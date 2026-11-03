---
status: done
updated: 2026-11-03
remaining: "Accepted as finished by the user on 2026-11-03: phase 2's tool-call check is recorded as unmet (§20, §18.4); the eco bugs in §21 stay logged for a later fix in eco-compiler, with kg's workarounds in place; moving kg into eco-compiler is a later decision."
---

# A knowledge graph of the compiler, for Claude Code

**Status (2026-11-03): implemented; accepted with one check unmet.** All eight phases are built, with their
results under each phase in §20, the evaluation in §18.4, the eco findings in
§21 and the deviations from this text in §23. kg is in `kg/`; `kg/README.md`
says how to build and use it.

This plan is written to be implemented from. §1–§4 say what and why. §5–§19
specify the work. §20 gives the phases as task lists with acceptance checks.
Facts it relies on were checked on 2026-11-03 against eco 0.2.0
(`/usr/local/bin/eco`), eco-compiler master `a874aa90`, the MCP specification
and the Claude Code documentation. Where something could not be checked, the
plan says so and phase 0 checks it.

## 1. Goal

Give Claude Code a queryable map of eco: what is in the compiler, where it sits
in the pipeline, what depends on what, what each part is for, which plans,
design docs and invariants talk about it, and how it got that way. Claude uses
it through an MCP server, whose tools answer those questions in one call each,
and whose instructions give a short orientation to every session.

The graph is rebuilt from the repository and kept current on every commit, in
every worktree, including uncommitted edits.

**Where it is built.** It is a prototype in this repository (www-eco-lang),
under `kg/`.
- It reads eco-compiler and its worktrees through `git` and the file system.
- It writes nothing inside the eco-compiler tree, including its git directory.
- If the prototype proves itself (§18), it moves into eco-compiler later.

**Dogfooding.** Everything is Elm built with eco, except:
- `git` itself;
- the embedding model server;
- nothing else: the parser is a copy checked into `kg/parser/` (§6.2).

The MCP server is 100% Elm, an `eco/system` program. What the prototype needs
from eco, and every eco bug it finds, is a result in itself (§21).

**Non-goals:**
- no model training: no graph neural network, no fine-tuning;
- the graph does not replace reading code; it tells Claude which code to read;
- nothing is sent to an outside service: embeddings are computed locally.

## 2. Why: what costs time today

Four questions from one session (2026-11-03) show the gaps. Each took a dozen
or more tool calls:

| question | what it took | the gap |
|---|---|---|
| What is `Monomorphize.EntryPrep`, and should it be in the driver? | reading the module, `Pipeline.Steps`, `Builder.Generate` | **orientation**: the pipeline order and each stage's entry are stable facts, rebuilt each time |
| Are `GlobalOpt.PreMono.*` global or local passes? | reading signatures for `TOpt.GlobalGraph`, imports of `EntryPrep` | **data flow**: which IR each stage consumes and produces |
| Where does borrow inference run, and should it be its own stage? | reading `MonoGlobalOptimize` step order, `Borrow.Facts` docs, `Config.default` | **pipeline position, config gates** |
| Do we have escape analysis anywhere? | `grep escape` found string escaping; the answer was under *promotion*, `sret`, `psplit`, `aggPromote`, a deleted C++ pipeline (`5ab78669`) and three plans | **vocabulary mismatch, scattered concepts, history, plan status** |

These four, and twelve more like them, are the benchmark (§18).

## 3. Decisions

| # | decision | reason |
|---|---|---|
| D1 | Everything in Elm, built with `eco make`, apart from the three exceptions in §1 | dogfooding; eco/system has what is needed (§5) |
| D2 | No database. An in-memory graph, content-addressed fact and vector caches, and per-worktree snapshots, all as `elm/bytes` files | small data (§13.6); one view per worktree; no service to run |
| D3 | All queries go through `Kg.Query` | the storage can change behind it; fallback thresholds in §11.5 |
| D4 | Elm sources are parsed with eco's own parser, from a copy checked into `kg/parser/` (changed 2026-11-03 from a vendored archive of `compiler/src` and `compiler/src-xhr`; §6.2) | exact AST with doc comments; dogfood; kg builds on nothing from eco-compiler and needs nothing from `eco/kernel` |
| D5 | C++ extraction is a port of `script/atlas-graph.py`'s scanner and linker | already tuned against false edges |
| D6 | MCP protocol revision `2025-11-25` (the "legacy", initialize-based era); unknown methods, including `server/discover`, get error -32601 at once | the simplest era to implement; Claude Code falls back to it when the probe gets an error (§14.1) |
| D7 | The server learns its worktree from `CLAUDE_PROJECT_DIR`, with a command-line fallback; it is registered with `--scope local` in each eco-compiler worktree | one view per worktree; nothing written to eco-compiler; not loaded in other projects (§15) |
| D8 | Freshness is checked on every query; watching the source roots only speeds it up; no git hooks | correctness never depends on a trigger; nothing installed in eco-compiler |
| D9 | Embeddings come from Ollama on `localhost:11434`; the default model is `nomic-embed-text` cut to 384 dimensions (chosen in phase 5, from `snowflake-arctic-embed:s`); search works keyword-only when Ollama is not running | the best evaluation run, and fast enough per query (0.16 s); no bge-small exists in Ollama's library (§13.3) |
| D10 | Hashes: git blob ids (SHA-1 from git) for files; SHA-256 from the pure-Elm package `billstclair/elm-sha256` for chunk text | there is no hash in eco/system or elm/core |
| D11 | Curated concepts live in `kg/knowledge/concepts.json`, not YAML | Elm has no YAML in its core packages; JSON decodes with `elm/json` |

## 4. What exists to build on

- **`script/atlas-graph.py`** (www-eco-lang, 1,045 lines). It replays
  eco-compiler's first-parent history (`git log --first-parent -M --raw`,
  blobs through `git cat-file --batch`), and its main parts are:
  - the stage rules `elm_stage` and `cpp_node_for`;
  - the C++ scanner (`strip_cpp`, `scan`, `CppFile`);
  - the linker `extract`, which covers Elm imports, C++ includes resolved like
    a compiler, symbol uses with namespace lookup, Elm → C++ kernel links and
    CMake library links;
  - the slot layout used by the atlas (`Layout`).

  What it keeps in memory:
  - it caches parsed C++ files by blob id while they are live;
  - it rescans Elm imports at every commit.

  A full replay of 1,255 commits takes about 86 s, about 68 ms per commit for
  everything, at module level (468 nodes, 3,092 edges now).
- **eco-compiler**:
  - module doc comments (about 8,600 `{-|` comments in `compiler/src` and
    `src-xhr`);
  - `plans/`: 602 top-level plans with front matter
    `status`/`updated`/`remaining`/`superseded_by`;
  - `design_docs/`: 47 entries plus `theory/`; it also holds PDFs, SVGs and
    vendored MLIR docs, which are skipped;
  - `THEORY.md`;
  - `design_docs/invariants.csv`: 418 invariants;
  - the config switches in `compiler/src/Compiler/Eco/Config.elm`;
  - 2,064 commits;
  - worktrees `deep`, `med` and `quick` under `worktrees/`, inside the main
    worktree's directory.

## 5. eco facts the design relies on

All checked against the `eco/system` source (`system-kernel-cpp/src/*.elm`) and
the kernels. File and line references are in eco-compiler.

- **Program shape.** `main : Platform.Program System.Environment Model Msg`
  with `System.program { init, update, subscriptions }`, where
  `init : System.Environment -> ( Model, Cmd Msg )`.
  - `Environment` has `args` (C `argv`, program name first), `stdin`,
    `stdout` and `stderr`.
  - The program stays alive while a read is pending, a child process lives, or
    a subscription exists (`System.elm:38-57`).
  - `System.exit`, `System.exitWithCode`, and
    `System.environmentVariables : Task x (Dict String String)`.
- **Standard input and output.**
  - `Stream.readLine : Readable Bytes -> Task Stream.Error String` strips `\n`
    and a trailing `\r`.
  - End of input is the error `Stream.Closed`.
  - `Stream.readLine` cancels the stream on invalid UTF-8.
  - `Stream.logLine : String -> Writable Bytes -> Task x ()` never fails.
  - The example to model on is `examples/src/Nl.elm:21-52`.
- **Child processes.**
  - `ChildProcess.run : String -> List String -> RunOptions -> Task FailedRun SuccessfulRun`.
    `defaultRunOptions` caps each output stream at 1 MiB
    (`maximumBytesWrittenToStreams`) and uses `DefaultShell`.
  - `ChildProcess.spawn` with connection `External ({ processId, streams } -> msg)`
    gives `streams : { stdin : Writable Bytes, stdout : Readable Bytes, stderr : Readable Bytes }`.
    The example to model on is `test/eco-system/src/ProcessSpawnExternalTest.elm`.
  - **Always set `shell = NoShell`.** `DefaultShell` joins the arguments into
    `/bin/sh -c` without quoting.
  - `readLine` and `read` can be mixed on one stream: bytes past the line stay
    in the stream for the next read (`Stream.elm:205-209`).
- **Files.**
  - In `FileSystem`:
    - `readFile : Path -> Task Error Bytes`;
    - `writeFile : Bytes -> Path -> Task Error Path`;
    - `writeFileWith` (`{ createNew, sync }`), for lock files;
    - `move` (new path first), `makeDirectory { recursive }`, `remove`,
      `listDirectory`, `homeDirectory`.
  - `Path.fromPosixString` and `Path.toPosixString`.
  - **Watching.** `watchRecursive : (WatchEvent -> msg) -> Path -> Sub msg`
    with `WatchEvent = Changed (Maybe Path) | Moved (Maybe Path)`; paths are
    relative to the watched directory. On Linux it uses inotify, one watch per
    directory, and has no exclude option.
- **HTTP.**
  - `elm/http` runs natively on libcurl (`elm-kernel-cpp/src/http`).
  - Requests run one at a time on one worker thread.
  - There is no timeout unless the request sets one.
  - Response bodies are buffered whole.
- **Bytes.**
  - `Bytes.Encode.float32` and `Bytes.Decode.float32` have native kernels.
  - Bytes fusion fuses fixed-width encoders, and decoder count loops with
    argument-free item reads (`unsignedInt8`).
  - A `float32 LE` decode loop is expected **not** to fuse in 0.2.0. It is
    correct, just slower (§13.6).
- **Regex.** eco's `elm/regex` kernel uses the vendored SRELL library
  (`elm-kernel-cpp/src/regex/Regex.hpp:16-20`), which supports lookbehind.
  Phase 0 tests it.
- **Packages.**
  - eco's package cache is `~/.eco/0.2.0/packages`, not `~/.elm`.
    `eco/system` comes bundled.
  - Other packages are downloaded once from package.elm-lang.org.
  - The compiler's dependency set is already in `~/.eco` (fetched by the
    parser experiment, below).
- **The parser as a library.** This was checked by experiment, building with
  `eco make` in 28 s to a 17.5 MB binary.
  - An application with `source-directories`
    `["src", "<eco-compiler>/compiler/src", "<eco-compiler>/compiler/src-xhr"]`
    builds. `src-xhr` supplies pure stand-ins for the IO modules the parser's
    error reporting imports (`System.IO`, `Eco.Console`, `Eco.File`,
    `Eco.Crash`). It must be listed; without it the build fails against the
    older `eco/kernel` bundled with eco 0.2.0.
  - Its dependencies are the compiler's own `elm.json` set, plus `eco/system`
    and `elm/virtual-dom` (indirect).
  - The entry point is
    `Compiler.Parse.Module.fromByteString : ProjectType -> String -> Result E.Error Src.Module`.
    It takes a `String`, and `ProjectType = Package Pkg.Name | Application | KernelApplication Pkg.Name`.
  - The result `Src.Module` keeps `docs : Docs`
    (`NoDocs A.Region (List (Name, Comment)) | YesDocs Comment (List (Name, Comment))`,
    declaration docs in reverse order). The text of a `Comment (Snippet { fptr, offset, length, ... })`
    is `String.slice offset (offset + length) fptr`.

## 6. Repository layout and build

### 6.1 Layout

```
kg/
  elm.json                 application (§6.3)
  parser/                  kg's copy of eco's parser, 33 modules (§6.2, parser/README.md)
  scripts/
    eval-summary.py        tables from evaluation results (§18.4)
  src/
    Main.elm               command line (§16)
    Kg/Cli.elm             argument parsing
    Mcp/Protocol.elm       JSON-RPC 2.0 and MCP message types, decoders, encoders (pure)
    Mcp/Server.elm         the stdio loop (§14)
    Kg/Tools.elm           tool schemas and handlers, calling Kg.Query (pure)
    Kg/Git.elm             git access through ChildProcess (§7)
    Kg/Fs.elm              file helpers: atomic write, lock, cache paths (§11)
    Kg/Id.elm              node and edge ids (§9.1)
    Kg/Graph.elm           the graph types and operations (pure)
    Kg/Extract/Elm.elm     Elm facts via Compiler.Parse.Module (pure)
    Kg/Extract/Cpp.elm     the C++ scanner port (pure)
    Kg/Extract/Build.elm   elm.json and CMakeLists.txt facts (pure)
    Kg/Extract/Prose.elm   plans, design docs, THEORY.md, invariants.csv (pure)
    Kg/Extract/Config.elm  config flags (pure)
    Kg/Facts.elm           the FileFacts type and its codec (pure)
    Kg/Stages.elm          the stage table and rules (pure)
    Kg/Link.elm            facts -> graph for one tree (pure)
    Kg/History.elm         replay, moves, edits, co-change (pure core, §10)
    Kg/Layout.elm          the atlas slot layout, a port of Layout (pure)
    Kg/Atlas.elm           history.json export (pure)
    Kg/Search/Tokens.elm   tokenizer (pure)
    Kg/Search/Bm25.elm     keyword index (pure)
    Kg/Search/Vectors.elm  vector store and scan (pure)
    Kg/Search/Chunks.elm   chunking (pure)
    Kg/Embed.elm           the Ollama client (elm/http)
    Kg/Query.elm           every query the tools make (pure)
    Kg/Render.elm          tool output text and budgets (pure)
    Kg/Snapshot.elm        snapshot codec and IO
    Kg/Codec.elm           elm/bytes helpers: varints, strings, lists, dicts, versioned headers (pure)
    Kg/Update.elm          the incremental update driver (§12)
    Kg/Eval.elm            the evaluation harness (§18)
  tests/
    Run.elm                the test runner, an eco program (§19)
    Fixtures/…             small repositories as directories of files, with expected outputs
  knowledge/
    concepts.json          curated concepts (phase 6)
  eval/
    questions.json         the question set and reference answers
    results/               one JSON file per run (checked in)
  bin/                     build output (git-ignored)
  out/                     generated files (git-ignored)
```

"Pure" modules import nothing from `eco/system`, so they can be tested without
IO and can be shared with the website (§17).

### 6.2 The parser

**Changed on 2026-11-03.** kg first built the parser from a `git archive` of
eco-compiler's `compiler/src` and `compiler/src-xhr` at a pinned commit. That
built kg on the compiler's sources, and through them on its IO layer and its
crashes (`Utils.Crash`, `Eco.Crash`, with `src-xhr`'s stand-ins for
`eco/kernel`). It is replaced by a copy checked into `kg/parser/`: 28
modules, about 14,500 lines, from commit `a874aa90`, with the error
messages, the JSON and binary codecs, the IO layer, every crash and 50 dead
functions taken out, and GLSL left unparsed (the GLSL package crashes under
eco). `kg/parser/README.md` lists
each change. On every Elm file of eco-compiler without a shader the copy
gives kg the same facts as before; files with shaders now parse.

Changes in the compiler's parser are brought over by hand when kg needs them.

### 6.3 `kg/elm.json`

- `type: application`.
- `source-directories`: `["src", "parser"]`.
- `dependencies` (as built, 2026-11-03): direct `eco/system`, `elm/core`,
  `elm/bytes`, `elm/http`, `elm/json`, `elm/regex`, `elm/time`,
  `obiloud/numeric-decimal`, `rtfeldman/elm-hex`;
  indirect `elm/file`, `elm/parser`, `elm/url`, `elm/virtual-dom`. Nothing
  from `eco/kernel`.
- The tests (§19) use a second application, `kg/tests/elm.json`, with
  `source-directories` `["../src", "../parser", "."]` and the same
  dependencies.

### 6.4 Build

```sh
cd kg && eco make src/Main.elm --output=bin/kg
cd kg/tests && eco make Run.elm --output=../bin/kg-test && ../bin/kg-test
```

From the repository root, `npm run kg` builds, and `npm run atlas` also
exports the website's atlas. `kg/README.md` says how to register and use
the server.

## 7. Git access (`Kg.Git`)

Every git command:
- runs with `ChildProcess` and `shell = NoShell`;
- runs with `-C <worktree>`;
- runs with `--no-optional-locks`, so that `status` never takes `index.lock`
  in a worktree Claude is using;
- has `GIT_OPTIONAL_LOCKS=0` set in its environment, with
  `MergeWithEnvironmentVariables`.

| need | command | how the output is read |
|---|---|---|
| repository id | `git rev-parse --path-format=absolute --git-common-dir` | trim; the cache key is the first 16 hex characters of its SHA-256 |
| worktree root | `git rev-parse --path-format=absolute --show-toplevel` | trim |
| current commit | `git rev-parse HEAD` | trim |
| first-parent history | `git log --first-parent --diff-merges=first-parent --reverse -M --raw --no-abbrev --format=@%H%x09%ct%x09%s <range> -- <paths>` | lines starting `@` begin a commit (hash, committer time, subject, tab-separated); lines starting `:` are `:<mode> <mode> <old> <new> <status>\t<path>[\t<newpath>]`. Use `run` with `maximumBytesWrittenToStreams = 64 * 1024 * 1024`; the whole log is about 4 MB. |
| ancestry | `git merge-base --is-ancestor <a> <b>` | exit code 0 or 1 |
| merge base | `git merge-base <a> <b>` | trim |
| tree listing | `git ls-tree -r --full-tree <commit> -- <paths>` | `<mode> blob <sha>\t<path>` |
| dirty files | `git status --porcelain=v1 -z --untracked-files=all -- <paths>` | NUL-separated entries `XY path`; renames carry a second path |
| hash of a dirty file | `git hash-object --stdin-paths` (no `-w`) through `spawn`: write paths, read one hash per line | one long-lived process per update |
| blob contents | `git cat-file --batch` through `spawn` | see below |

`<paths>` is the extractor's path list: the Python `PATHS` plus `plans`,
`design_docs`, `THEORY.md` and `compiler/src/Compiler/Eco/Config.elm`.

**Reading `cat-file --batch`.**
1. Write `<sha>\n` to its stdin.
2. `readLine` gives the header `<sha> blob <size>`, or `<sha> missing`.
3. Then `read` chunks into an accumulator until it holds `size + 1` bytes (the
   body and a newline). Split with `Bytes.Decode.bytes size`, and keep the
   bytes past the newline for the next object.
4. Keep one request in flight, answering requests in order. A `Kg.Git.Batch`
   state machine holds the pending queue and the accumulator.

Blob bodies are decoded as UTF-8 with `Bytes.Decode.string`. A file that is
not valid UTF-8 gets an empty `FileFacts` with `error = "not UTF-8"`.

## 8. Extraction: file → facts

Extraction is a pure function `extract : String -> String -> FileFacts`, taking
the path and the text. Its result is cached by `(blob id, extractor version)`
(§11.2). `Kg.Facts.extractorVersion : Int` is bumped whenever any extractor
changes its output; that invalidates the whole fact cache.

```elm
type FileFacts
    = ElmFile ElmFacts
    | CppFile CppFacts
    | ElmJson { sourceDirectories : List String, dependencies : List ( String, String ) }
    | CMake { libraries : List ( String, List String ), variables : List ( String, List String ), tablegen : List TableGen }
    | Markdown MarkdownFacts
    | Invariants (List Invariant)
    | ConfigModule (List ConfigFlag)   -- in addition to ElmFile, for Compiler/Eco/Config.elm
    | Unparsed String                  -- why
```

### 8.1 Elm (`Kg.Extract.Elm`)

- **Parse** with `Compiler.Parse.Module.fromByteString Application text`. On
  `Err`, fall back to the Python's regex, `^import\s+([A-Z][\w.]*)` (multiline),
  for imports only, and record the parse error.
- **Facts:**

  ```elm
  type alias ElmFacts =
      { moduleName : String
      , imports : List { name : String, alias : Maybe String, exposing : Exposing }
      , moduleDoc : Maybe String
      , decls : List Decl
      , references : List { qualifier : String, name : String, line : Int }  -- qualified uses, for calls/uses_type (phase 4)
      , fieldReads : List { field : String, line : Int }                    -- `.field` and `x.field`, for gates
      , kernelImports : List String                                         -- imports whose name contains ".Kernel."
      }

  type alias Decl =
      { name : String, kind : DeclKind, signature : Maybe String, doc : Maybe String, line : Int }

  type DeclKind = Value | Union | Alias | Port
  ```

- `signature` is the type annotation's source text, sliced from the source by
  its region, with whitespace collapsed.
- `references` and `fieldReads` come from walking the expression AST of every
  value: `Var` qualified by an import alias or module name, and field access or
  accessor nodes.
- Phase 1 needs `moduleName`, `imports` and `kernelImports` only. The rest
  arrives in phase 4.

### 8.2 C++ (`Kg.Extract.Cpp`)

This is a port of the Python, function by function, keeping its regexes. Test
lookbehind under eco first (phase 0).

| Python | Elm |
|---|---|
| `LITERALS`, `strip_cpp` (blank comments and literals, keep newlines and offsets) | `stripCpp : String -> String` |
| `without_preprocessor` | `withoutPreprocessor` |
| `balanced_tail`, `clean_head`, `function_name`, `QUALS`, `NAME`, `KEYWORDS` | same names |
| `scan` (brace and semicolon scanner: definitions, classes, opened namespaces, `extern "C"`) | `scan : String -> { defs : List ( String, String ), classes : List String, opened : List String }` |
| `CppFile` (includes, tokens, and the lazy per-name `uses`) | `CppFacts`, computed eagerly (below) |
| `/alternatename:` directives (linker defaults) | added to `defs` with namespace `""` |

```elm
type alias CppFacts =
    { includes : List String
    , defs : List ( String, String )          -- (namespace, name)
    , classes : List String
    , opened : List String
    , uses : Dict String (List String)         -- name -> qualifiers it is used with ("" for none); declarations excluded
    , declares : List String                  -- names this file declares (`T name(` or `extern T name;`)
    , tokens : List String                    -- distinct identifiers
    , definesMain : Bool
    }
```

`uses` is computed for every identifier in the file, applying `CppFile.uses`'
rules:
- skip names after `.` or `->`;
- take the qualifier from a preceding `a::b::`;
- treat a name preceded by a type-like token as a declaration.

The Python computes `uses` lazily, only for names something defines. Eager is
simpler and is cached once per blob. If facts get too big, fall back to lazy
use in phase 3.

### 8.3 Build files (`Kg.Extract.Build`)

- **elm.json:** `source-directories` and the `direct` plus `indirect`
  dependencies.
- **CMakeLists.txt:** a port of `cmake_libraries`, plus:
  - the variables `ECO_ELM_KERNEL_MODS`, `ECO_KERNEL_MODS` and
    `ECO_SYSTEM_MODS`;
  - the `LLVM_TARGET_DEFINITIONS` and `mlir_tablegen` pairs (`TableGen`), as
    `extract` reads them.

### 8.4 Prose (`Kg.Extract.Prose`)

Only these files are prose:
- `plans/*.md`, top level only;
- `design_docs/**/*.md`;
- `design_docs/invariants.csv`;
- `THEORY.md`.

```elm
type alias MarkdownFacts =
    { frontMatter : Dict String String   -- plans only
    , title : String                     -- the first `# ` heading, else the file name
    , sections : List Section
    , mentions : List Mention
    }

type alias Section = { path : List String, startLine : Int, text : String }   -- path = headings from H1 down
type alias Mention = { target : String, line : Int }                           -- raw, resolved by Link
```

- **Front matter.** If the file starts with `---\n`, read lines up to the next
  `---`. Each `key: value` line gives one entry. A value in double quotes is
  unquoted with `\"` → `"`. Lines that don't match (continuations, comments)
  are appended to the previous value with a space. This handles every plan
  checked; `superseded_by` is free text and is stored as text.
- **Sections:** split at every heading line (`^#{1,6} `) outside fenced code
  blocks. `path` is the heading stack.
- **Mentions:**
  - every backticked span whose content matches
    `^[A-Z][A-Za-z0-9_]*(\.[A-Z][A-Za-z0-9_]*)*(\.[a-z][A-Za-z0-9_]*)?$` (a
    module or a qualified value);
  - every span or bare token matching
    `^[\w./-]+\.(elm|cpp|hpp|h|td|md)(:\d+)?$` (a path, with an optional line).
- **`invariants.csv`** is `;`-separated, but descriptions contain unquoted `;`.
  Rules:
  - skip blank lines and lines starting with `#`;
  - a row starts with an id matching `^[A-Z][A-Z0-9_]*;`;
  - field 1 is `id`, 2 `phase`, 3 `category`, 4 `status`;
  - the **last** field is `source`;
  - everything between field 4 and the last field, joined with `;`, is
    `description`;
  - `source` gives mentions (split on `,` and whitespace).

  Expect 418 rows.

### 8.5 Config flags (`Kg.Extract.Config`)

From `compiler/src/Compiler/Eco/Config.elm`:
- every field of every record type alias, with its path from `EcoConfig`
  (`aggPromote`, `borrow.enabled`, `mono.lss.enabled`, …);
- its default value, from the `default` record expression, as source text;
- its doc, the paragraph of the module or type doc that names it.

```elm
type alias ConfigFlag = { path : List String, typeName : String, default : String, doc : String }
```

Gates are resolved in §9.4.

## 9. Linking: facts → one tree's graph (`Kg.Link`)

`link : LinkInput -> Graph` is pure. `LinkInput` holds:
- the facts of every relevant file in the tree, by path;
- the package kernel table (§9.3);
- the stage table.

### 9.1 Ids

| node | id | label |
|---|---|---|
| Elm module | the module name, e.g. `Compiler.Parse.Module` (as the atlas) | the name without `Compiler.` |
| C++ component | `cpp:<group>:<stem>`, as `cpp_node_for` | as `cpp_node_for` |
| definition | `<module id>#<name>` | `<name>` |
| stage | `stage:<key>` | the title |
| plan | `plan:<file name without .md>` | the title |
| design doc section | `doc:<path>#<section path joined with />` | the heading |
| invariant | `inv:<id>` | the id |
| config flag | `flag:<path joined with .>` | the path |
| concept | `concept:<slug>` | the name |
| commit | `commit:<hash>` | the subject |

```elm
type alias Graph =
    { nodes : Dict String Node
    , out : Dict String (List Edge)     -- by source id, sorted by (kind, target)
    , inn : Dict String (List Edge)     -- by target id
    , fileNode : Dict String String     -- path -> node id
    }

type alias Node =
    { id : String, kind : NodeKind, label : String, stage : Maybe String
    , paths : List String, line : Maybe Int, doc : Maybe String, props : Dict String String }

type alias Edge = { kind : EdgeKind, from : String, to : String, weight : Float, line : Maybe Int }
```

`Dict` keeps keys sorted, so a graph built from the same facts is the same
value. This is the basis of the determinism check.

### 9.2 Stages (`Kg.Stages`)

- Port `STAGES`, `elm_stage`, `cpp_node_for`, `CPP_FOUND`, `ROOTS`, `PATHS`,
  `CPP_DIRS`, `CMAKES`, `TWIN_DIR` and `LIBRARIES` verbatim.
- Add a field `entry : Maybe String` to each stage. This is new, curated
  data:
  - driver: `Terminal.Main`;
  - parse: `Compiler.Parse.Module`;
  - canon: `Compiler.Canonicalize.Module`;
  - type: `Compiler.Type.Solve`;
  - local: `Compiler.LocalOpt.Typed.Module`;
  - mono: `Compiler.Monomorphize.Monomorphize`;
  - global: `Compiler.GlobalOpt.MonoGlobalOptimize`;
  - genmlir: `Compiler.Generate.MLIR.Backend`;
  - the others: none.

  Check each against the tree in phase 2 and correct it there; `kg check`
  fails on an entry that names no node.

### 9.3 Module-level edges

These ports produce the atlas graph:
- **The Elm rules of `extract`:**
  - source directories from the first of `ELM_JSONS` present;
  - twin modules from `eco-kernel-cpp/src/`;
  - `imports` edges;
  - kernel imports through package kernels.
- **The C++ rules of `extract`:**
  - the node and file maps;
  - tablegen and `EcoBootConfig.h` generated headers;
  - `resolve` for includes, giving `includes` edges;
  - `class_home` member edges and the `free` table, excluding programs;
  - `uses_symbol` edges, using the include closure, `reaches`, and the cap of
    three owners;
  - `kernel` edges from Elm kernel imports to C++ definers;
  - CMake library edges from `EcoBootConfig`.
- **Package kernels.** A port of `package_kernels`. It reads Elm packages from
  `$ELM_HOME/0.19.1/packages` (default `~/.elm`) as the Python does, so the
  graphs match. This is the only input that does not come from git; its
  contents are recorded in the snapshot header as a hash of the file list.

### 9.4 Definition-level and prose edges (phase 4)

- **Elm definitions:**
  - `defines`: module → each `Decl`;
  - `calls` / `uses_type`: definition → definition, from `references` resolved
    through the module's imports (alias, exposing, default imports). Unresolved
    references are dropped.
- **C++ definitions:**
  - `defines`: component → each `defs` entry with namespace (id
    `<component>#<ns>::<name>`);
  - `uses_symbol` at definition level is left for later.
- **`produces` / `consumes`.** For each stage with an `entry`, take the entry
  module's exposed values. Their signatures' argument types give `consumes`
  edges and their result types give `produces` edges, to the type
  definitions they resolve to. Phase 4 measures how many of these are right
  (§22).
- **`mentions`:** plan, doc section or invariant → the node a mention
  resolves to. Resolution order:
  1. exact module or definition id;
  2. unique suffix match on module ids;
  3. path to its file's node (with line);
  4. otherwise unresolved. Unresolved mentions are listed by `kg check` for
     open plans and for invariants.
- **`supersedes`:** plan → plan, for each `plans/<name>.md` named in
  `superseded_by`.
- **`gates`:** flag → definition, for each `fieldReads` entry whose field is
  the last segment of a flag path.
  - It is kept only when that segment is unique among all config record
    fields, or when the read's line also names the parent segment (`lss` for
    `enabled`).
  - Flags with no gate found are listed by `kg check`. Phase 4 samples 30
    gates by hand and needs at least 90% right before exposing the edge kind.
- **`in_stage`:** module → stage.

## 10. History (`Kg.History`)

### 10.1 Replay

1. **Read commits** with the first-parent log (§7) for the range wanted.
2. **For each commit, update the tree's file map** (path → blob id):
   - `A`/`M`: set the path;
   - `D`: delete the path;
   - `R`: move the path, and record `(old path, new path)`;
   - only `relevant` paths count (a port of `relevant`).
3. **Get facts for every changed blob** from the fact cache, or extract them
   from `cat-file` and add them to the cache.
4. **`link`** the whole tree from facts. That's whole-tree linking each commit,
   as the Python does.
5. **Diff against the previous commit's graph.** Nodes and edges added or
   removed; node renames are taken from the recorded path renames, mapping old
   node to new node exactly as the Python's `renamed` logic does.
6. **Record:**
   - `touched` (commit → nodes whose files changed, plus deletions within
     surviving nodes);
   - edit times;
   - `co_changes`: for every pair of distinct module or component nodes
     touched by the same commit, add 1. Commits touching more than 50 nodes
     are skipped for co-change, so bulk renames don't swamp it.
7. **Layout** (atlas only): step the slot layout (a port of `Layout`, §17)
   and record frames as the Python does.

### 10.2 History data in the snapshot

```elm
type alias History =
    { commits : Array { hash : String, time : Int, subject : String }
    , lives : Dict String (List Int)             -- node id -> commit indices it appeared and went, alternately
    , renames : Dict String (List ( Int, String ))  -- node id -> (commit index, previous id)
    , edits : Dict String (List Int)             -- node id -> commit indices that touched it
    , coChange : Dict ( String, String ) Int     -- (a, b) with a < b
    , lastIndexed : String                       -- commit hash
    }
```

Atlas frames (§17) are derived from this plus the layout, not stored
separately.

## 11. Storage (`Kg.Fs`, `Kg.Codec`, `Kg.Snapshot`)

### 11.1 Locations

```
~/.cache/eco-kg/<repo id>/
  facts/<aa>/<rest of blob id>.<extractorVersion>   FileFacts
  vectors/<model slug>/<aa>/<rest of sha256>        one vector
  worktrees/<sha256(worktree root)[0..16]>/
    snapshot.kg                                     the linked graph, history, indexes
    overlay.kg                                      facts and vectors of dirty files (§12.3)
    lock                                            update lock (§11.4)
```

`<repo id>` is the first 16 hex characters of the SHA-256 of the absolute
common git directory.

### 11.2 Fact and vector files

- **Fact files** are `Kg.Codec` encodings of `FileFacts`, written once and never
  changed.
- **A vector** is the dimension `d` as a `u16`, then `d` `float32` values,
  little-endian.
- Thousands of small files are fine for ext4. If listing or opening them is
  slow (measured in phase 3), pack them into one append-only file per kind
  with an index. That change stays inside `Kg.Fs`.

### 11.3 Snapshot

**Header:**
- magic `ECOKG`;
- `u16` format version;
- `u16` extractor version;
- the worktree root;
- the indexed commit;
- the hash of the package-kernel table;
- the embedding model;
- the dirty-set fingerprint (§12.3).

**Body:**
- the `Graph`;
- the `History`;
- the BM25 index;
- the vector block (§13.5);
- the chunk table.

**Encoding:**
- every list is a `u32` length then items;
- every string is a `u32` byte length then UTF-8;
- dicts are lists of pairs in key order.

A snapshot with a different format or extractor version is ignored and rebuilt.

### 11.4 Atomic writes and locks

- **Every write** goes to `<path>.tmp-<pid>-<time>`, then `FileSystem.move`
  onto the target. Readers never see a partial file.
- **Updates to one worktree's snapshot** take `lock`, created with
  `writeFileWith { createNew = True }`.
  - If the lock exists and is younger than 10 minutes, wait and retry every
    200 ms, up to 30 s. After that, answer from the existing snapshot, marked
    stale.
  - An older lock is stale and is removed.
- **Fact and vector files** need no lock: they are content-addressed, and a
  race writes identical bytes.

### 11.5 Fallback thresholds

Measured in phase 2 and phase 5, on the full eco-compiler graph:
- snapshot load over 2 s;
- process memory over 1 GB;
- a `context` or `neighbours` query over 100 ms;
- a `locate` query over 300 ms.

Measured (2026-11-03), on the main worktree at `a874aa90`:
- snapshot load: 1.0 s (104 MB file);
- memory: 808 MB for a query process without vectors; 1.15 GB at the peak
  while 37,150 vectors load, settling lower (§13.7);
- `context` and `neighbours`: 3–7 ms; `locate` with keywords: 2 ms, with
  vectors 0.13 s.

The memory peak is over the threshold while vectors load. Its cause is eco's
representation of decoded data (§21): the decoded snapshot is about 8 times
its file, and decoding float vectors allocates heavily. It is logged as an
eco optimisation target rather than worked around with another store.

If any is exceeded, the cause is found first:
1. if it is an eco performance problem, it is logged (§21) and fixed in eco if
   possible;
2. otherwise the storage behind `Kg.Query` is replaced, with SQLite through a
   child process as the first candidate.

## 12. Keeping it current (`Kg.Update`)

### 12.1 The update procedure

`update worktree` runs on every query (through the freshness check) and in the
background:

```
head  <- git rev-parse HEAD
snap  <- load snapshot (or empty)
if snap.lastIndexed == head:
    committed graph is current
else if snap.lastIndexed is empty:
    replay full first-parent history to head; link head's tree
else if git merge-base --is-ancestor snap.lastIndexed head:
    replay snap.lastIndexed..head
else:
    base <- git merge-base snap.lastIndexed head
    truncate history to base (drop commits after it, recompute coChange from the kept commits)
    replay base..head
save snapshot (atomic)
then apply the overlay (12.3)
```

- **Rewriting and branch switches are the same case.** A rebase, an amend, a
  reset and a checkout of another branch all fail the ancestry check, and are
  all handled by truncating to the merge base and replaying from there.
- **Linking is whole-tree, from cached facts.** It is not made incremental.
  The target is under 5 s per update at definition level; this is checked in
  phase 4.

### 12.2 The freshness check

The check runs before every query:
1. **`git rev-parse HEAD`:** about 5 ms.
2. **`git --no-optional-locks status --porcelain=v1 -z --untracked-files=all -- <paths>`:**
   tens of ms. Measure in phase 3; if it is slow, cache it, and invalidate the
   cache from the watcher (§12.4).
3. **Compare both with the snapshot header.** Equal: answer at once.
   Otherwise: update, then answer.

### 12.3 The overlay of uncommitted files

- **Fingerprint.** The dirty set's fingerprint is a SHA-256 over the sorted
  `(path, status, blob id from git hash-object)` entries.
- **Building it,** when the fingerprint changed:
  1. extract facts for the dirty blobs, through the fact cache;
  2. make a file map from `HEAD`'s map with the dirty files applied (deleted
     ones removed);
  3. re-link;
  4. re-chunk the dirty prose and doc comments;
  5. embed the new chunks (§13.4).
- **Storage.** The result is held in memory and in `overlay.kg`. History is not
  changed: uncommitted edits are not commits.
- **Labelling.** Every answer computed from an overlaid graph starts with
  `(includes N uncommitted files)`.

### 12.4 Watching

- **What is watched.** The server watches:
  - each source root that exists in its worktree (`compiler/src`,
    `compiler/src-xhr`, `compiler/src-version`, `runtime/src`,
    `runtime/include`, `elm-kernel-cpp/src`, `eco-kernel-cpp/src`,
    `system-kernel-cpp/src`, `plans`, `design_docs`);
  - the worktree's git directory, non-recursively, for `HEAD` and `index`.
- **What is never watched.** The worktree root, which would recurse into
  `worktrees/`, `build/` and `.git`.
- **What an event does.** Events start a 500 ms debounce timer. When it fires,
  the server runs the freshness check and the update in the background, so the
  next query finds a current snapshot.
- **Correctness.** Watching only affects speed: a missed event is caught by the
  next query's freshness check.

## 13. Search

### 13.1 Chunks (`Kg.Search.Chunks`)

| source | one chunk per | text |
|---|---|---|
| Elm definition with a doc | definition | `<kind> <module>.<name> : <signature>\n<doc>` |
| Elm module | module | `module <name>\n<module doc>` |
| C++ component | component, plus one per comment block over 200 characters | `component <label> (<paths>)\n<comment>` |
| plan | section | `plan <title> [<status>] > <section path>\n<text>` |
| design doc / THEORY.md | section | `doc <title> > <section path>\n<text>` |
| invariant | invariant | `invariant <id> [<category>, <status>]\n<description>` |
| config flag | flag | `flag <path> = <default>\n<doc>` |

- **Splitting:** a chunk over 2,000 characters (about 512 tokens) is split at
  paragraph boundaries into pieces of at most 2,000 characters. Each piece
  repeats the first line (the header).
- **Chunk records:**

  ```elm
  type alias Chunk = { id : Int, node : String, kind : ChunkKind, status : Maybe String, stage : Maybe String, textHash : String, text : String }
  ```

- **`textHash`** is the SHA-256 of the text, in hex.
- **Stable ids:** chunk ids are assigned by sorting chunks on `(node, text
  hash)`.

### 13.2 Keyword search (`Kg.Search.Tokens`, `Kg.Search.Bm25`)

- **Tokenizing:**
  1. lowercase;
  2. split on non-alphanumerics;
  3. also split identifiers at camelCase and digit boundaries, keeping the
     whole identifier as a token too;
  4. drop tokens under 2 characters;
  5. drop a 30-word English stop list.

  Example: `aggPromote` → `aggpromote`, `agg`, `promote`.
- **Index:** `Dict token (List ( chunkId, termFrequency ))`, the chunk lengths,
  and the average length.
- **Score:** BM25 with `k1 = 1.2` and `b = 0.75`:

  ```
  idf(t) = ln(1 + (N - n_t + 0.5) / (n_t + 0.5))
  score(c) = Σ_t idf(t) · tf(t,c)·(k1+1) / (tf(t,c) + k1·(1 - b + b·len(c)/avgLen))
  ```

- **Results:** the top 50.

### 13.3 The embedding server

- **Ollama**, at `$ECO_KG_OLLAMA` (default `http://127.0.0.1:11434`).
  - Installed on 2026-11-03 with the official installer
    (`curl -fsSL https://ollama.com/install.sh | sh`, as root), which runs it
    as a systemd service. Version 0.40.14.
  - It uses CUDA automatically when present; it found the RTX A1000 with only
    the NVIDIA driver installed (Ollama ships its own CUDA runtime). A GPU is
    never required, and for the two small models the CPU is faster (§13.7).
- **Models,** compared in phase 5:

  | model | params | dims | notes |
  |---|---|---|---|
  | `snowflake-arctic-embed:s` | 33M | 384 | default candidate |
  | `all-minilm:l6` | 22M | 384 | fastest |
  | `nomic-embed-text` (v1.5) | 137M | 768, cut to 384 with `dimensions` | needs prefixes `search_query: ` / `search_document: ` |

- **Request:**
  `POST /api/embed {"model": m, "input": [texts…], "truncate": true, "dimensions": 384?}`.
- **Response:** `{"embeddings": [[float…]…], "total_duration", "prompt_eval_count", …}`.
  - Vectors come back L2-normalised. Normalise again anyway; it is cheap and
    guards against other servers.
- **Batching:**
  - documents in batches of 32;
  - each request has a 120 s timeout;
  - queries have a 5 s timeout.

### 13.4 Embedding (`Kg.Embed`)

- **Cache key:** `(model slug, textHash)`, where the model slug includes the
  `dimensions` setting. The prefix is part of the text sent, not the key.
- **The first build runs in the background, in priority order:**
  1. Elm and C++ doc chunks, design docs, `THEORY.md`, invariants, flags;
  2. plans with status `partial` or `not-started`;
  3. all other plans.

  The server answers queries meanwhile. Chunks without a vector are
  keyword-only.
- **Throughput** comes free with each batch: `prompt_eval_count / total_duration`.
  It is logged to stderr and used in §13.7.

### 13.5 Vector storage and scan (`Kg.Search.Vectors`)

- **Layout:** one `Bytes` block of `n × d` float32 values, in chunk-id order,
  plus a `present` bit per chunk. That's about 69 MB for 45k × 384.
- **Scanning a query vector `q`** (an `Array Float` of length `d`): for each
  chunk that passes the metadata filter, compute `Σ q[i]·v[i]`. Keep the top 50
  in a bounded min-heap.
- **Two implementations are written and measured in phase 5, and the faster
  kept:**
  - **A**, decoding `float32` from the block in a `Bytes.Decode.loop`;
  - **B**, decoding the block once at load into one flat `Array Float`, then
    indexing it.

  If both take over 100 ms per query on 45k × 384, log it as an eco
  optimisation target (§21).

### 13.6 `locate` ranking

1. **Run BM25** on the query (top 50).
2. **Run the vector search,** if the server is up: embed the query with the
   query prefix and 5 s timeout, then scan (top 50).
3. **Fuse the two lists** with reciprocal rank fusion:
   `score(c) = Σ_lists 1 / (60 + rank(c))`.
4. **Lift to nodes.** A node's score is the maximum over its chunks, and it
   remembers its best chunk.
5. **Expand** to neighbours with `0.3 ×` the node's score:
   - for a plan, design doc or invariant: the nodes it `mentions`;
   - for a module: its `gates` flags;
   - for a flag: its gated definitions.

   A neighbour keeps the higher of its own score and the expanded one.
6. **Filter:** by default, drop plans with status `superseded` or `abandoned`
   (`includeSuperseded` overrides this). Then apply the `kinds` and `stage`
   filters.
7. **Return the top `limit` nodes** (default 10), grouped by stage (§14.4).

### 13.7 Costs

**Measured (2026-11-03)** on the i7-14700K with the RTX A1000, Ollama
0.40.14, on the main worktree at `a874aa90`: 42,916 chunks, of which 37,160
have text worth embedding.

| model | GPU (Ollama's default) | CPU only (`num_gpu = 0`) | full build, all 37,160 chunks |
|---|---|---|---|
| `snowflake-arctic-embed:s` | 5,238 tokens/s, 57 chunks/s | 6,236 tokens/s, 65 chunks/s | 16 min (GPU) |
| `all-minilm` | 6,084 tokens/s, 69 chunks/s | 11,657 tokens/s, 128 chunks/s | 11 min (GPU) |
| `nomic-embed-text`, 384 dimensions | 2,981 tokens/s, 31 chunks/s | 1,948 tokens/s, 19 chunks/s | 32 min (GPU) |

Throughput is from `kg bench-embed` on 512 (GPU) or 256 (CPU) uncached
chunks; full builds are `kg embed` runs, with an evaluation sharing the
server at the same time. For the two small models the CPU is faster than
this GPU: Ollama sends each input of a batch through the GPU on its own, at
about 20 ms each, whatever its length.

- **Per query:** the query is embedded in 43–56 ms, the 37k vectors are
  scanned in 81 ms (scan C, §13.5), and fusion takes 2 ms: about 0.13 s.
  Loading the vector block when a session opens takes 3 s, in the
  background.
- **Per commit:** a commit changes a few chunks; they are embedded in the
  background in well under a second.
- **Memory:** 37k × 384 packed int8 vectors are about 60 MB live, but
  decoding them from float32 makes the process peak at 1.15 GB (§11.5).

The estimates the plan started with follow; they were close for the small
models on CPU (10–40 min estimated, 5–10 min measured), and wrong about the
GPU, which was expected to take a few minutes.

These are estimates, replaced by measurements in phase 5.
- **The text to embed** (measured): plans 17.8 MB, design docs and `THEORY.md`
  5.2 MB, Elm docs 2.3 MB, C++ comments 2.2 MB. That's about 27.5 MB, about
  7–8M tokens and 40k–45k chunks.
- **Per query:** under 0.3 s in total; the embedding and the scan each take
  tens of ms.
- **Per typical commit:** seconds.
- **First full build on CPU (i7-14700K):**
  - 33M-parameter models: about 10–40 min;
  - nomic: about 1–3 h;
  - an RTX A1000 GPU would take a few minutes.

  The background priority order (§13.4) makes the important chunks available
  first.

## 14. The MCP server (`Mcp.Protocol`, `Mcp.Server`, `Kg.Tools`)

### 14.1 Protocol

- **Transport:** newline-delimited JSON-RPC 2.0 over stdio.
  - Encode with `Json.Encode.encode 0`, which escapes newlines inside strings.
  - Nothing but MCP messages goes to stdout. Logs go to stderr with
    `Stream.logLine`.
- **The loop:**
  1. `init` reads the first line (`Task.attempt GotLine (Stream.readLine env.stdin)`).
  2. Each `GotLine` is decoded and handled.
  3. Its response, if any, is written.
  4. The next read is issued.

  `Err Stream.Closed` means stdin closed: exit with code 0.
- **Messages handled:**

  | message | response |
  |---|---|
  | `initialize` | `{"protocolVersion":"2025-11-25","capabilities":{"tools":{"listChanged":false}},"serverInfo":{"name":"eco-kg","version":"0.1.0"},"instructions":<§14.3>}`. Always answer with `2025-11-25`, whatever version the client asked for; the client decides whether to continue. |
  | `notifications/initialized`, `notifications/cancelled`, any other notification (no `id`) | none |
  | `ping` | `{}` |
  | `tools/list` | `{"tools":[…§14.2…]}` |
  | `tools/call` | §14.4 |
  | `server/discover` and any other request | error `{"code":-32601,"message":"Method not found"}`, at once. Never answer -32022: that marks the server as a 2026-07-28 server. |
  | a line that is not JSON | error `-32700` with `id: null` |
  | an unknown tool | error `-32602` |
  | bad arguments to a known tool | a result with `isError: true` and a text saying what is wrong, so the model can correct itself |

- **Message length:** requests are short and responses are bounded (§14.4), so
  no special handling is needed.

### 14.2 Tools

Each tool has `name`, `description` (one or two sentences, saying when to use
it) and `inputSchema` (JSON Schema, `"type":"object"`,
`"additionalProperties":false`).

| tool | arguments | returns |
|---|---|---|
| `overview` | none | the full orientation summary (§14.3, full form) |
| `locate` | `query: string` (required); `kinds: array of "code"\|"plan"\|"doc"\|"invariant"\|"flag"`; `stage: string`; `limit: integer 1–30` (default 10); `includeSuperseded: boolean` | ranked nodes grouped by stage, each with its best matching chunk's first 200 characters |
| `context` | `node: string` (required) | everything about one node (§14.4) |
| `neighbours` | `node: string` (required); `direction: "out"\|"in"\|"both"` (default `"both"`); `depth: integer 1–3` (default 1); `kinds: array of edge kinds`; `limit: integer 1–200` (default 50) | edges grouped by kind and direction |
| `path` | `from: string`, `to: string` (required); `via: array of edge kinds` (default the dependency kinds: `imports`, `includes`, `uses_symbol`, `kernel`, `calls`, `uses_type`) | up to 3 shortest paths, length at most 8, by breadth-first search |
| `history` | `node: string` (required); `limit: integer 1–50` (default 15) | first and last appearance, renames, edit count, the most recent and the busiest commits, the nodes it changes with most |
| `layering` | `stage: string` | dependency edges between stages, grouped as `foundation → stage`, `earlier → later stage`, `later → earlier stage`, `stage → driver`, with counts and the first 20 of each. It reports and does not judge: which groups are violations is a policy for later. |

**Resolving `node` arguments**, in order:
1. exact id;
2. exact label;
3. a module name or label ending with the argument after a `.`, if unique;
4. a file path (to its node);
5. otherwise a non-error result listing up to 10 candidates by BM25 on labels.

### 14.3 Instructions

- **The instructions are at most 4,000 characters,** because Claude Code cuts
  server instructions at 4,096. `kg check` fails if the generated text is
  longer. Content:
  1. One sentence: "eco-kg answers questions about the eco compiler's
     structure, history and documentation."
  2. When to use it, by kind of question, as rewritten after evaluation 1
     (Claude had answered questions that name a module with Grep and Read):
     a question that names a module, definition, file, plan or flag: call
     `context` first, which gives in one call its stage, files, signature,
     doc, dependencies and users, gating flags, plans, invariants, co-change
     and history; a question in words rather than names: `locate`, which
     searches code docs, plans, design docs, invariants and flags at once;
     `path`, `neighbours`, `history` and `layering` for the rest; then read
     the code at the path:line given.
  3. The stages in pipeline order, one line each: key, title, entry module.
  4. "Call `overview` for the full map."
- **The full form,** returned by `overview` and written to
  `kg/out/compiler-map.md`, adds:
  - each stage's one-line job;
  - what it consumes and produces (from §9.4, once present);
  - the foundations and their sections;
  - the config flags that gate whole passes;
  - open (`partial`, `not-started`) plans grouped by stage, by the stage of
    the nodes they mention most.

### 14.4 Output format and budgets

- **The shape of every tool result:** `{"content":[{"type":"text","text":…}]}`.
- **The text is Markdown:**
  - the first line is the freshness header,
    `graph at <commit 10> · <date>[ · includes N uncommitted files][ · stale: update failed: …]`;
  - code locations are written `path:line`, relative to the worktree root;
  - lists are compact, one line per item.
- **`context` sections, in order:**
  1. kind, stage and paths;
  2. signature;
  3. doc (first 1,500 characters);
  4. depends on, by edge kind, labels only, up to 30;
  5. used by, likewise;
  6. gated by;
  7. plans, with their status;
  8. invariants;
  9. changes with (the top 5 co-change partners);
  10. history in one line.
- **Budget:**
  - each result is cut to 8,000 characters (about 2,000 tokens), which stays
    well under Claude Code's 10,000-token warning;
  - cut items are replaced by `… N more (raise limit)`;
  - the hard maximum is 20,000 characters, even with a raised `limit`.

## 15. Registration and configuration

- **Register once per eco-compiler worktree,** run from inside that worktree:

  ```sh
  claude mcp add --transport stdio --scope local eco-kg -- ~/sc/gitlab/www-eco-lang/kg/bin/kg serve
  ```

  Local scope stores the entry in `~/.claude.json`. Checked in phase 0:
  Claude Code keys it by the main repository's path
  (`/home/rupert/sc/gitlab/eco-compiler`), even when it is run from a linked
  worktree, so one registration serves every worktree of the repository.
  Nothing is written to eco-compiler, and the server does not load in other
  projects. Registered on 2026-11-03.
- **Which worktree:**
  - the server takes `CLAUDE_PROJECT_DIR` from its environment (Claude Code
    sets it to the project root);
  - otherwise it takes `--worktree <path>`;
  - otherwise it takes the process's working directory.

  That directory must be inside an eco-compiler worktree: `git rev-parse
  --show-toplevel` must succeed, and the stage rules must find
  `compiler/src`. Otherwise the server answers `initialize` with short
  instructions saying it is inactive, and every tool call returns
  `isError: true`.
- **Environment variables:**
  - `ECO_KG_OLLAMA`: the server URL;
  - `ECO_KG_MODEL`: default `nomic-embed-text`;
  - `ECO_KG_DIMENSIONS`: default 384 for the default model, unset otherwise;
  - `ECO_KG_CACHE`: default `~/.cache/eco-kg`;
  - `ELM_HOME`: for package kernels.

## 16. Command line (`Main`, `Kg.Cli`)

`kg <command> [--worktree <path>] [options]`. Exit code 0 on success, 1 on
failure, 2 on bad usage.

| command | does |
|---|---|
| `serve` | the MCP server (§14) |
| `build` | full replay and link, writing the snapshot; prints counts and timings to stderr |
| `update` | the incremental update (§12.1) and overlay |
| `query <tool> <json args>` | runs one tool and prints its text, for testing tools without Claude |
| `summary` | writes `kg/out/compiler-map.md` and prints the instructions' length |
| `check [--determinism N] [--atlas-parity <python history.json>]` | §19.2 |
| `export --atlas <file>` | writes the website's `history.json` (§17) |
| `export --neo4j <dir>` | writes `nodes.csv` and `edges.csv` for `neo4j-admin database import` (phase 7) |
| `embed [--max-minutes M]` | runs the background embedding in the foreground, for the first build |
| `eval <questions.json> --arms with,without [--runs R]` | §18 |

## 17. The atlas

- **`Kg.Layout`** ports the Python's `Layout` class (`step`, `insert_flow`,
  `geometry`, `positions`) and the constants above it (`HEAD_ROWS`, `MAXROWS`,
  `NODE_W`, …).
- **`Kg.Atlas`** builds the `history.json` structure, writing exactly the same
  fields as the Python `main`:
  - `stages`, `branch`, `sections`, `nodeW`, `nodeH`;
  - `frames`, `nodes` (with `life`, `pos`, `info`, `edits`);
  - `edges`, `stageTracks`, `world`.
- **Parity.** The Python output is not deterministic: `stageTracks` keys come
  out in set order, and `json.dump` escapes non-ASCII.
  1. Patch `script/atlas-graph.py` first, building `stageTracks` with
     `dict(sorted(...))` and dumping with `ensure_ascii=False`.
  2. Regenerate `content/atlas/history.json`.
  3. Parity is then checked by `kg check --atlas-parity`, which decodes both
     files and compares the values, so key order and whitespace don't matter.
  4. When parity holds, the website's build uses `kg export --atlas`, and
     `script/atlas-graph.py` is deleted.
- **Done (2026-11-03).** Parity holds on the patched Python, after three of
  its bugs were fixed (phase 1 result). `npm run atlas` builds kg and exports
  `content/atlas/history.json`; `npm run kg` only builds it.
- **Sharing types with the website.** The website cannot import eco/system
  modules. It can share `Kg.Atlas`'s pure types, if a later change wants the
  decoder and encoder in one place; that is optional.

## 18. Evaluation (`Kg.Eval`)

### 18.1 The question set

`kg/eval/questions.json` holds 16 questions. Each has:
- `id`;
- `question`;
- `reference`: a short reference answer;
- `mustMention`: files or modules the answer must name;
- `category`: orientation, data flow, vocabulary, history or plans.

Questions:
- the four in §2;
- "what consumes `Borrow.Facts`";
- "which passes rewrite the Mono graph after borrow inference runs";
- "what replaced `-enable-unboxed-agg`";
- "which invariants govern the closure ABI";
- "which plans are open on the C++ foundation";
- "what changes with `GlobalOpt/Staging.elm` most often";
- "where are kernel function types derived";
- "what does `Prune.pruneAfterInline` remove and when does it run";
- "which config flags gate MLIR generation rewrites";
- "where is the flags decoder built";
- "what is the lambda-set member id";
- "which C++ passes run before EcoToLLVM".

### 18.2 Running

**One run of one question in one arm:**

```sh
claude -p "<question>" --output-format stream-json --verbose \
  --strict-mcp-config --mcp-config <arm>.json \
  --permission-mode dontAsk --allowedTools "Read,Grep,Glob,Bash(git log:*),mcp__eco-kg__*" \
  --max-turns 40
```

- **Where it runs:** in a clean eco-compiler worktree at a fixed commit,
  recorded with the results.
- **The arms:**
  - `with.json` is `{"mcpServers":{"eco-kg":{"command":"<kg>","args":["serve"]}}}`;
  - `without.json` is `{"mcpServers":{}}`.

  `--strict-mcp-config` keeps the user's other MCP servers out of both arms.
- **Check the arm:** the harness reads the first `system/init` event and checks
  that `mcp_servers` lists `eco-kg` as connected (with-arm) or is empty
  (without-arm). If not, the run is discarded.
- **Tool calls:** counted from `assistant` events' `tool_use` blocks.
- **From the final `result` event:**
  - `num_turns`, `duration_ms`, `total_cost_usd`;
  - `usage` and `modelUsage` tokens;
  - the answer, `result`.
- **Unverified:** whether `mcp__eco-kg__*` works as a wildcard in
  `--allowedTools`. Phase 0 checks it; if not, list the tools by name.

### 18.3 Grading and recording

- **`mustMention` hits** are computed automatically.
- **Correctness** is graded 0, 1 or 2 against the reference, by hand, or by a
  separate `claude -p` grading prompt whose grades are spot-checked by hand.
- **Results** are written to `kg/eval/results/<date>-<phase>.json` with the
  commit, the model and every number.
- **The summary** is a table of medians per category and arm.
- **Each phase reports its delta against the phase 0 baseline in this plan.**


### 18.4 Results (2026-11-03)

Every run: 16 questions, one run each, Claude Code's default model, graded
by Sonnet against the references and spot-checked by hand. Files are in
`kg/eval/results/`; `python3 -I kg/scripts/eval-summary.py <files>` prints
the tables.

| run | eco-kg | median tool calls | mean grade (0–2) | cost |
|---|---|---|---|---|
| `phase0-baseline` | none | 7 | 1.31 | $4.88 |
| `phase2-4-keyword` | keyword search, instructions v2 | 8 | 1.44 | $3.84 |
| `phase5-arctic` | + vectors (arctic), concepts | 7 | 1.50 | $2.61 |
| `phase6-arctic` | + concepts ranked first when the query names one | 6 | 1.31 | $2.54 |
| `phase6-minilm` | the same, all-minilm vectors | 6 | 1.50 | $2.60 |
| `final-arctic` | + plans by stage, normalised concept matching, instructions v3 (in a second clone, see below) | 6.5 | 1.38 | $4.21 |
| `phase6-nomic` | as `final-arctic`, nomic vectors | 5 | 1.62 | $3.58 |

| `final-v4` | as `phase6-nomic`, instructions v4: eco-kg's path:line locations are exact, so open them with Read rather than searching again | 6 | 1.62 | $3.47 |

The v4 sentence did not lower the tool calls on the orientation (6, as the
baseline) and data-flow (8, against 7) questions.

By category, baseline against the best runs:

| category | baseline calls / grade | with eco-kg calls / grade |
|---|---|---|
| orientation (6) | 6 / 1.17 | 5.5–6 / 1.50–1.83 |
| data flow (4) | 7 / 1.50 | 7 / 1.50–2.00 |
| history (2) | 4 / 1.00 | 3.5–4.5 / 1.00–1.50 |
| plans (2) | 9.5 / 1.50 | 5–7.5 / 0.50–1.50 |
| vocabulary (2) | 8.5 / 1.50 | 5–7.5 / 0.50–1.50 |

What the runs show:
- **Cost fell by about half** in every run in the first clone ($4.88 → $2.5),
  because Claude reads far fewer files: the answers it needs are in one tool
  result. The final run's higher cost came from running in a second clone,
  whose different path missed the prompt cache the other runs shared; its
  tool calls and grades are comparable, its cost is not.
- **Tool calls fell a little** (7 → 6). Claude still confirms in the code with
  Grep and Read, as the instructions ask; eco-kg replaces the searching, not
  the confirming.
- **Grades rose a little** (1.31 → 1.38–1.50). With one run per question and
  grades in whole points, a difference of one question moves the mean by
  0.06–0.12, so the differences between runs with eco-kg are within noise.
- **Specific failures were found and fixed:** a stale design doc taken over
  the code (lambda-set member id, 0 → 2, after the concept was matched and the
  instructions said the code wins); plans by stage, which no tool gave
  (0 → 1); co-change without paths or deletions (0 → 1).
- **The models** differ less than the runs do. all-minilm, the smallest and
  fastest, did as well as arctic on the same binary.

## 19. Testing

### 19.1 Unit and fixture tests

`kg/tests/Run.elm` is an eco program, `System.simpleProgram`, that runs a list
of tests and prints `PASS`/`FAIL` lines. It exits 1 on any failure.

- **Each extractor:** small inputs, with expected facts.
  - The C++ scanner tests copy the Python's tricky cases: `extern "C"` after
    literal stripping, `NurserySpace::MinorEnv`, macro bodies with braces,
    `/alternatename`.
- **`Kg.Link`:** fixture trees under `tests/Fixtures/` with expected edges.
- **Codecs:** `decode (encode x) == x` for every stored type.
- **BM25 and the tokenizer:** fixed small corpora with expected rankings.
- **The vector scan:** top-k against a brute-force reference.
- **RRF:** a hand-computed example.
- **MCP:** protocol fixtures, request lines with expected response lines,
  including `initialize`, `server/discover`, `ping`, an unknown tool, bad
  arguments and non-JSON.
- **Rendering:** budgets are respected; the instructions stay at most 4,000
  characters.

**Built (2026-11-03):** `kg/tests/Run.elm`, 63 tests, all passing, run with
`cd kg/tests && eco make Run.elm --output=../bin/kg-test && ../bin/kg-test`.
They cover the eco checks of phase 0, the C++ scanner's tricky cases, the Elm
and prose extractors, the `tiny` fixture tree's module edges, codec round
trips, the tokenizer, BM25, RRF, chunk splitting, the concept boost of
`locate`, the MCP protocol fixtures, argument errors, output budgets, the
instructions' length, `paths` and `neighbours`, history truncation and
co-change, `cat-file` against a repository made with `git init`, and the
vector scans against brute force. The C++ facts were also compared with the
Python's on all 398 current C++ files: equal.

### 19.2 `kg check`

- **Determinism (`--determinism N`):**
  1. build a snapshot at `HEAD~N`;
  2. update it commit by commit to `HEAD`;
  3. compare it with a full build at `HEAD`, excluding the vector block and
     timings;
  4. they must be equal.

  N defaults to 50; the phase 3 exit uses 200. This is two builds, not N.
- **Atlas parity (`--atlas-parity`):** §17.
- **References:**
  - unresolved mentions in `partial` and `not-started` plans;
  - invariant `source`s that resolve to nothing;
  - `concepts.json` links to missing nodes;
  - stage `entry` modules that don't exist.

  These are listed, and fail only for stage entries and concepts.
- **Instructions:** at most 4,000 characters.

## 20. Phases

Each phase lists tasks in order and the checks that close it. Record measured
numbers in this plan as each phase closes.

### Phase 0: foundations and baseline

1. Create `kg/` (§6.1), `vendor/COMMIT`, `scripts/vendor-compiler.sh`, and
   `elm.json` (§6.3). Build a `Main` that prints its arguments.
   - Check: `eco make` succeeds.
2. **Parser smoke test:** `kg parse <file.elm>` prints the module name, the
   import count and the doc count.
   - Check: it parses every file under `compiler/src` without error. Count
     and list any failures.
3. **Lookbehind:** a test that `Regex.fromString "(?<!:):(?!:)"` compiles and
   splits `a:b::c` correctly under eco.
4. **`billstclair/elm-sha256`:** test vectors pass under eco, and hashing
   1 MB takes under 1 s. If not, log it (§21) and use `git hash-object
   --stdin` for chunk hashes.
5. **`Mcp.Protocol` and `Mcp.Server`** with one tool, `ping_kg`, returning
   `"ok"`. Register it (§15) in one eco-compiler worktree.
   - Check: in Claude Code, `/mcp` shows `eco-kg` connected and the tool can
     be called.
   - Check: `server/discover` gets -32601 (protocol fixture test).
6. **The `--allowedTools "mcp__eco-kg__*"` wildcard** (§18.2).
7. **Write `kg/eval/questions.json`** with references (§18.1). Build
   `kg eval` far enough to run the without-arm.
   - Check: baseline results recorded under §18 here.


**Result (2026-11-03): done.**
- `kg/` builds with `eco make` (`npm run kg`). It first vendored the parser from eco-compiler; since 2026-11-03 it has its own copy (§6.2).
- The parser parses all 291 files of `compiler/src` and the 30 of
  `src-xhr`, `src-version` and `eco-kernel-cpp/src`, about 5 ms each; over the
  history, 9,304 distinct Elm blobs parse.
- Lookbehind works under eco's SRELL kernel. `Regex.find` and
  `Json.Decode.Error` do not (§21), and `billstclair/elm-sha256` gives wrong
  hashes under eco's 64-bit `Bitwise`; `Kg.Sha256` replaces it (8 MB in under
  1 s).
- The MCP server connects in Claude Code and its tool is called (`ping_kg`,
  later the seven tools).
- `--allowedTools "mcp__eco-kg__*"` works as a wildcard.
- The baseline is in §18.4.

### Phase 1: module graph and atlas parity

1. `Kg.Git`: the commands in §7, with a `cat-file --batch` test against a
   fixture repository made with `git init` in the test's temp directory.
2. `Kg.Codec`, `Kg.Fs` (atomic writes, locks, cache paths), `Kg.Facts`
   (`FileFacts` codec, extractor version).
3. `Kg.Extract.Cpp` (§8.2), `Kg.Extract.Build` (§8.3), and `Kg.Extract.Elm`
   with imports only (§8.1).
4. `Kg.Stages` (§9.2), and `Kg.Link` at module level (§9.3), including package
   kernels from `ELM_HOME`.
5. `Kg.History` replay (§10.1) and the snapshot (§11.3).
6. `Kg.Layout` and `Kg.Atlas` (§17).
7. Patch `script/atlas-graph.py` for determinism and regenerate
   `content/atlas/history.json` (§17).
8. **Checks:**
   - `kg build` completes;
   - `kg check --atlas-parity content/atlas/history.json` passes;
   - the final graph has 468 nodes and 3,092 edges at the commit the current
     `history.json` was made from;
   - full build time is recorded.
9. Switch the website to `kg export --atlas` and delete the Python script.


**Result (2026-11-03): done.**
- `kg check --atlas-parity content/atlas/history.json` passes: the decoded
  JSON is equal, 373 frames, 522 nodes ever, 468 now, 3,093 edges now.
- Parity found three bugs in the Python, fixed there before the comparison
  (§17): CMake sources reached through `${VAR}` were joined to their directory
  twice, losing `EcoBootConfig → Core` (hence 3,093 edges, not 3,092); an
  `import` line inside the `eco init` template string was read as an import
  (two spurious frames: 373, not 375); and Elm paths came out in
  history-dependent order.
- A first build extracts the facts of 12,661 blobs and replays 1,539 commits
  in about 8 minutes. With the facts cached, the replay with the atlas layout
  takes 36 s (the Python took 85 s), and `kg build` 40 s.
- The website now builds the atlas with `npm run atlas` (`kg export --atlas`),
  and `script/atlas-graph.py` is deleted.

### Phase 2: tools and orientation

1. `Kg.Query`: node resolution (§14.2), neighbours, paths (breadth-first
   search), history summaries, layering groups.
2. `Kg.Search.Tokens` and `Kg.Search.Bm25` over chunks of module docs and
   prose (§13.1–§13.2). `Kg.Extract.Prose` is needed here for plans and docs
   (§8.4).
3. `Kg.Render` with budgets (§14.4); the tools `overview`, `locate`
   (keyword only), `context`, `neighbours`, `path`, `history`, `layering`.
4. Instructions and summary (§14.3); verify the stage entries (§9.2).
5. **Checks:**
   - `kg query` gives sensible output for each tool on 5 hand-picked nodes;
   - §11.5 load and query timings measured;
   - evaluation 1 run, with the with-arm showing fewer tool calls than the
     baseline on the orientation and data-flow questions.


**Result (2026-11-03): built; the tool-call check is not met.** Measured
over six runs with eco-kg (§18.4), the median calls on orientation questions
were 5.5–7.5 against the baseline's 6, and on data-flow questions 7–9
against 7. Three rewrites of the instructions did not change that: Claude
uses eco-kg in place of searching, then confirms in the code with Read and
Grep as before. What eco-kg changed instead is cost (about a half to two
thirds of the baseline's) and grades (1.31 → 1.44–1.62).
- The tools give sensible output on the nodes tried (EntryPrep, Prune,
  `GlobalOpt/Staging.elm`, `flag:borrow.enabled`, `cpp:pass:EcoGCPrepare`,
  layering of `mono`). `layering` shows the one edge against the pipeline:
  `MonoSolver.Translate` (mono) imports `GlobalOpt.KernelFacts` (global).
- §11.5: the snapshot loads in 1.0 s; a query process peaks at 808 MB without
  vectors; `context` and `neighbours` take 3–7 ms; keyword `locate` 2 ms.
- Evaluation 1 (keyword search only, §18.4): with eco-kg the mean grade rose
  from 1.31 to 1.44 and the cost fell 21 %, but the median number of tool
  calls did not fall (8 against 7; orientation 7.5 against 6, data flow 9
  against 7). Claude often answered questions that name a module with Grep
  and Read, as before. The instructions were rewritten to say when each tool
  is quicker (§14.3), which is in the run measured.

### Phase 3: incremental updates

1. `Kg.Update` (§12.1), including truncating to the merge base.
2. The freshness check (§12.2), the overlay (§12.3), watching (§12.4), locks
   (§11.4).
3. `kg check --determinism` (§19.2).
4. **Checks:**
   - an update after a typical commit takes under 5 s;
   - a query after editing a file shows the overlay header and the edit's
     effect;
   - `--determinism 200` passes;
   - two concurrent `kg update`s leave one valid snapshot.


**Result (2026-11-03): done.**
- An update after one commit takes 2.8 s: the replay of the commit, then the
  whole graph linked again from cached facts (facts loaded 0.4 s, assembled
  1.5 s, chunks 0.2 s, keyword index 0.3 s). The keyword index is rebuilt
  from the previous one, remapping its postings and tokenizing only new
  chunks; a fresh build of it takes 4.7 s.
- `kg check --determinism 1` and `--determinism 200` pass: the snapshot built
  at `HEAD~200` and updated to `HEAD` equals a full build, byte for byte
  (graph, history, chunks, keyword index, base).
- A file added in a worktree shows in the next query with the header
  `includes 1 uncommitted file`, with its edges; deleted, it goes. Watching
  makes the change visible without a call (tested in a clone with a probe
  module).
- Two concurrent `kg update`s: the second waits on the lock, then finds the
  snapshot current; the snapshot is valid.

### Phase 4: definitions and prose links

1. The full `Kg.Extract.Elm` (§8.1), `Kg.Extract.Config` (§8.5), and the
   invariants parser (§8.4).
2. The definition-level, `produces`/`consumes`, `mentions`, `supersedes`,
   `gates` and `in_stage` edges (§9.4).
3. The reference checks in `kg check` (§19.2).
4. **Checks:**
   - precision samples recorded:
     - 30 `gates` (at least 90% right);
     - 30 `mentions` (at least 95%);
     - 20 `calls` (at least 95%);
     - `produces`/`consumes` on every stage entry, by hand;
   - update under 5 s at definition level;
   - evaluation 2 run.


**Result (2026-11-03): done.**
- Precision, sampled by hand with `kg edges <kind> --sample N`:
  - `gates`: 30 of 30 right as reads of the flag. Thirteen of the first
    sample were in `Compiler.Eco.Config` itself (the decoder, `hash`,
    `clamp`), which defines the flags rather than being gated by them; the
    config modules are now excluded, and a second sample of 30 was 30 right.
    215 edges.
  - `mentions`: 29 of 30. The miss was `Set.size` in prose about elm/core
    resolving to the compiler's `Data.Set#size`; one-word qualifiers that
    name elm/core modules are no longer resolved by suffix. 10,986 edges.
  - `calls`: 20 of 20, resolved through import aliases (`BD.string`,
    `UF.get`, `T.toDoc`). 21,498 edges.
  - `produces`/`consumes`: right on every stage entry by its signatures
    (Canonicalize `Source.Module` → `Canonical.Module`, Local optimize →
    `TypedOptimized.LocalGraph`, Monomorphize `TypedOptimized.GlobalGraph` →
    `MonoGraph`, Global optimize `MonoGraph` → `MonoGraph`, Generate MLIR
    `MonoGraph` → `MlirModule`), with some helper types (`Name.Name`) as
    noise.
- Updates stay at 2.8 s with definitions.
- `kg check` lists 398 references for a person to look at: 90 ambiguous
  file names, 248 names of files that do not exist (most proposed by plans
  not yet started), 60 dotted names that resolve to nothing.
- Evaluation 2 is the same run as evaluation 1: phases 2 and 4 were built
  together.

### Phase 5: vectors

1. Install Ollama (§13.3); pull the three models.
2. `Kg.Embed` with batching, timeouts and the background priority order
   (§13.4).
3. `Kg.Search.Vectors`, both implementations (§13.5), and fused `locate`
   (§13.6).
4. **Measure,** recording the measured values over the estimates in §13.7:
   - tokens/s per model on CPU;
   - full-build time per model;
   - query latency;
   - memory.
5. **Checks:**
   - evaluation 3 run, with each model;
   - the vocabulary questions answered without a manual search;
   - `locate` under 0.3 s on CPU;
   - the default model chosen;
   - the decision whether to move into eco-compiler recorded here.


**Result (2026-11-03): done; the default model is `nomic-embed-text` at 384
dimensions.**
- Ollama is installed; all three models are pulled and each has embedded all
  37,160 chunks (16, 11 and 32 minutes on the GPU; §13.7).
- `Kg.Embed` batches 32 texts, with 120 s and 5 s timeouts, in the priority
  order of §13.4, in the background in the server and in the foreground with
  `kg embed`. Throughput is logged.
- Both planned scans were built and measured, and neither was good enough
  under eco: A (decode per query) 1,089 ms, B (flat `Array Float`) 356 ms and
  about 550 MB. A third, C (int8, eight to an `Int`, rows as lists), takes
  81–86 ms and is kept (§13.5, §23). Finding it also found an eco bug: a
  list made by `List.take` made the scan 12 times slower (§21).
- `locate` takes 0.13 s with arctic and 0.16 s with nomic, under the 0.3 s
  target.
- Evaluation 3 ran once per model (§18.4). nomic's run had the best grade
  (1.62), fewest tool calls (5) and both vocabulary questions right; with one
  run per question the margin is within noise, but it costs only 30 ms more
  per query and a one-time 32-minute build, so it is the default.
- The vocabulary questions are answered from `locate` without a manual search
  for the word: in the nomic run, "escape analysis" and "lambda-set member
  id" each took one `locate` and then reads of the code it pointed to.
- **Moving into eco-compiler:** recommended, but not yet. The prototype
  works, halves the cost of answering these questions, and is current per
  worktree, with uncommitted edits. Before it moves, two things from this
  plan's own rules should be settled: the eco bugs it works around (§21)
  should be fixed in eco, so the code moves without workarounds. One run per
  question was judged enough for this prototype (the user, 2026-11-03), so
  differences of a tenth of a grade between runs are within noise. This is
  the user's decision; the recommendation is recorded here.

### Phase 6: curated concepts

1. `kg/knowledge/concepts.json`:

   ```json
   [{"slug": "...", "name": "...", "aliases": ["..."], "summary": "...",
     "links": [{"node": "...", "role": "implements|measures|configures|consumes_facts_of"}]}]
   ```

2. Draft it with Claude from the docs and plans, starting with 10 concepts:
   - borrow inference;
   - escape analysis / promotion;
   - lambda sets;
   - staging;
   - ids (MVar/arrow);
   - bytes fusion;
   - CAFs;
   - reification;
   - kernels;
   - the GC.

   Review it by hand.
3. Concepts become nodes. Their names and aliases are added to BM25 and to
   chunks.
4. **Checks:** `kg check` passes; evaluation 4 run.


**Result (2026-11-03): done.**
- `kg/knowledge/concepts.json` holds the 10 concepts, drafted by Claude from
  the docs, plans and the graph, each with 12 links; all 112 distinct link
  targets were checked to be nodes, and the summaries reviewed by hand.
  "Reification" turned out to mean two things in eco, bytes-fusion
  reification (live) and borrow reification (not built); the concept says
  both.
- Concepts are nodes with chunks and keyword tokens for their names and
  aliases. A query that is or contains a concept's name or alias puts the
  concept first and its links next: "escape analysis" now gives the concept,
  then `Expr#walkPromo`, `Expr#tupleBinderPromotable`, `Expr#promotableCtorCall`,
  `Backend#buildSretPromoted` and `Backend#buildPsplitPromoted`, where before
  it gave borrow-inference design docs.
- `kg check` passes (no failures). The snapshot header records a hash of the
  concepts, so editing them re-links and re-indexes without a replay.
- Evaluation 4: `phase6-*` and `final-arctic` in §18.4.

### Phase 7 (optional): Neo4j export

1. `kg export --neo4j <dir>` writes `nodes.csv`
   (`id:ID,kind:LABEL,label,stage,paths`) and `edges.csv`
   (`:START_ID,:END_ID,:TYPE,weight`).
2. **Check:** `neo4j-admin database import full --nodes=… --relationships=…`
   succeeds.


**Result (2026-11-03): done.** `kg export --neo4j <dir>` wrote 18,658 nodes
and 69,291 edges, and `neo4j-admin database import full` (the `neo4j:5`
Docker image) imported them in 1.2 s: 18,648 nodes, 69,171 relationships and
137,428 properties at the time of the test, before the concepts were added.

## 21. Dogfooding

**What it exercises in eco:**
- a long-running stdio program;
- child processes with live pipes;
- inotify watching;
- large heaps held for a session;
- `elm/bytes` at volume;
- numeric loops over float data;
- `elm/http` to a local server;
- the compiler's own parser used as a library;
- startup and snapshot-load time.

**Rules:**
- An eco bug or missing feature found here goes in the log below, with a
  minimal reproduction, and is fixed in eco-compiler where possible. It is not
  quietly worked around.
- A workaround that is unavoidable for now stays behind one module boundary.
- Where Python would be easier, that is not a reason to use it. Only a real
  gap in eco is, and the gap is then logged.

**Log:**

| date | what | reproduction | status |
|---|---|---|---|
| 2026-11-03 | The `eco/kernel` bundled with eco 0.2.0 lacks `Eco.Console.isTerminal`, which master's `compiler/src/System/IO.elm` uses. Outside builds of the parser must list `compiler/src-xhr`. | build the parser with `compiler/src` only | worked around (§5) |
| 2026-11-03 | `float32` decode loops are expected not to fuse in 0.2.0 | §13.5 measurement | to measure |
| 2026-11-03 | `Regex.find` and `Regex.replace` hand back `Match` records whose fields the compiled code reads from the wrong slots: `index` and `submatches` are right, `number` is a pointer value and reading `match` segfaults. The kernel (`elm-kernel-cpp/src/regex/RegexExports.cpp:108-122`) writes the fields as (index, match, number, submatches); the compiled code appears to expect the unboxed fields first. | `Regex.find (re "a") "abc" \|> List.map .match` | fixed in eco 0.2.0~b7; `Kg.Re` now reads `match` and `number` directly |
| 2026-11-03 | `Match.index` counts code points, while `String.slice` and `String.length` count UTF-16 units, as Elm's do. In Elm the index is in UTF-16 units. | `Regex.find (re "b") "a😀b"` gives index 2; Elm gives 3 | fixed in eco 0.2.0~b7; the conversion in `Kg.Re` is gone |
| 2026-11-03 | `String.toList` and `String.foldl` step through UTF-16 units: `String.toList "a😀b"` has 4 elements, and the emoji is two surrogate `Char`s. Elm gives 3. This contradicts `design_docs/elm-divergence.md` §2 (Char is one code point). | `List.length (String.toList "a😀b")` | fixed in eco 0.2.0~rc2 |
| 2026-11-03 | A `Json.Decode.Error` cannot be used: `Json.Decode.errorToString` segfaults, and so does a `case` on the error's constructors (`Field`, `Failure`, …), for parse errors and type errors alike. Testing `Ok`/`Err` is safe. | `D.decodeString D.int "x" \|> Result.mapError D.errorToString` | fixed in eco 0.2.0~b7; the MCP parse error now carries `errorToString` (`Mcp.Protocol`). `Kg.Args` still checks field by field, for clearer messages |
| 2026-11-03 | A list made by `List.take` is about 4 times slower to walk than one made by `List.map` (12 times inside kg's vector scan: 832 ms against 69 ms). | `dot (List.take 384 (xs ++ [0])) ys` against `dot xs ys`, 100,000 times: 750 ms against 190 ms | improved in eco 0.2.0~b7 to about 2× (118 ms against 62 ms for a 384-element sum, 100,000 times); `Kg.Search.Vectors.padTo` still avoids it; open |
| 2026-11-03 | `Bytes.Decode` loops are slow and allocate heavily: decoding 14.3 M `float32` takes about 1.1 s, and 14.3 M `unsignedInt8` with the `listStep` pattern also about 1.1 s with a 2 GB peak; neither appears to fuse. | §13.5 measurements, `bench-vectors` | measured; vectors are quantized and kept as packed `Int` lists instead |
| 2026-11-03 | Data held in Elm values is large: the 104 MB snapshot takes about 800 MB once decoded, and 14.3 M `Float`s in an `Array` or in lists about 50 bytes each. | `kg query context …` peaks at 808 MB | measured; within §11.5's 1 GB without vectors, at 1.15 GB peak with them (§13.7) |
| 2026-11-03 | `Json.Encode` writes object keys in sorted order, where Elm keeps the order given. Harmless here. | `E.encode 0 (E.object [ ( "b", … ), ( "a", … ) ])` | fixed in eco 0.2.0~b7; the atlas export's key order changed, its data did not |
| 2026-11-03 | The parser rejects the character literal `'😀'` (asks for double quotes). Elm accepts it. | `c = '😀'` | open |
| 2026-11-03 | Any `[glsl| … |]` literal segfaults the parser built with eco (8 files in eco-compiler); most likely in `guida-lang/glsl`'s parser running natively. | a module with a one-line shader | worked around: kg's copy of the parser does not parse GLSL (§6.2) |
| 2026-11-03 | `Bitwise` is 64-bit by design (`elm-divergence.md` §5.5), so `billstclair/elm-sha256` returns wrong hashes. | `Sha256.sha256 ""` | worked around: `Kg.Sha256` masks every step to 32 bits; the package is not used |

## 22. Risks

- **Staleness.** A wrong map is worse than none. The freshness check on every
  query (§12.2) and the determinism check (§19.2) are the defence.
- **Wrong links.** Mentions, gates, calls and symbol uses are inferred. The
  atlas work showed how name-based matching overlinks. Every inferred edge
  kind has a precision sample and a threshold before it is exposed (phase 4).
- **Context flooding.** Output budgets (§14.4), checked in tests.
- **Claude not using the tools.** The instructions say when to use them
  (§14.3), and evaluation shows whether it does.
- **The parser falling behind.** kg has its own copy (§6.2), so a change in
  the compiler cannot break kg's build; the copy is brought up to date by
  hand when Elm syntax kg must read changes.
- **eco gaps slowing the prototype.** That is part of the point, but a gap
  that blocks a phase gets a decision: fix it in eco first, or work around it
  behind a module boundary (§21).
- **Upkeep of curated data:** stage entries and concepts. Both are checked by
  `kg check`.
- **macOS.** `watchRecursive` polls there, with a full snapshot every second.
  The prototype targets Linux; macOS needs watching off or narrowed further.

## 23. Deviations from this plan, and why

Recorded as the work was done (2026-11-03). Each was the simpler or the
correct choice once the code met the facts; none changes what the prototype
is for.

| § | the plan said | what was built | why |
|---|---|---|---|
| 6.2, D4 | a vendored, pinned archive of the compiler's sources | a checked-in copy of the parser in `kg/parser/`, with the IO layer, error messages, JSON codecs and crashes taken out | kg should not build on eco-compiler's sources, need `eco/kernel`, or crash (the user, 2026-11-03) |
| 3 D10, 6.3 | SHA-256 from `billstclair/elm-sha256` | `Kg.Sha256`, a 32-bit-masked SHA-256 in Elm | the package gives wrong hashes under eco's 64-bit `Bitwise` (§21) |
| 6.1 | the module list | as listed, plus `Kg.Re` (the regex workaround), `Kg.Sha256`, `Kg.PathUtil`, `Kg.Context` (worktree, cache, settings), `Kg.Commands`, `Kg.Session` (snapshot + freshness + overlay), `Kg.Serve` (the eco-kg MCP application), `Kg.Overlay`, `Kg.Replay` (the pure replay step), `Kg.Build` (the replay's IO), `Kg.Assemble` (§9.4, the whole graph), `Kg.Check`, `Kg.Args`, `Kg.Json`, `Kg.Debug`, `Kg.Semantic` (vector search state), `Kg.Neo4j`, and `tests/Test/Runner.elm`. There is no `Kg.Id`: ids are made where nodes are | the plan's modules were too coarse in places; nothing else changes |
| 7 | `cat-file --batch` and `hash-object --stdin-paths` through `spawn` | both through `ChildProcess.run`: the blob ids go to a list file that `sh -c 'exec git cat-file --batch < "$1"'` reads, paths passed as arguments, in batches of 400; `hash-object -- <paths>` | `spawn` is a `Cmd`, which would have turned every command into a message-driven state machine; with `run` every command is one `Task` chain |
| 8 | `ConfigModule` as a `FileFacts` variant | `ElmFacts.config`, filled for `Compiler/Eco/Config.elm` | a file has one set of facts; the config module is an Elm file |
| 8.2 | `uses` for every identifier | only names used with at least one qualifier are kept | a name with no uses never makes an edge; it halves the facts |
| 8, 11.1 | facts cached by (blob, extractor version) | by (blob, kind of file, extractor version), with a hash of the path for CMake files, Markdown and `Config.elm` | the same blob can sit at paths needing different extractors (an empty file), and those extractors' output depends on the path |
| 9.1 | commit nodes | not made | `history` reads the history directly; 1,539 commit nodes would only add noise to search |
| 9.4 | `supersedes` from `superseded_by` | `supersedes` points from the newer plan to the one it replaces | so the edge reads as its name says |
| 9.4 | `gates` from any `.field` read | as planned, and never from `Compiler.Eco.Config` or `Builder.Eco.Config` | those define, decode and hash every flag (phase 4 sample) |
| 10.2, 12.1 | truncate the history to the merge base | the history keeps per-commit edits, from which `coChange` is derived; truncation keeps commits up to the last one touching kg's paths at or before the merge base, rebuilds the replay's state there from `git ls-tree`, and replays forward. The atlas layout is not kept in snapshots (`kg export --atlas` replays in full) | the layout cannot be truncated, and the knowledge graph does not need it |
| 11.1 | facts and vectors under `<repo id>/` | under the cache root, shared by every repository | they are content-addressed; a clone (the evaluation's) reuses the original's 12,661 facts instead of spending 8 minutes |
| 11.3 | the vector block in the snapshot | a separate file per worktree and model, `vectors-<model>.kg`; the shared per-hash cache under `vectors/<model>/` is the source of truth | vectors arrive in the background; rewriting a 100 MB snapshot for them would be wasteful |
| 12.3 | the overlay also written to `overlay.kg` | in memory only | building it takes about 2.5 s; a process that needs it builds it |
| 13.1 | chunk ids by (node, text hash) | by (node, text) | the same order, without hashing every chunk first; hashes are computed for embeddable chunks and reused across updates |
| 13.5 | two scans, A and B, keep the faster | a third, C, is kept: int8 per-vector quantization, eight to an `Int`, rows as lists | under eco A took 1.1 s and B 356 ms with 550 MB; C takes 81 ms (§13.7) |
| 14.3 | the instruction text | rewritten after evaluation 1 to say, per kind of question, which tool is quicker than Grep | Claude did not choose the tools for questions that name a module |
| 15 | local scope is keyed by the worktree's path | Claude Code keys it by the main repository's path, so one registration serves every worktree, and `CLAUDE_PROJECT_DIR` (checked: the worktree) tells them apart | observed in phase 0 |
| 16 | the command list | plus `parse` (the phase 0 smoke test), `facts`, `edges <kind> --sample N` (precision samples), `bench-vectors` and `bench-embed` (phase 5 measurements) | measurement and debugging |
| 18.2 | runs in a clean worktree | in a `git clone --shared` under `~/.cache/eco-kg/eval/`, so no parent `CLAUDE.md` applies and nothing is written to eco-compiler | a worktree of eco-compiler would write to its git directory |

