"""Extract eco's module/file dependency graph and lay it out by pipeline stage.

Usage: python3 -I script/atlas-graph.py ../eco-compiler content/atlas/graph.json

The atlas page at /atlas reads the output at build time.

Every node but the programs should be used by something. The dependencies
come from Elm imports, C++ #includes, C++ names used in one file and defined
in another, kernel calls from Elm to C++, and the kernel libraries CMake has
eco-boot link into programs. The Elm packages the compiler depends on are read
from ELM_HOME (~/.elm by default). Anything other than a program that nothing
uses is listed on stderr.
"""
import json, os, re, sys
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


def elm_stage(m):
    p = m.split(".")
    if p[0] in ("Terminal", "API", "Builder") or m in ("Compiler.Compile",):
        return "driver"
    if m.startswith("Compiler.Parse."):
        return "parse"
    if m.startswith("Compiler.Canonicalize."):
        return "canon"
    if m.startswith("Compiler.Type.") or m.startswith("Compiler.TypedCanonical."):
        return "type"
    if m.startswith("Compiler.Nitpick.") or m.startswith("Compiler.LocalOpt."):
        return "local"
    if m.startswith(("Compiler.Monomorphize.", "Compiler.MonoSolver.")) or m == "Compiler.Pipeline.Steps":
        return "mono"
    if m.startswith("Compiler.GlobalOpt."):
        return "global"
    if m.startswith("Compiler.Generate.MLIR") or p[0] == "Mlir":
        return "genmlir"
    if m == "Compiler.Generate.Mode":
        return None  # used by both generators
    if m.startswith("Compiler.Generate."):
        return "genjs"
    return None  # foundation


# ---------------------------------------------------------------- Elm
# The compiler is every module in the source directories of compiler/elm.json.
# Some modules (Eco.File, Eco.Process, ...) exist twice: compiler/src-xhr has
# the one for a compiler running on stock Elm, which reaches the file system
# through eco-io, and eco-kernel-cpp/src has the native one, which calls the
# C++ kernel. The build picks one, so each is a single node with the imports
# of both.
nodes = {}  # id -> dict
edges = set()
kernel_imports = defaultdict(set)   # Elm module -> kernel modules it imports, e.g. Eco.Kernel.File
package_imports = defaultdict(set)  # Elm module -> package modules it imports, e.g. Regex

COMPILER = os.path.join(ROOT, "compiler")
ELM_DIRS = [os.path.join("compiler", d)
            for d in json.load(open(os.path.join(COMPILER, "elm.json")))["source-directories"]]
TWIN_DIRS = ["eco-kernel-cpp/src"]


def elm_modules(base):
    out = {}
    for d, _, fs in os.walk(os.path.join(ROOT, base)):
        for f in fs:
            if f.endswith(".elm"):
                rel = os.path.relpath(os.path.join(d, f), ROOT)
                out[os.path.relpath(rel, base)[:-4].replace(os.sep, ".")] = rel
    return out


elm_files = defaultdict(list)  # module -> paths, relative to ROOT
for sd in ELM_DIRS:
    for mod, rel in elm_modules(sd).items():
        elm_files[mod].append(rel)
for td in TWIN_DIRS:
    for mod, rel in elm_modules(td).items():
        if mod in elm_files:
            elm_files[mod].append(rel)

imp_re = re.compile(r"^import\s+([A-Z][\w.]*)", re.M)
for mod, paths in elm_files.items():
    label = mod[len("Compiler."):] if mod.startswith("Compiler.") else mod
    nodes[mod] = dict(id=mod, label=label, lang="elm", stage=elm_stage(mod),
                      path=", ".join(paths), group=".".join(mod.split(".")[:3]))
    for rel in paths:
        text = open(os.path.join(ROOT, rel), encoding="utf-8").read()
        for m in imp_re.findall(text):
            if m in elm_files:
                if m != mod:
                    edges.add((mod, m))
            elif ".Kernel." in m:
                kernel_imports[mod].add(m)
            else:
                package_imports[mod].add(m)

# ---------------------------------------------------------------- C++
def cpp_node_for(rel):
    """Map a C++ file path (relative to ROOT) to (node id, label, stage, group)."""
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
    if rel.startswith("runtime/src/allocator/"):
        stem = re.sub(r"_(posix|win32)$", "", stem)
        return ("cpp:alloc:" + stem, stem, "runtime", "allocator")
    if rel.startswith("runtime/src/platform/"):
        return ("cpp:plat:" + stem, stem, "runtime", "platform")
    if rel.startswith("runtime/src/"):
        return ("cpp:rt:" + stem, stem, "native", "runtime")
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


def read(rel):
    return open(os.path.join(ROOT, rel), encoding="utf-8", errors="replace").read()


cpp_dirs = ["runtime/src", "elm-kernel-cpp/src", "eco-kernel-cpp/src", "system-kernel-cpp/src"]
by_base = defaultdict(list)  # include basename -> node ids
file_node = {}
for cd in cpp_dirs:
    for d, dirs, fs in os.walk(os.path.join(ROOT, cd)):
        dirs[:] = [x for x in dirs if x not in ("third_party", "vendor", "tests", "test")]
        for f in fs:
            if not re.search(r"\.(cpp|hpp|h|td)$", f):
                continue
            rel = os.path.relpath(os.path.join(d, f), ROOT)
            n = cpp_node_for(rel)
            if not n:
                continue
            nid, label, st, grp = n
            file_node[rel] = nid
            by_base[f].append(nid)
            if nid not in nodes:
                nodes[nid] = dict(id=nid, label=label, lang="cpp", stage=st, path=rel, group=grp, files=[])
            nodes[nid].setdefault("files", []).append(rel)

# Headers the build writes. TableGen turns each .td into .inc files that the
# dialect sources include, and CMake writes EcoBootConfig.h, the list of
# libraries eco-boot links a program against, which EcoBootConfig.cpp reads.
CODEGEN_CMAKE = "runtime/src/codegen/CMakeLists.txt"
codegen_cmake = read(CODEGEN_CMAKE)
td = None
for m in re.finditer(r"set\(LLVM_TARGET_DEFINITIONS\s+(\S+)\)|mlir_tablegen\(\S*?([\w.]+\.inc)\s", codegen_cmake):
    if m.group(1):
        td = file_node[os.path.join(os.path.dirname(CODEGEN_CMAKE), m.group(1))]
    elif td:
        by_base[m.group(2)].append(td)
by_base["EcoBootConfig.h"].append("cpp:cg:EcoBootConfig")

inc_re = re.compile(r'^\s*#\s*include\s+"([^"]+)"|^\s*include\s+"([^"]+)"', re.M)
includes = defaultdict(set)  # file -> node ids it includes
included = defaultdict(set)  # file -> files it includes
for rel, nid in file_node.items():
    for a, b in inc_re.findall(read(rel)):
        base = os.path.basename(a or b)
        cands = by_base.get(base, [])
        if not cands:
            continue
        # prefer a candidate in the same top-level library
        top = rel.split("/")[0]
        same = [c for c in cands if any(fp.startswith(top) for fp in nodes[c]["files"])]
        tgt = (same or cands)[0]
        includes[rel].add(tgt)
        included[rel] |= {f for f in nodes[tgt]["files"] if os.path.basename(f) == base}
        if tgt != nid:
            edges.add((nid, tgt))


# ---------------------------------------------------------------- C++ symbols
# An #include reaches a header, but the code behind it can be anywhere: every
# pass is declared in Passes.h and defined in a file of its own, and kernels
# are called by C name from code that includes none of their headers. So
# find what each .cpp file defines with external linkage, and where each of
# those names is used, and link the user to the definer.

def strip_cpp(text):
    """Blank comments and the insides of string and character literals,
    keeping the quotes, the newlines and every offset."""
    out = list(text)
    i, n = 0, len(text)

    def blank(a, b):
        for k in range(a, b):
            if out[k] != "\n":
                out[k] = " "

    while i < n:
        c = text[i]
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            blank(i, j)
            i = j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            blank(i, j)
            i = j
        elif c == "R" and text.startswith('R"', i) and not (i and (text[i - 1].isalnum() and text[i - 1] not in "uUL8")):
            m = re.match(r'R"([^(\s]*)\(', text[i:])
            if not m:
                i += 1
                continue
            end = text.find(")" + m.group(1) + '"', i)
            end = n if end < 0 else end + len(m.group(1)) + 2
            blank(i + 2, end - 1)
            i = end
        elif c in "\"'":
            if c == "'" and i and text[i - 1].isalnum():  # digit separator, 1'000
                i += 1
                continue
            j = i + 1
            while j < n and text[j] != c and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            blank(i + 1, j)
            i = j + 1
        else:
            i += 1
    return "".join(out)


def without_preprocessor(code):
    """Blank preprocessor lines, with their continuations."""
    lines = code.split("\n")
    cont = False
    for k, line in enumerate(lines):
        if cont or line.lstrip().startswith("#"):
            cont = line.rstrip().endswith("\\")
            lines[k] = " " * len(line)
    return "\n".join(lines)


def matching(code, i, open_, close):
    """The index of the bracket that closes the one at i."""
    depth = 0
    for j in range(i, len(code)):
        if code[j] == open_:
            depth += 1
        elif code[j] == close:
            depth -= 1
            if depth == 0:
                return j
    return len(code) - 1


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
            if depth == 0:
                rest = head[j + 1:]
                m = re.match(r"\s*(?:const|noexcept|override|final|\s)*:(?!:)", rest)
                if m:
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
    prefix = before[:m.start()]
    if re.search(r"\bstatic\b", prefix):
        return None
    return name


def scan(code):
    """What a file defines at namespace scope.

    Returns (defs, classes, opened): defs are (namespace, name, kind) for the
    functions and variables it defines with external linkage, where namespace
    is the full "a::b" the name is in and a qualified name's class, if any, is
    kept in it; classes are the classes it defines; opened are the namespaces
    it opens or brings in with `using namespace`.
    """
    defs, classes, opened = [], set(), set()
    stack = []  # namespace names, "" for an anonymous one
    start, i, n = 0, 0, len(code)

    def here():
        return [x for x in stack if x is not None]

    while i < n:
        c = code[i]
        if c == "{":
            head = clean_head(code[start:i])
            internal = "" in stack
            ns = re.search(r"(?:^|[\s;)}])(?:inline\s+)?namespace(?:\s+([\w:]+))?$", head)
            if head.count("(") > head.count(")"):
                # a brace inside a macro's argument
                i = matching(code, i, "{", "}")
                start = i + 1
            elif ns:
                stack.append(ns.group(1) or "")
                opened.add("::".join(x for x in here() if x))
                start = i + 1
            elif re.fullmatch(r'extern\s*"\s*"', head):
                stack.append(None)
                start = i + 1
            else:
                cm = re.match(r"(?:typedef\s+)?(class|struct|union)\b(.*)$", head, re.S)
                if cm:
                    names = re.findall(r"[A-Za-z_]\w*", re.sub(r"alignas\s*\([^()]*\)", "", re.split(r"(?<!:):(?!:)", cm.group(2))[0]))
                    names = [x for x in names if x != "final"]
                    if names:
                        classes.add(names[-1])
                elif not internal and not head.startswith(("enum", "using", "typedef")):
                    fn = function_name(head)
                    prefix = "::".join(x for x in here() if x)
                    if fn:
                        parts = fn.split("::")
                        defs.append(("::".join(([prefix] if prefix else []) + parts[:-1]), parts[-1], "function"))
                    elif "(" not in head and not re.search(r"\bstatic\b", head):
                        vm = re.search(r"([A-Za-z_]\w*)\s*(?:\[[^\]]*\]\s*)*=?\s*$", head)
                        if vm and vm.group(1) not in KEYWORDS and len(head.split()) > 1:
                            defs.append((prefix, vm.group(1), "variable"))
                i = matching(code, i, "{", "}")
                start = i + 1
        elif c == "}":
            if stack:
                stack.pop()
            start = i + 1
        elif c == ";":
            stmt = clean_head(code[start:i])
            um = re.fullmatch(r"using\s+namespace\s+([\w:]+)", stmt)
            if um:
                opened.add(um.group(1).lstrip(":"))
            elif ("" not in stack and stmt
                    and not re.match(r"(using|typedef|template|friend|static_assert|class|struct|enum|union|extern|namespace)\b", stmt)
                    and not re.search(r"\bstatic\b", stmt)):
                lhs = stmt.split("=")[0]
                if "(" not in lhs and len(lhs.split()) > 1:
                    vm = re.search(r"([A-Za-z_]\w*)\s*(?:\[[^\]]*\]\s*)*$", lhs)
                    if vm and vm.group(1) not in KEYWORDS:
                        defs.append(("::".join(x for x in here() if x), vm.group(1), "variable"))
            start = i + 1
        i += 1
    return defs, classes, opened


code_of = {rel: strip_cpp(read(rel)) for rel in file_node if not rel.endswith(".td")}
scanned = {rel: scan(without_preprocessor(code)) for rel, code in code_of.items()}
tok_re = re.compile(r"[A-Za-z_]\w*")
tokens_of = {rel: set(tok_re.findall(code)) for rel, code in code_of.items()}

# where each class is defined, if in exactly one node
class_home = defaultdict(set)
for rel, (_, cl, _) in scanned.items():
    for c in cl:
        class_home[c].add(file_node[rel])

# MSVC has no weak symbols: a file names its default for one in a linker
# directive, /alternatename:symbol=default.
for rel in scanned:
    for m in re.finditer(r"/alternatename:(\w+)=", read(rel)):
        scanned[rel][0].append(("", m.group(1), "function"))

# A member defined outside the node that defines its class: the class's node
# is implemented, in part, by the definer.
free = defaultdict(set)  # name -> (namespace, node) for functions and variables
for rel, (defs, _, _) in scanned.items():
    if not rel.endswith(".cpp"):
        continue
    nid = file_node[rel]
    for ns, name, kind in defs:
        owner_class = ns.split("::")[-1] if ns else ""
        if owner_class in class_home:
            homes = class_home[owner_class] - {nid}
            if len(class_home[owner_class]) == 1 and homes:
                edges.add((next(iter(homes)), nid))
        else:
            free[name].add((ns, nid))


def closure(rel, seen=None):
    """The files rel includes, directly or not."""
    seen = set() if seen is None else seen
    for f in included.get(rel, ()):
        if f not in seen:
            seen.add(f)
            closure(f, seen)
    return seen


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


# A program is a file that defines main. Nothing links a program, so a weak
# default a program defines for itself, as ecoc does for
# Eco_Kernel_register_all_gc_roots, is not something other code uses.
programs = {o for _, o in free.get("main", ())}

NOT_A_CALL = {"return", "else", "case", "new", "delete", "throw", "co_return", "co_await", "co_yield", "do"}
for rel, code in code_of.items():
    nid = file_node[rel]
    seen = set()
    for f in closure(rel):
        seen |= tokens_of.get(f, set())
    opened = scanned[rel][2]
    declared = set()
    uses = []
    for m in tok_re.finditer(code):
        name = m.group(0)
        if name not in free or name == "main":
            continue
        before = code[max(0, m.start() - 120):m.start()].rstrip()
        if before.endswith(".") or before.endswith("->"):
            continue
        qm = re.search(r"((?:[A-Za-z_]\w*\s*::\s*)+)$", before)
        qualifier = re.sub(r"\s+", "", qm.group(1))[:-2] if qm else ""
        if before.endswith("::") and not qm:
            qualifier = ""  # ::name
        prev = re.search(r"([A-Za-z_]\w*|(?<=[\w>])\s*[*&]+|>)\s*$", before[:qm.start()] if qm else before)
        if prev and prev.group(1).strip() not in NOT_A_CALL and not qm:
            declared.add(name)  # `T name(` or `extern T name;` declares rather than uses
            continue
        uses.append((name, qualifier))
    for name, qualifier in uses:
        if name not in seen and name not in declared:
            continue
        owners = {o for ns, o in free[name] if reaches(ns, qualifier, opened)} - {nid} - programs
        if 0 < len(owners) <= 3:
            for o in owners:
                edges.add((nid, o))

for n in nodes.values():
    if n["lang"] == "cpp":
        fs = sorted(n["files"])
        n["path"] = os.path.dirname(fs[0]) + "/" if len(fs) > 2 else ", ".join(fs)


# ---------------------------------------------------------------- Elm to C++
# An Elm module that imports a kernel module, Eco.Kernel.File say, calls the
# C functions named Eco_Kernel_File_*. A module that imports a package module
# that imports a kernel module, as Regex imports Elm.Kernel.Regex, calls
# Elm_Kernel_Regex_* through it. The packages are read from ELM_HOME, as the
# Elm compiler downloads them.
def kernel_definers(prefix):
    return {o for name, owners in free.items() if name.startswith(prefix) for _, o in owners}


package_kernels = defaultdict(set)  # package module -> kernel modules it imports
elm_home = os.environ.get("ELM_HOME", os.path.expanduser("~/.elm"))
deps = json.load(open(os.path.join(COMPILER, "elm.json")))["dependencies"]
for pkg, version in list(deps["direct"].items()) + list(deps["indirect"].items()):
    pkg_src = os.path.join(elm_home, "0.19.1", "packages", pkg, version, "src")
    if not os.path.isdir(pkg_src):
        print("missing package, not linking its kernels:", pkg, version, file=sys.stderr)
        continue
    for pm, rel in elm_modules(os.path.relpath(pkg_src, ROOT)).items():
        package_kernels[pm] = {m for m in imp_re.findall(read(rel)) if ".Kernel." in m}
for mod, pms in package_imports.items():
    for pm in pms:
        kernel_imports[mod] |= package_kernels.get(pm, set())
for mod, kms in kernel_imports.items():
    for km in kms:
        for o in kernel_definers(km.replace(".", "_") + "_"):
            edges.add((mod, o))


# ---------------------------------------------------------------- build
# eco-boot links every program it builds against each kernel library, by
# name from the generated EcoBootConfig.h, so that header uses them all.
def cmake_libraries(cm):
    text = read(cm)
    base = os.path.dirname(cm)
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


libraries = {}
for cm in ("elm-kernel-cpp/CMakeLists.txt", "eco-kernel-cpp/CMakeLists.txt", "system-kernel-cpp/CMakeLists.txt"):
    libraries.update(cmake_libraries(cm))
for var, prefix in (("ECO_ELM_KERNEL_MODS", "ElmKernel_"), ("ECO_KERNEL_MODS", "EcoKernel_"),
                    ("ECO_SYSTEM_MODS", "EcoSystem_")):
    mods = re.search(r"set\(" + var + r"\s+(.*?)\s+CACHE", codegen_cmake, re.S).group(1).split()
    for mod in mods:
        for src_file in libraries[prefix + mod]:
            if src_file in file_node and file_node[src_file] != "cpp:cg:EcoBootConfig":
                edges.add(("cpp:cg:EcoBootConfig", file_node[src_file]))

# Nothing in the compiler depends on these: the programs, the Node.js addon,
# and EcoRunner, the library the tests run compiled code with.
ROOTS = {"Terminal.Main", "API.Main", "cpp:embed:eco_node_addon", "cpp:cg:EcoRunner"} | programs
unused = sorted(i for i in nodes if i not in ROOTS and not any(b == i for _, b in edges))
if unused:
    print("used by nothing:", ", ".join(unused), file=sys.stderr)

# ---------------------------------------------------------------- C++ foundation
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
for _, _, ids in CPP_FOUND:
    for i in ids:
        assert i in nodes, i
        nodes[i]["stage"] = "cppfound"


# ---------------------------------------------------------------- layout
# Everything is in grid cells. A node's footprint is NODE_W cells by NODE_H
# rows: its text sits in row 1, and the page draws its frame on the
# in-between grid around that. Columns are COL_PITCH cells apart.
NODE_W, NODE_H, COL_PITCH = 13, 3, 15
HEAD_ROWS = 9          # stage header rows; nodes start on this row
STAGE_GAP = 2          # cells between stage footprints (arrow lives here)
MIN_COLS = 2

out_adj = defaultdict(set)
in_adj = defaultdict(set)
for a, b in edges:
    out_adj[a].add(b)
    in_adj[b].add(a)

pos = {}
MAXROWS = 24
ROW_GAP = 3            # rows between the two pipeline rows


def stage_columns(key):
    """Columns of node ids for a stage: importers left, what they import right."""
    ids = {n["id"] for n in nodes.values() if n["stage"] == key}
    depth = {}

    def d(i, seen=()):
        if i in depth:
            return depth[i]
        preds = [p for p in in_adj[i] if p in ids and p not in seen]
        v = 0 if not preds else 1 + max(d(p, seen + (i,)) for p in preds)
        depth[i] = v
        return v

    for i in ids:
        d(i)
    cols = defaultdict(list)
    for i in ids:
        cols[min(depth[i], 2)].append(i)
    col_lists = []
    for c in sorted(cols):
        lst = sorted(cols[c], key=lambda i: (nodes[i]["group"], nodes[i]["label"]))
        for k in range(0, len(lst), MAXROWS):
            col_lists.append(lst[k:k + MAXROWS])
    return ids, col_lists


# First pass: widths and heights. Row 0 runs left to right; row 1 starts at
# the column where the stage after the branch point starts in row 0.
info = {}
row_x = {0: 0, 1: None}
for key, title, blurb, lang, row in STAGES:
    ids, col_lists = stage_columns(key)
    if row == 1 and row_x[1] is None:
        branch = info[BRANCH_FROM]
        row_x[1] = branch["gx"] + branch["gw"] + STAGE_GAP
    gw = max(MIN_COLS, len(col_lists)) * COL_PITCH
    info[key] = dict(gx=row_x[row], gw=gw, col_lists=col_lists, count=len(ids), row=row)
    row_x[row] += gw + STAGE_GAP

row_rows = {}
for r in (0, 1):
    tallest = max((len(l) for s in info.values() if s["row"] == r for l in s["col_lists"]), default=0)
    row_rows[r] = HEAD_ROWS + tallest * NODE_H + 1
row_top = {0: 0, 1: row_rows[0] + ROW_GAP}

stage_boxes = []
for key, title, blurb, lang, row in STAGES:
    s = info[key]
    for ci, lst in enumerate(s["col_lists"]):
        for ri, i in enumerate(lst):
            pos[i] = (s["gx"] + 1 + ci * COL_PITCH, row_top[row] + HEAD_ROWS + ri * NODE_H)
    stage_boxes.append(dict(key=key, title=title, blurb=blurb, lang=lang, row=row,
                            gx=s["gx"], gw=s["gw"], gy=row_top[row], gh=row_rows[row], count=s["count"]))

world_cols = max(row_x.values()) - STAGE_GAP
stage_rows = row_top[1] + row_rows[1]
elm_end = max(s["gx"] + s["gw"] for s in stage_boxes if s["lang"] == "elm")

# foundation band: each module sits under the mean column of its users,
# packed into rows that keep footprints a column pitch apart
FOUND_TOP = stage_rows + 3
FOUND_HEAD = 7
found = [n["id"] for n in nodes.values() if n["stage"] is None]
for n in found:
    nodes[n]["stage"] = "foundation"

for _ in range(3):
    want = {}
    for i in found:
        xs = [pos[p][0] for p in in_adj[i] if p in pos]
        want[i] = sum(xs) / len(xs) if xs else elm_end / 2
    rows = []
    tmp = {}
    for i in sorted(found, key=lambda i: want[i]):
        wx = int(round(max(1, min(elm_end - NODE_W - 1, want[i]))))
        r = 0
        while True:
            if r == len(rows):
                rows.append([])
            if all(abs(wx - ox) >= COL_PITCH for ox in rows[r]):
                rows[r].append(wx)
                tmp[i] = (wx, FOUND_TOP + FOUND_HEAD + r * NODE_H)
                break
            r += 1
    pos.update(tmp)

# C++ foundation: under the C++ stages, one section per group, each a few
# columns under its own sub-heading (rows 7-8); nodes from row 9.
CPP_PER_COL = 4
cpp_gx = min(s["gx"] for s in stage_boxes if s["lang"] == "cpp")
sections = []
sx = cpp_gx + 1
for key, title, ids in CPP_FOUND:
    ncols = -(-len(ids) // CPP_PER_COL)
    for k, i in enumerate(ids):
        pos[i] = (sx + (k // CPP_PER_COL) * COL_PITCH, FOUND_TOP + FOUND_HEAD + 2 + (k % CPP_PER_COL) * NODE_H)
    sections.append(dict(key=key, title=title, gx=sx))
    sx += ncols * COL_PITCH + 2

found_rows = max(FOUND_HEAD + len(rows) * NODE_H, FOUND_HEAD + 2 + CPP_PER_COL * NODE_H) + 1
world_rows = FOUND_TOP + found_rows

for i, (px, py) in pos.items():
    nodes[i]["gx"], nodes[i]["gy"] = px, py

order = sorted(nodes, key=lambda i: (nodes[i]["gx"], nodes[i]["gy"]))
index = {i: k for k, i in enumerate(order)}
data = dict(
    world=dict(cols=world_cols, rows=world_rows, stageRows=stage_rows, branch=[BRANCH_FROM, BRANCH_TO],
               foundTop=FOUND_TOP, foundRows=found_rows, foundCols=elm_end,
               cppFound=dict(gx=cpp_gx, gw=world_cols - cpp_gx, sections=sections),
               nodeW=NODE_W, nodeH=NODE_H),
    stages=stage_boxes,
    nodes=[[nodes[i]["label"], nodes[i]["lang"], nodes[i]["stage"], nodes[i]["gx"], nodes[i]["gy"], nodes[i]["path"], i] for i in order],
    edges=sorted([index[a], index[b]] for a, b in edges),
)
json.dump(data, open(OUT, "w"), separators=(",", ":"))
print(len(nodes), "nodes", len(edges), "edges", "world cells", world_cols, world_rows)
