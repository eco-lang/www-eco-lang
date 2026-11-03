# kg's copy of the eco parser

kg reads Elm source with eco's own parser. This directory is a copy of the
parser, checked in here, so that kg builds on its own: it does not read
eco-compiler's sources to build, and it needs nothing from the `eco/kernel`
package.

## Where it came from

The modules the parser needs, from eco-compiler's `compiler/src` at
commit `a874aa905452cfd2b2135a5d6d46bb8ddc47da30` (2026-10-30), copied on
2026-11-03. Module names are unchanged (`Compiler.Parse.Module`,
`Compiler.AST.Source`, …), so code moves between the two easily. The copy
does not follow the compiler: changes there are brought over by hand when kg
needs them.

## What was changed

The compiler's parser reaches its IO layer (`System.IO`, `Eco.Console`,
`Eco.File`, …) through JSON helpers, and aborts on states it treats as
impossible through `Utils.Crash` and `Eco.Crash`. Crashing has no place in
ordinary Elm, so the copy has neither:

- **`Compiler.Reporting.Error.Syntax`** keeps only its error types. The
  messages (`toReport` and its helpers) and the binary codecs are left out,
  and with them `Compiler.Reporting.Doc`, `Render.Code`, `Report` and the ANSI
  pretty-printer. kg only asks whether a parse succeeded.
- **`Compiler.Elm.Package`** and **`Compiler.Elm.ModuleName`** lose their JSON
  codecs (`decoder`, `encode`, `keyDecoder`), so `Compiler.Json.Encode` and
  `Compiler.Json.Decode` are not needed, and with them `System.IO`.
- **`Compiler.Data.Name.getKernel`** is left out: nothing in the parser calls
  it, and it crashed on a name that is not a kernel module.
- **`Compiler.Parse.Primitives.unsafeIndex`** returns `'\u{0000}'` past the end
  of the text instead of crashing. Its callers check bounds first, and no
  parser looks for that character, so a test against it fails.
- **`Compiler.Parse.Shader`** does not parse the GLSL inside a `[glsl| … |]`
  literal: every shader is taken to declare no inputs. kg needs nothing from
  inside a shader, the GLSL parser package segfaults under eco 0.2.0 on any
  shader (`eco-bugs.md`), and leaving it out drops `guida-lang/glsl`. The
  unreachable branch of `addInput` that crashed is gone with it.

Nothing else was changed. On all 807 Elm files of eco-compiler that have no
shader, the copy gives kg exactly the facts the compiler's own sources gave;
on the 8 with shaders, the compiler's sources crashed and the copy parses
them.

- **The binary codecs are gone.** The AST, annotation, name, package,
  operator and shader modules carried encoders and decoders for the
  compiler's build cache; kg stores its facts with its own `Kg.Codec`. Removing
  them dropped `Compiler.AST.StringTable`, `Utils.Bytes.Decode` and
  `Utils.Bytes.Encode`, and with them `Compiler.Data.NonEmptyList` and
  `Compiler.Data.OneOrMore`.
- **Dead functions are gone:** 50 values nothing in kg or the parser uses,
  found by name and confirmed by the compiler (each removal that broke the
  build was put back). They were in `Compiler.Data.Name` (the names the type
  checker and code generators need: `isNumberType`, `fromVarIndex`, `jsArray`,
  …), `Compiler.Elm.ModuleName` (the WebGL and JSON module names, file paths,
  canonical ordering), `Compiler.Elm.Package` (package suggestions by edit
  distance, which also drops `dasch/levenshtein`, and URLs) and
  `Compiler.Parse.Primitives` (`fromSnippet`, `getCharWidth`).

What is left is 28 modules, about 14,500 lines (from 33 modules and 30,300
lines as first copied, and 51 modules and 36,600 lines reached from the
compiler's sources). The modules not needed by the parser
(`Compiler.Elm.Version`, `Compiler.Data.Index`, the JSON modules,
`Utils.Crash`, `Prelude` and the IO layer) were never copied.

Each step was checked the same way: on all 807 Elm files of eco-compiler
without a shader, kg's facts are byte for byte the ones the compiler's own
sources gave.
