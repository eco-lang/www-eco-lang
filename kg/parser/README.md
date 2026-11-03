# kg's copy of the eco parser

kg reads Elm source with eco's own parser. This directory is a copy of the
parser, checked in here, so that kg builds on its own: it does not read
eco-compiler's sources to build, and it needs nothing from the `eco/kernel`
package.

## Where it came from

The 33 modules the parser needs, from eco-compiler's `compiler/src` at
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

The modules not needed by the parser (`Compiler.Elm.Version`,
`Compiler.Data.Index`, the JSON modules, `Utils.Crash`, `Prelude` and the IO
layer) are not copied.
