"""Extract eco's dependency graph at every commit of its history, and lay it
out by pipeline stage, frame by frame.

Usage: python3 -I script/atlas-graph.py ../eco-compiler content/atlas/history.json

The atlas page at /atlas reads the output at build time. Its last frame is
eco as it is now, and the frames before it are how it got there.

The script replays the main line of eco's history, `git log --first-parent`,
one commit at a time, reading each changed file once with `git cat-file`.
Committed work only: changes not yet committed are not in the atlas.

The graph at a commit. The nodes are the compiler's Elm modules and the C++
components of the runtime and kernels. The dependencies come from Elm
imports, C++ #includes, C++ names used in one file and defined in another,
kernel calls from Elm to C++, and the kernel libraries CMake has eco-boot link
into programs. The Elm packages the compiler depends on are read from ELM_HOME
(~/.elm by default). At the last commit, anything other than a program that
nothing uses is listed on stderr.

The layout. Each frame is the frame before it with as little changed as
possible. A node keeps the slot it arrived in. A node that leaves leaves a
hole. A node that arrives goes into its column in order of name, and the
nodes below it move down one slot, as far as the first hole, which takes up
the move. Columns overflow into the next column, and a stage that needs
another column pushes the stages after it to the right. A node only changes
slot when one of those moves pushes it, or when it is moved in the code to
another stage, which git sees as a rename.
"""
import json, os, re, subprocess, sys
from collections import defaultdict

ROOT, OUT = sys.argv[1], sys.argv[2]

# ---------------------------------------------------------------- stages
# (key, title, blurb, lang, row). Row 0 is the shared front end plus the
# erased JavaScript path; row 1 is the typed path, which branches off after
# Local optimize and starts under Generate JavaScript.
STAGES = [
    ("driver", "Driver", "Command line, build plan, per-module compile", "elm", 0),
    ("parse", "Parse", "Source text to AST", "elm", 0),
    ("canon", "Canonicalize", "Resolve names and imports", "elm", 0),
    ("type", "Type check", "Constraints, solving, typed AST", "elm", 0),
    ("local", "Local optimize", "Pattern checks, decision trees", "elm", 0),
    ("genjs", "Generate JavaScript", "Erased path: .js and .html output", "elm", 0),
    ("mono", "Monomorphize", "Typed path: link and specialize", "elm", 1),
    ("global", "Global optimize", "Inline, CSE, borrow, staging", "elm", 1),
    ("genmlir", "Generate MLIR", "eco-dialect MLIR bytecode", "elm", 1),
    ("backend", "MLIR lowering", "eco dialect to LLVM dialect", "cpp", 1),
    ("native", "LLVM & link", "Driver, JIT, AOT, embedding", "cpp", 1),
    ("runtime", "Runtime", "Collector and scheduler", "cpp", 1),
    ("kernels", "Kernels", "C++ built-in functions", "cpp", 1),
]
BRANCH_FROM, BRANCH_TO = "local", "mono"
STAGE_KEYS = [s[0] for s in STAGES] + ["foundation", "cppfound"]


def elm_stage(m):
    p = m.split(".")
    if p[0] in ("Terminal", "API", "Builder") or m == "Compiler.Compile" or m.startswith("Compiler.Pipeline."):
        return "driver"
    if m.startswith("Compiler.Parse."):
        return "parse"
    if m.startswith("Compiler.Canonicalize."):
        return "canon"
    if m.startswith("Compiler.Type.") or m.startswith("Compiler.TypedCanonical."):
        return "type"
    if m.startswith("Compiler.Nitpick.") or m.startswith("Compiler.LocalOpt."):
        return "local"
    if m.startswith(("Compiler.Monomorphize.", "Compiler.MonoSolver.")):
        return "mono"
    if m.startswith("Compiler.GlobalOpt."):
        return "global"
    if m.startswith("Compiler.Generate.MLIR") or p[0] == "Mlir":
        return "genmlir"
    if m == "Compiler.Generate.Mode":
        return "foundation"  # used by both generators
    if m.startswith("Compiler.Generate."):
        return "genjs"
    return "foundation"


def cpp_node_for(rel):
    """Map a C++ file path to (node id, label, stage, group), or None."""
    parts = rel.split("/")
    stem = re.sub(r"\.(cpp|hpp|h|td)$", "", parts[-1])
    if rel.startswith("runtime/src/codegen/"):
        sub = parts[3] if len(parts) > 4 else ""
        if sub == "Passes":
            return ("cpp:pass:" + stem, stem, "backend", "Passes")
        if sub == "BF":
            return ("cpp:bf", "BF dialect", "backend", "BF")
        if stem == "Ops":
            return ("cpp:cg:Ops", "Ops.td", "backend", "codegen")
        if stem in ("EcoDialect", "EcoOps", "Passes", "LoweringStats", "EcoSplit", "EcoPipeline"):
            return ("cpp:cg:" + stem, stem, "backend", "codegen")
        return ("cpp:cg:" + stem, stem, "native", "codegen")
    if rel.startswith("runtime/src/jit/") or rel.startswith("runtime/src/embed/"):
        return ("cpp:" + parts[2] + ":" + stem, stem, "native", parts[2])
    if rel.startswith("runtime/src/platform/"):
        return ("cpp:plat:" + stem, stem, "runtime", "platform")
    if rel in ("runtime/src/ecogen.cpp", "runtime/src/main.cpp"):
        return ("cpp:rt:" + stem, stem, "native", "runtime")
    if rel.startswith(("runtime/src/", "runtime/include/")):
        # the allocator, and the runtime before it had folders
        stem = re.sub(r"_(posix|win32)$", "", stem)
        return ("cpp:alloc:" + stem, stem, "runtime", "allocator")
    if rel.startswith("elm-kernel-cpp/src/"):
        if len(parts) > 3:
            return ("cpp:ek:" + parts[2], "elm/" + parts[2], "kernels", "elm-kernel-cpp")
        return ("cpp:ek:" + stem, "elm/" + stem, "kernels", "elm-kernel-cpp")
    if rel.startswith("eco-kernel-cpp/src/"):
        if stem != "KernelExports":
            stem = re.sub(r"Exports$", "", stem) or stem
        return ("cpp:eco:" + stem, "Eco." + stem, "kernels", "eco-kernel-cpp")
    if rel.startswith("system-kernel-cpp/src/"):
        if len(parts) > 4:
            return ("cpp:sys:" + parts[3], "System." + parts[3], "kernels", "system-kernel-cpp")
        stem = re.sub(r"Exports$", "", stem) or stem
        return ("cpp:sys:" + stem, "System." + stem, "kernels", "system-kernel-cpp")
    return None


# What every C++ stage stands on: the heap value model and the operations on
# values, and the C ABI that generated code, kernels and runtime share.
CPP_FOUND = [
    ("values", "Heap and values", [
        "cpp:alloc:Heap", "cpp:alloc:CharValue", "cpp:alloc:TypeInfo", "cpp:alloc:HeapHelpers",
        "cpp:alloc:RootedSlots", "cpp:alloc:StringOps", "cpp:alloc:ListOps", "cpp:alloc:BytesOps",
        "cpp:alloc:ElmBytesRuntime", "cpp:alloc:Utf8", "cpp:alloc:CaseMap", "cpp:alloc:CaseMapTables",
    ]),
    ("abi", "Runtime ABI", [
        "cpp:alloc:RuntimeExports", "cpp:ek:KernelExports", "cpp:eco:KernelExports",
        "cpp:ek:ExportHelpers", "cpp:eco:ExportHelpers", "cpp:plat:TaskBinding", "cpp:eco:TaskBinding",
    ]),
]
CPP_FOUND_SLOT = {i: (s, k) for s, (_, _, ids) in enumerate(CPP_FOUND) for k, i in enumerate(ids)}

# Nothing in the compiler depends on these: the programs (found by their
# main), the Node.js addon, and EcoRunner, the library the tests run compiled
# code with.
ROOTS = {"Terminal.Main", "API.Main", "cpp:embed:eco_node_addon", "cpp:cg:EcoRunner"}

# ---------------------------------------------------------------- sources
PATHS = ["compiler/src", "compiler/src-xhr", "compiler/src-version", "compiler/elm.json",
         "runtime/src", "runtime/include", "elm-kernel-cpp", "eco-kernel-cpp", "system-kernel-cpp/src",
         "system-kernel-cpp/CMakeLists.txt"]
CPP_DIRS = ("runtime/src/", "runtime/include/", "elm-kernel-cpp/src/", "eco-kernel-cpp/src/", "system-kernel-cpp/src/")
CMAKES = {"runtime/src/codegen/CMakeLists.txt", "elm-kernel-cpp/CMakeLists.txt",
          "eco-kernel-cpp/CMakeLists.txt", "system-kernel-cpp/CMakeLists.txt"}
TWIN_DIR = "eco-kernel-cpp/src/"
LIBRARIES = ["runtime", "elm-kernel-cpp", "eco-kernel-cpp", "system-kernel-cpp"]  # lowest first


def relevant(path):
    if path == "compiler/elm.json" or path in CMAKES:
        return True
    if path.endswith(".elm"):
        return path.startswith(("compiler/", TWIN_DIR))
    if re.search(r"\.(cpp|hpp|h|td)$", path) and path.startswith(CPP_DIRS):
        return not {"third_party", "vendor", "tests", "test"} & set(path.split("/")[:-1])
    return False


class Blobs:
    """File contents by blob id, from one `git cat-file --batch`."""

    def __init__(self):
        self.p = subprocess.Popen(["git", "-C", ROOT, "cat-file", "--batch"],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE)

    def get(self, sha):
        self.p.stdin.write(sha.encode() + b"\n")
        self.p.stdin.flush()
        header = self.p.stdout.readline().split()
        data = self.p.stdout.read(int(header[2]))
        self.p.stdout.read(1)
        return data.decode("utf-8", "replace")


def history():
    """The main line, oldest first: (hash, time, subject, changes), where a
    change is (status, old path, new path, new blob)."""
    out = subprocess.run(
        ["git", "-C", ROOT, "-c", "core.quotePath=false", "log", "--first-parent", "--diff-merges=first-parent",
         "--reverse", "-M", "--raw", "--no-abbrev", "--format=@%H %ct %s", "--"] + PATHS,
        capture_output=True, text=True, check=True).stdout
    commits = []
    for line in out.splitlines():
        if line.startswith("@"):
            h, t, subject = (line[1:].split(" ", 2) + [""])[:3]
            commits.append((h, int(t), subject, []))
        elif line.startswith(":"):
            meta, *paths = line.split("\t")
            _, _, _, new, status = meta.split()
            old_path = paths[0]
            new_path = paths[-1]
            commits[-1][3].append((status[0], old_path, new_path, new))
    return commits


# ---------------------------------------------------------------- C++ reading
# An #include reaches a header, but the code behind it can be anywhere: every
# pass is declared in Passes.h and defined in a file of its own, and kernels
# are called by C name from code that includes none of their headers. So each
# file is read for what it defines with external linkage and for the names it
# uses, and a user is linked to the definer.

LITERALS = re.compile(
    r'//[^\n]*|/\*.*?\*/'
    r'|(?<![\w])(?:u8|u|U|L)?R"([^(\s]{0,16})\(.*?\)\1"'
    r'|"(?:\\.|[^"\\\n])*"'
    r"|(?<![\w])'(?:\\.|[^'\\\n])*'", re.S)


def strip_cpp(text):
    """Blank comments and the insides of string and character literals,
    keeping the quotes, the newlines and every offset."""
    def blank(m):
        s = m.group(0)
        if s.startswith("/"):
            return re.sub(r"[^\n]", " ", s)
        q = s.index(s[-1])  # the opening quote
        return s[:q + 1] + re.sub(r"[^\n]", " ", s[q + 1:-1]) + s[-1]
    return LITERALS.sub(blank, text)


def without_preprocessor(code):
    """Blank preprocessor lines, with their continuations."""
    lines = code.split("\n")
    cont = False
    for k, line in enumerate(lines):
        if cont or line.lstrip().startswith("#"):
            cont = line.rstrip().endswith("\\")
            lines[k] = " " * len(line)
    return "\n".join(lines)


def balanced_tail(head):
    """For a head ending in ')', the index of the '(' that matches it."""
    depth = 0
    for j in range(len(head) - 1, -1, -1):
        if head[j] == ")":
            depth += 1
        elif head[j] == "(":
            depth -= 1
            if depth == 0:
                return j
    return -1


KEYWORDS = {"if", "for", "while", "switch", "catch", "return", "sizeof", "alignof", "decltype",
            "static_assert", "alignas", "noexcept", "defined", "__attribute__", "else", "case",
            "new", "delete", "throw", "co_return", "co_await", "operator", "typeid", "assert"}
QUALS = re.compile(r"(\s*(const|noexcept(\s*\([^()]*\))?|override|final|volatile|&&|&|mutable|try))*\s*$")
NAME = re.compile(r"((?:[A-Za-z_]\w*(?:<[^<>]*>)?\s*::\s*)*~?[A-Za-z_]\w*)\s*$")


def clean_head(head):
    head = re.sub(r"\[\[.*?\]\]", " ", head, flags=re.S)
    head = re.sub(r"__attribute__\s*\(\(.*?\)\)", " ", head, flags=re.S)
    head = re.sub(r"__declspec\s*\([^()]*\)", " ", head)
    head = re.sub(r"^\s*template\s*<.*?>\s*(?=[A-Za-z_])", "", head, flags=re.S)
    return head.strip()


def function_name(head):
    """The qualified name of a function definition whose head (the text before
    the body's '{') is given, or None."""
    # a constructor's member initializers: cut at the ':' after the parameters
    depth = 0
    for j, c in enumerate(head):
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0 and re.match(r"\s*(?:const|noexcept|override|final|\s)*:(?!:)", head[j + 1:]):
                head = head[:j + 1]
                break
    head = re.sub(r"\)\s*->\s*[^()]*$", ")", head)
    head = QUALS.sub("", head)
    if not head.endswith(")"):
        return None
    k = balanced_tail(head)
    if k <= 0:
        return None
    before = head[:k]
    if "=" in re.sub(r"operator\s*\S+", "", before):
        return None
    m = NAME.search(before)
    if not m:
        return None
    name = re.sub(r"<[^<>]*>", "", re.sub(r"\s+", "", m.group(1)))
    simple = name.split("::")[-1]
    if simple in KEYWORDS or simple.startswith("~"):
        return None
    if re.search(r"\bstatic\b", before[:m.start()]):
        return None
    return name


def scan(code):
    """What a file defines at namespace scope: (defs, classes, opened). defs
    are (namespace, name) for the functions and variables it defines with
    external linkage, where namespace is the full "a::b" the name is in, with
    a qualified name's class, if any, kept in it; classes are the classes it
    defines; opened are the namespaces it opens or brings in with `using
    namespace`."""
    defs, classes, opened = [], set(), set()
    marks = [(m.start(), m.group(0)) for m in re.finditer(r"[{};]", code)]
    close = {}
    stack = []
    for k, (_, c) in enumerate(marks):
        if c == "{":
            stack.append(k)
        elif c == "}" and stack:
            close[stack.pop()] = k
    scope = []  # namespace names, "" for an anonymous one, None for extern "C"
    start, k = 0, 0

    def here():
        return "::".join(x for x in scope if x)

    while k < len(marks):
        i, c = marks[k]
        if c == "{":
            head = clean_head(code[start:i])
            ns = re.search(r"(?:^|[\s;)}])(?:inline\s+)?namespace(?:\s+([\w:]+))?$", head)
            if head.count("(") > head.count(")"):
                k = close.get(k, len(marks) - 1)  # a brace inside a macro's argument
            elif ns:
                scope.append(ns.group(1) or "")
                opened.add(here())
            elif re.fullmatch(r'extern\s*"\s*"', head):
                scope.append(None)
            else:
                cm = re.match(r"(?:typedef\s+)?(class|struct|union)\b(.*)$", head, re.S)
                if cm:
                    names = re.findall(r"[A-Za-z_]\w*", re.sub(r"alignas\s*\([^()]*\)", "",
                                                             re.split(r"(?<!:):(?!:)", cm.group(2))[0]))
                    names = [x for x in names if x != "final"]
                    if names:
                        classes.add(names[-1])
                elif "" not in scope and not head.startswith(("enum", "using", "typedef")):
                    fn = function_name(head)
                    if fn:
                        parts = fn.split("::")
                        defs.append(("::".join(([here()] if here() else []) + parts[:-1]), parts[-1]))
                    elif "(" not in head and not re.search(r"\bstatic\b", head):
                        vm = re.search(r"([A-Za-z_]\w*)\s*(?:\[[^\]]*\]\s*)*=?\s*$", head)
                        if vm and vm.group(1) not in KEYWORDS and len(head.split()) > 1:
                            defs.append((here(), vm.group(1)))
                k = close.get(k, len(marks) - 1)
            start = marks[k][0] + 1
        elif c == "}":
            if scope:
                scope.pop()
            start = i + 1
        else:
            stmt = clean_head(code[start:i])
            um = re.fullmatch(r"using\s+namespace\s+([\w:]+)", stmt)
            if um:
                opened.add(um.group(1).lstrip(":"))
            elif ("" not in scope and stmt
                    and not re.match(r"(using|typedef|template|friend|static_assert|class|struct|enum|union|extern|namespace)\b", stmt)
                    and not re.search(r"\bstatic\b", stmt)):
                lhs = stmt.split("=")[0]
                if "(" not in lhs and len(lhs.split()) > 1:
                    vm = re.search(r"([A-Za-z_]\w*)\s*(?:\[[^\]]*\]\s*)*$", lhs)
                    if vm and vm.group(1) not in KEYWORDS:
                        defs.append((here(), vm.group(1)))
            start = i + 1
        k += 1
    return defs, classes, opened


INCLUDE = re.compile(r'^\s*#\s*include\s+"([^"]+)"|^\s*include\s+"([^"]+)"', re.M)
TOKEN = re.compile(r"[A-Za-z_]\w*")
NOT_A_CALL = {"return", "else", "case", "new", "delete", "throw", "co_return", "co_await", "co_yield", "do"}


class CppFile:
    """What one version of a C++ file says, read once."""

    def __init__(self, path, text):
        self.includes = [a or b for a, b in INCLUDE.findall(text)]
        self.alternates = re.findall(r"/alternatename:(\w+)=", text)
        if path.endswith(".td"):
            self.code, self.defs, self.classes, self.opened, self.tokens = "", [], set(), set(), set()
        else:
            self.code = strip_cpp(text)
            self.defs, self.classes, self.opened = scan(without_preprocessor(self.code))
            self.defs += [("", a) for a in self.alternates]
            self.tokens = set(TOKEN.findall(self.code))
        self.uses_of = {}

    def uses(self, name):
        """How the file mentions a name: a list of qualifiers ("" for none) of
        the places it uses it, and whether it declares it."""
        if name not in self.uses_of:
            quals, declares = [], False
            for m in re.finditer(r"\b" + name + r"\b", self.code):
                before = self.code[max(0, m.start() - 120):m.start()].rstrip()
                if before.endswith(".") or before.endswith("->"):
                    continue
                qm = re.search(r"((?:[A-Za-z_]\w*\s*::\s*)+)$", before)
                qualifier = re.sub(r"\s+", "", qm.group(1))[:-2] if qm else ""
                prev = re.search(r"([A-Za-z_]\w*|(?<=[\w>])\s*[*&]+|>)\s*$", before[:qm.start()] if qm else before)
                if prev and prev.group(1).strip() not in NOT_A_CALL and not qm:
                    declares = True  # `T name(` or `extern T name;` declares rather than uses
                    continue
                quals.append(qualifier)
            self.uses_of[name] = (sorted(set(quals)), declares)
        return self.uses_of[name]


def reaches(ns, qualifier, opened):
    """Whether a use of a name, qualified by `qualifier` ("" for none) in a
    file that opens the namespaces `opened`, can find it in namespace `ns`."""
    if not ns:
        return qualifier == ""
    if qualifier:
        # a qualified name is looked up from each enclosing namespace outwards
        scopes = {""} | {"::".join(o.split("::")[:k]) for o in opened for k in range(1, o.count("::") + 2)}
        return any(ns == (sc + "::" + qualifier if sc else qualifier) for sc in scopes)
    return any(o == ns or o.startswith(ns + "::") for o in opened)


# ---------------------------------------------------------------- one commit
IMPORT = re.compile(r"^import\s+([A-Z][\w.]*)", re.M)
ELM_HOME = os.environ.get("ELM_HOME", os.path.expanduser("~/.elm"))
package_cache = {}
missing_packages = set()


def package_kernels(pkg, version):
    """The kernel modules each module of a package imports."""
    if (pkg, version) not in package_cache:
        src = os.path.join(ELM_HOME, "0.19.1", "packages", pkg, version, "src")
        out = {}
        for d, _, fs in os.walk(src):
            for f in fs:
                if f.endswith(".elm"):
                    p = os.path.join(d, f)
                    mod = os.path.relpath(p, src)[:-4].replace(os.sep, ".")
                    out[mod] = {m for m in IMPORT.findall(open(p, encoding="utf-8").read()) if ".Kernel." in m}
        if not os.path.isdir(src):
            missing_packages.add(pkg + " " + version)
        package_cache[pkg, version] = out
    return package_cache[pkg, version]


def cmake_libraries(path, text):
    """The source files of each static library a CMakeLists.txt defines."""
    base = os.path.dirname(path)
    var = {m.group(1): m.group(2).split() for m in re.finditer(r"set\((\w+)\s+([^)]*)\)", text)}

    def sources(words):
        out = []
        for w in words:
            v = re.fullmatch(r"\$\{(\w+)\}", w)
            out += sources(var.get(v.group(1), [])) if v else [w]
        return [os.path.normpath(os.path.join(base, w)) for w in out if w.endswith(".cpp")]

    libs = {}
    for m in re.finditer(r"add_library\(\s*(\w+)\s+STATIC\s+([^)]*)\)", text):
        libs[m.group(1)] = sources(m.group(2).split())
    for m in re.finditer(r"eco_system_module\(\s*(\w+)\s+([^)]*)\)", text):
        libs["EcoSystem_" + m.group(1)] = sources(m.group(2).split())
    return libs


def extract(files, cpp):
    """The graph a commit's files make: (nodes, edges, file_node), where nodes
    maps a node id to its label, lang, stage, path and group."""
    nodes, edges, file_node = {}, set(), {}

    # Elm. The compiler is every module in the source directories of
    # compiler/elm.json. Some modules (Eco.File, Eco.Process, ...) exist twice:
    # compiler/src-xhr has the one for a compiler running on stock Elm, which
    # reaches the file system through eco-io, and eco-kernel-cpp/src has the
    # native one, which calls the C++ kernel. The build picks one, so each is
    # a single node with the imports of both.
    elm_files = defaultdict(list)
    kernel_imports = defaultdict(set)
    elm_json = None
    if "compiler/elm.json" in files:
        try:
            elm_json = json.loads(files["compiler/elm.json"])
        except ValueError:
            pass
    if elm_json:
        dirs = ["compiler/" + d.strip("./") + "/" for d in elm_json.get("source-directories", [])]
        for p in files:
            if p.endswith(".elm"):
                for d in dirs:
                    if p.startswith(d):
                        elm_files[p[len(d):-4].replace("/", ".")].append(p)
        for p in files:
            if p.endswith(".elm") and p.startswith(TWIN_DIR):
                mod = p[len(TWIN_DIR):-4].replace("/", ".")
                if mod in elm_files:
                    elm_files[mod].append(p)
        deps = elm_json.get("dependencies", {})
        pkg_kernels = {}
        for pkg, version in list(deps.get("direct", {}).items()) + list(deps.get("indirect", {}).items()):
            if pkg.split("/")[0] in ("elm", "elm-explorations"):  # only these may have kernel code
                pkg_kernels.update(package_kernels(pkg, version))
        for mod, paths in elm_files.items():
            label = mod[len("Compiler."):] if mod.startswith("Compiler.") else mod
            nodes[mod] = dict(label=label, lang="elm", stage=elm_stage(mod), path=", ".join(paths),
                              group=".".join(mod.split(".")[:3]))
            for p in paths:
                file_node[p] = mod
                for m in IMPORT.findall(files[p]):
                    if m in elm_files:
                        if m != mod:
                            edges.add((mod, m))
                    elif ".Kernel." in m:
                        kernel_imports[mod].add(m)
                    else:
                        kernel_imports[mod] |= pkg_kernels.get(m, set())

    # C++ components
    by_base = defaultdict(list)
    cpp_paths = sorted(p for p in files if p.startswith(CPP_DIRS) and re.search(r"\.(cpp|hpp|h|td)$", p))
    for p in cpp_paths:
        n = cpp_node_for(p)
        if not n:
            continue
        nid, label, st, grp = n
        file_node[p] = nid
        by_base[os.path.basename(p)].append(nid)
        if nid not in nodes:
            nodes[nid] = dict(label=label, lang="cpp", stage="cppfound" if nid in CPP_FOUND_SLOT else st,
                              group=grp, files=[])
        nodes[nid]["files"].append(p)
    cpp_files = [p for p in cpp_paths if p in file_node]

    # Headers the build writes. TableGen turns each .td into .inc files that
    # the dialect sources include, and CMake writes EcoBootConfig.h, the list
    # of libraries eco-boot links a program against, which EcoBootConfig.cpp
    # reads.
    codegen_cmake = files.get("runtime/src/codegen/CMakeLists.txt", "")
    td = None
    for m in re.finditer(r"set\(LLVM_TARGET_DEFINITIONS\s+(\S+)\)|mlir_tablegen\(\S*?([\w.]+\.inc)\s", codegen_cmake):
        if m.group(1):
            td = file_node.get(os.path.normpath(os.path.join("runtime/src/codegen", m.group(1))))
        elif td:
            by_base[m.group(2)].append(td)
    if "cpp:cg:EcoBootConfig" in nodes:
        by_base["EcoBootConfig.h"].append("cpp:cg:EcoBootConfig")

    # An #include is looked for next to the file first, then in the include
    # directories: its own library's, then the libraries below it.
    files_by_base = defaultdict(list)
    for p in cpp_files:
        files_by_base[os.path.basename(p)].append(p)

    def resolve(p, inc):
        near = os.path.normpath(os.path.join(os.path.dirname(p), inc))
        if near in file_node:
            return near
        cands = [f for f in files_by_base.get(os.path.basename(inc), []) if f.endswith("/" + inc.lstrip("./"))]
        if not cands:
            return None
        top = p.split("/")[0]
        return min(cands, key=lambda f: (f.split("/")[0] != top, LIBRARIES.index(f.split("/")[0]),
                                         -len(os.path.commonpath([f, p])), f))

    included = defaultdict(set)
    for p in cpp_files:
        nid = file_node[p]
        for inc in cpp[p].includes:
            f = resolve(p, inc)
            if f:
                included[p].add(f)
                tgt = file_node[f]
            elif by_base.get(os.path.basename(inc)) and not os.path.basename(inc) in files_by_base:
                tgt = by_base[os.path.basename(inc)][0]  # a header the build writes
            else:
                continue
            if tgt != nid:
                edges.add((nid, tgt))

    class_home = defaultdict(set)
    for p in cpp_files:
        for c in cpp[p].classes:
            class_home[c].add(file_node[p])
    # A member defined outside the node that defines its class: the class's
    # node is implemented, in part, by the definer.
    free = defaultdict(set)  # name -> (namespace, node) for functions and variables
    for p in cpp_files:
        if not p.endswith(".cpp"):
            continue
        nid = file_node[p]
        for ns, name in cpp[p].defs:
            owner_class = ns.split("::")[-1] if ns else ""
            if owner_class in class_home:
                homes = class_home[owner_class] - {nid}
                if len(class_home[owner_class]) == 1 and homes:
                    edges.add((next(iter(homes)), nid))
            else:
                free[name].add((ns, nid))
    # A program is a file that defines main. Nothing links a program, so a
    # weak default a program defines for itself, as ecoc does for
    # Eco_Kernel_register_all_gc_roots, is not something other code uses.
    programs = {o for _, o in free.get("main", ())}

    def closure(p):
        seen, todo = set(), [p]
        while todo:
            for f in included.get(todo.pop(), ()):
                if f not in seen:
                    seen.add(f)
                    todo.append(f)
        return seen

    for p in cpp_files:
        info = cpp[p]
        names = [n for n in info.tokens if n in free and n != "main"]
        if not names:
            continue
        nid = file_node[p]
        visible = closure(p)
        for name in names:
            quals, declares = info.uses(name)
            if not quals:
                continue
            if not declares and not any(name in cpp[f].tokens for f in visible if f in cpp):
                continue
            for q in quals:
                owners = {o for ns, o in free[name] if reaches(ns, q, info.opened)} - {nid} - programs
                if 0 < len(owners) <= 3:
                    for o in owners:
                        edges.add((nid, o))

    # Elm to C++. An Elm module that imports a kernel module, Eco.Kernel.File
    # say, calls the C functions named Eco_Kernel_File_*. A module that
    # imports a package module that imports a kernel module, as Regex imports
    # Elm.Kernel.Regex, calls Elm_Kernel_Regex_* through it.
    definers = defaultdict(set)
    for name, owners in free.items():
        m = re.match(r"([A-Z][a-z]+_Kernel_[A-Za-z0-9]+)_", name)
        if m:
            definers[m.group(1)] |= {o for _, o in owners}
    for mod, kms in kernel_imports.items():
        for km in kms:
            for o in definers.get(km.replace(".", "_"), ()):
                edges.add((mod, o))

    # The build. eco-boot links every program it builds against each kernel
    # library, by name from the generated EcoBootConfig.h, so that header
    # uses them all.
    if "cpp:cg:EcoBootConfig" in nodes:
        libraries = {}
        for cm in CMAKES - {"runtime/src/codegen/CMakeLists.txt"}:
            if cm in files:
                libraries.update(cmake_libraries(cm, files[cm]))
        for var, prefix in (("ECO_ELM_KERNEL_MODS", "ElmKernel_"), ("ECO_KERNEL_MODS", "EcoKernel_"),
                            ("ECO_SYSTEM_MODS", "EcoSystem_")):
            m = re.search(r"set\(" + var + r"\s+(.*?)\s+CACHE", codegen_cmake, re.S)
            for mod in (m.group(1).split() if m else []):
                for src_file in libraries.get(prefix + mod, []):
                    if file_node.get(src_file, "cpp:cg:EcoBootConfig") != "cpp:cg:EcoBootConfig":
                        edges.add(("cpp:cg:EcoBootConfig", file_node[src_file]))

    for n in nodes.values():
        if n["lang"] == "cpp":
            fs = sorted(n.pop("files"))
            n["path"] = os.path.dirname(fs[0]) + "/" if len(fs) > 2 else ", ".join(fs)
    return nodes, edges, file_node, programs


# ---------------------------------------------------------------- layout
# Everything is in grid cells. A node's footprint is NODE_W cells by NODE_H
# rows: its text sits in row 1, and the page draws its frame on the
# in-between grid around that. Columns are COL_PITCH cells apart.
NODE_W, NODE_H, COL_PITCH = 13, 3, 15
HEAD_ROWS = 9          # stage header rows; nodes start on this row
STAGE_GAP = 2          # cells between stage footprints (arrow lives here)
MIN_COLS = 2
MAXROWS = 24           # slots in a column
ROW_GAP = 3            # rows between the two pipeline rows
FOUND_HEAD = 7         # foundation header rows
CPP_PER_COL = 4


def stack_height(stack):
    """The slots a stack needs for one more module."""
    return len(stack) if None not in stack else stack.index(None)


class Layout:
    """Slots for nodes, kept from one commit to the next.

    A stage has a flow of slots for each depth, 0 for the nodes nothing else
    in the stage imports, 1 and 2 for the ones further in. A flow runs down a
    column and on into the next, MAXROWS slots to a column. The Elm
    foundation has a stack of slots per column. A slot holds a node's uid or
    None, a hole left by a node that has gone.
    """

    def __init__(self):
        self.uid = {}        # node id -> uid, for the nodes there now
        self.uids = []       # uid -> its first node id
        self.info = {}       # uid -> node info, for the nodes there now
        self.flows = {}      # (stage, depth) -> slots
        self.stacks = {}     # foundation column -> slots
        self.where = {}      # uid -> ("flow", key) | ("stack", col) | ("cpp",)

    def remove(self, u):
        kind = self.where.pop(u)
        slots = self.flows[kind[1]] if kind[0] == "flow" else self.stacks[kind[1]] if kind[0] == "stack" else None
        if slots is not None:
            slots[slots.index(u)] = None

    def key(self, u):
        i = self.info[u]
        return (i["group"], i["label"])

    def insert_flow(self, u, fkey):
        slots = self.flows.setdefault(fkey, [])
        k = self.key(u)
        i = 0
        for j, s in enumerate(slots):
            if s is not None and self.key(s) < k:
                i = j + 1
        hole = next((h for h in range(i, len(slots)) if slots[h] is None), None)
        if hole is None:
            slots.insert(i, u)
        else:
            slots[i + 1:hole + 1] = slots[i:hole]
            slots[i] = u
        self.where[u] = ("flow", fkey)

    def step(self, nodes, edges, renamed):
        """Move from the last commit's graph to this one's. `renamed` maps a
        node id that has gone to the id it was renamed to."""
        gone = [i for i in self.uid if i not in nodes]
        old_uid = dict(self.uid)
        for i in gone:
            del self.uid[i]
        for old, new in renamed.items():
            if old in gone and new in nodes and new not in old_uid:
                self.uid[new] = old_uid[old]
        arrived = []
        for i in sorted(nodes):
            if i not in self.uid:
                self.uid[i] = len(self.uids)
                self.uids.append(i)
                arrived.append(self.uid[i])
        live = set(self.uid.values())
        for u in list(self.where):
            if u not in live:
                self.remove(u)
                del self.info[u]
        moved = []
        for i, u in self.uid.items():
            n = nodes[i]
            before = self.info.get(u)
            self.info[u] = dict(n, id=i)
            if before and before["stage"] != n["stage"] and u in self.where:
                self.remove(u)
                moved.append(u)

        # trailing holes take no room
        for slots in list(self.flows.values()) + list(self.stacks.values()):
            while slots and slots[-1] is None:
                slots.pop()
        for k in [k for k, s in self.flows.items() if not s]:
            del self.flows[k]
        for k in [k for k, s in self.stacks.items() if not s]:
            del self.stacks[k]

        placing = sorted(arrived + moved, key=lambda u: self.key(u))
        by_id_stage = {i: nodes[i]["stage"] for i in nodes}
        in_adj = defaultdict(set)
        for a, b in edges:
            if by_id_stage[a] == by_id_stage[b]:
                in_adj[b].add(a)

        def depth(i, seen=()):
            preds = [p for p in in_adj[i] if p not in seen]
            return 0 if not preds or len(seen) > 2 else 1 + max(depth(p, seen + (i,)) for p in preds)

        for u in placing:
            st = self.info[u]["stage"]
            if st == "cppfound":
                self.where[u] = ("cpp",)
            elif st != "foundation":
                self.insert_flow(u, (st, min(depth(self.info[u]["id"]), 2)))

        geo = self.geometry()
        pos = self.positions(geo)
        # the Elm foundation: each arrival goes under the mean column of its
        # users, on top of that column's stack
        users = defaultdict(list)
        for a, b in edges:
            users[b].append(a)
        found = [u for u in placing if self.info[u]["stage"] == "foundation"]
        ncols = max(1, (geo["elmEnd"] - 2 - NODE_W) // COL_PITCH + 1)
        # those with placed users first, so the rest can go under them
        for everyone in (False, True):
            want = {}
            for u in found:
                xs = [pos[self.uid[a]][0] for a in users[self.info[u]["id"]] if self.uid.get(a) in pos]
                if xs:
                    want[u] = sum(xs) / len(xs)
            for u in sorted(found, key=lambda u: (want.get(u, geo["elmEnd"] / 2), self.key(u))):
                if u not in want and not everyone:
                    continue
                x = want.get(u, geo["elmEnd"] / 2)
                c0 = max(0, min(ncols - 1, (x - 1) / COL_PITCH))
                # the nearest column with room: each column further away costs
                # as much as two more modules already in the stack
                c = min(range(ncols), key=lambda c: (stack_height(self.stacks.get(c, [])) + 2 * abs(c - c0), c))
                stack = self.stacks.setdefault(c, [])
                h = next((h for h, s in enumerate(stack) if s is None), None)
                if h is None:
                    stack.append(u)
                else:
                    stack[h] = u
                self.where[u] = ("stack", c)
                pos[u] = (1 + c * COL_PITCH, 0)
            found = [u for u in found if u not in self.where]
        # a stack beyond the foundation's columns moves in
        for c in [c for c in self.stacks if c >= ncols]:
            for u in self.stacks.pop(c):
                if u is not None:
                    self.stacks.setdefault(ncols - 1, []).append(u)
                    self.where[u] = ("stack", ncols - 1)
        geo = self.geometry()
        return geo, self.positions(geo)

    def geometry(self):
        live_stage = defaultdict(int)
        for u in self.where:
            live_stage[self.info[u]["stage"]] += 1
        stages = {}
        row_x = {0: 0, 1: 0}
        cols_of = {}
        for key, _, _, lang, row in STAGES:
            depths = sorted(d for (s, d) in self.flows if s == key)
            ncols = sum(-(-len(self.flows[key, d]) // MAXROWS) for d in depths)
            cols_of[key] = ncols
            if row == 1 and key == BRANCH_TO and BRANCH_FROM in stages:
                f = stages[BRANCH_FROM]
                row_x[1] = max(row_x[1], f["gx"] + f["gw"] + STAGE_GAP)
            if live_stage[key]:
                gw = max(MIN_COLS, ncols) * COL_PITCH
                stages[key] = dict(gx=row_x[row], gw=gw, row=row, lang=lang)
                row_x[row] += gw + STAGE_GAP
        row_rows = {}
        for r in (0, 1):
            tallest = 0
            for (s, d), slots in self.flows.items():
                if s in stages and stages[s]["row"] == r:
                    tallest = max(tallest, min(len(slots), MAXROWS))
            row_rows[r] = HEAD_ROWS + tallest * NODE_H + 1 if any(s["row"] == r for s in stages.values()) else 0
        row_top = {0: 0, 1: row_rows[0] + ROW_GAP if row_rows[0] else 0}
        for key, s in stages.items():
            s["gy"], s["gh"] = row_top[s["row"]], row_rows[s["row"]]
        stage_rows = row_top[1] + row_rows[1] if row_rows[1] else row_rows[0]
        elm_end = max([s["gx"] + s["gw"] for s in stages.values() if s["lang"] == "elm"], default=0)
        tallest_stack = max([len(s) for s in self.stacks.values()], default=0)
        # the C++ foundation starts under the first C++ stage, or after the
        # Elm foundation if that reaches further
        cpp_gx = max([min([s["gx"] for s in stages.values() if s["lang"] == "cpp"], default=0)]
                     + ([elm_end + STAGE_GAP] if tallest_stack else []))
        found_top = stage_rows + 3
        has_cpp_found = any(self.info[u]["stage"] == "cppfound" for u in self.where)
        found_rows = 0
        if tallest_stack or has_cpp_found:
            found_rows = max(FOUND_HEAD + tallest_stack * NODE_H,
                             FOUND_HEAD + 2 + CPP_PER_COL * NODE_H if has_cpp_found else 0) + 1
        sections, sx = [], cpp_gx + 1
        for key, title, ids in CPP_FOUND:
            sections.append(dict(key=key, title=title, gx=sx))
            sx += -(-len(ids) // CPP_PER_COL) * COL_PITCH + 2
        world_cols = max([s["gx"] + s["gw"] for s in stages.values()] + [sx if has_cpp_found else 0])
        return dict(stages=stages, colsOf=cols_of, elmEnd=elm_end, cppGx=cpp_gx, foundTop=found_top,
                    foundRows=found_rows, hasElmFound=bool(tallest_stack), hasCppFound=has_cpp_found,
                    sections=sections, cols=world_cols, rows=found_top + found_rows if found_rows else stage_rows)

    def positions(self, geo):
        pos = {}
        for (st, d), slots in self.flows.items():
            if st not in geo["stages"]:
                continue
            s = geo["stages"][st]
            off = sum(-(-len(self.flows[st, e]) // MAXROWS) for e in range(d) if (st, e) in self.flows)
            for j, u in enumerate(slots):
                if u is not None:
                    pos[u] = (s["gx"] + 1 + (off + j // MAXROWS) * COL_PITCH,
                              s["gy"] + HEAD_ROWS + (j % MAXROWS) * NODE_H)
        for c, slots in self.stacks.items():
            for j, u in enumerate(slots):
                if u is not None:
                    pos[u] = (1 + c * COL_PITCH, geo["foundTop"] + FOUND_HEAD + j * NODE_H)
        for u, kind in self.where.items():
            if kind[0] == "cpp":
                s, k = CPP_FOUND_SLOT[self.info[u]["id"]]
                pos[u] = (geo["sections"][s]["gx"] + (k // CPP_PER_COL) * COL_PITCH,
                          geo["foundTop"] + FOUND_HEAD + 2 + (k % CPP_PER_COL) * NODE_H)
        return pos


# ---------------------------------------------------------------- replay
def main():
    blobs = Blobs()
    files = {}           # path -> text
    sha_of = {}          # path -> blob id
    cpp_cache = {}       # blob id -> CppFile
    cpp = {}             # path -> CppFile
    layout = Layout()
    frames = []          # (hash, time, subject)
    tracks = defaultdict(list)    # uid -> [(frame, gx, gy)]
    infos = defaultdict(list)     # uid -> [(frame, stage, id, label, path)]
    lives = defaultdict(list)     # uid -> [born, died, born, ...]
    edge_lives = defaultdict(list)
    stage_tracks = defaultdict(list)
    world_track = []
    last_pos, last_info, last_edges, last_geo = {}, {}, set(), {}
    prev_file_node = {}
    nodes = edges = programs = None

    commits = history()
    for n_commit, (h, t, subject, changes) in enumerate(commits):
        renamed_paths = {}
        touched = False
        for status, old, new, sha in changes:
            if status in "DR" and old in files:
                del files[old], sha_of[old]
                cpp.pop(old, None)
                touched = True
            if status == "R":
                renamed_paths[old] = new
            if status != "D" and relevant(new):
                if sha_of.get(new) != sha:
                    files[new] = blobs.get(sha)
                    sha_of[new] = sha
                    if new.startswith(CPP_DIRS) and re.search(r"\.(cpp|hpp|h|td)$", new):
                        if sha not in cpp_cache:
                            cpp_cache[sha] = CppFile(new, files[new])
                        cpp[new] = cpp_cache[sha]
                    touched = True
        if not touched:
            continue
        live_shas = set(sha_of.values())
        for s in [s for s in cpp_cache if s not in live_shas]:
            del cpp_cache[s]

        nodes, edges, file_node, programs = extract(files, cpp)
        renamed = {}
        for old, new in renamed_paths.items():
            a, b = prev_file_node.get(old), file_node.get(new)
            if a and b and a != b:
                renamed[a] = b
        prev_file_node = file_node
        geo, pos = layout.step(nodes, edges, renamed)

        uid_edges = {(layout.uid[a], layout.uid[b]) for a, b in edges}
        info_now = {u: (STAGE_KEYS.index(i["stage"]), i["id"], i["label"], i["path"]) for u, i in layout.info.items()}
        stage_now = {k: (s["gx"], s["gw"], s["gy"], s["gh"]) for k, s in geo["stages"].items()}
        world_now = (geo["cols"], geo["rows"], geo["foundTop"], geo["foundRows"], geo["elmEnd"] if geo["hasElmFound"] else 0,
                     geo["cppGx"] if geo["hasCppFound"] else 0,
                     geo["cols"] - geo["cppGx"] if geo["hasCppFound"] else 0, geo["sections"][0]["gx"] - geo["cppGx"],
                     geo["sections"][1]["gx"] - geo["cppGx"])
        if (pos == last_pos and info_now == last_info and uid_edges == last_edges and stage_now == last_geo
                and world_track and world_track[-1][1:] == world_now):
            continue
        f = len(frames)
        frames.append((h[:10], t, subject))
        for u in set(pos) | set(last_pos):
            was, now = u in last_pos, u in pos
            if now and not was:
                lives[u].append(f)
            if was and not now:
                lives[u].append(f)
            if now and (not was or pos[u] != last_pos[u]):
                tracks[u].append((f,) + pos[u])
            if now and (not was or info_now[u] != last_info.get(u)):
                infos[u].append((f,) + info_now[u])
        for e in uid_edges ^ last_edges:
            edge_lives[e].append(f)
        for k in set(stage_now) | set(last_geo):
            if stage_now.get(k) != last_geo.get(k):
                stage_tracks[k].append((f,) + stage_now[k] if k in stage_now else (f,))
        if not world_track or world_track[-1][1:] != world_now:
            world_track.append((f,) + world_now)
        last_pos, last_info, last_edges, last_geo = pos, info_now, uid_edges, stage_now
        if n_commit % 100 == 0:
            print(f"{n_commit}/{len(commits)} {len(nodes)} nodes {len(edges)} edges", file=sys.stderr)

    if missing_packages:
        print("missing packages, not linking their kernels:", ", ".join(sorted(missing_packages)), file=sys.stderr)
    roots = ROOTS | programs
    used = {b for _, b in edges}
    unused = sorted(i for i in nodes if i not in roots and i not in used)
    if unused:
        print("used by nothing:", ", ".join(unused), file=sys.stderr)

    data = dict(
        stages=[dict(key=k, title=t, blurb=b, lang=l, row=r) for k, t, b, l, r in STAGES],
        branch=[BRANCH_FROM, BRANCH_TO],
        sections=[dict(key=k, title=t) for k, t, _ in CPP_FOUND],
        nodeW=NODE_W, nodeH=NODE_H,
        frames=[list(fr) for fr in frames],
        nodes=[dict(lang=layout_lang(layout, infos, u), life=lives[u], pos=[list(x) for x in tracks[u]],
                    info=[list(x) for x in infos[u]])
               for u in range(len(layout.uids))],
        edges=[[a, b] + lives_ for (a, b), lives_ in sorted(edge_lives.items())],
        stageTracks={k: [list(x) for x in v] for k, v in stage_tracks.items()},
        world=[list(x) for x in world_track],
    )
    json.dump(data, open(OUT, "w"), separators=(",", ":"))
    print(len(frames), "frames,", len(layout.uids), "nodes ever,", len(nodes), "now,", len(edges), "edges now",
          file=sys.stderr)


def layout_lang(layout, infos, u):
    return "cpp" if layout.uids[u].startswith("cpp:") else "elm"


main()
