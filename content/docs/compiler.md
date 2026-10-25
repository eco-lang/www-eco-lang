---
title: "The compiler"
description: "An overview of Eco's compiler: a per-module half that checks and caches typed code, a whole-program half that specializes it, and the parts that make up each."
section: "The compiler"
sectionOrder: 2
order: 1
---

Eco's compiler works in two halves with a cache between them. The first half looks at one module at a time and keeps everything the type checker learned about it. The second half sees the whole program at once and uses those types to turn polymorphic, higher-order Elm into code where every value has one concrete layout and most calls go straight to a known function.

> **Background**
> - [Monomorphization](/docs/glossary#monomorphization): making one copy of a polymorphic function for each concrete type it is used at.
> - [Lambda set](/docs/glossary#lambda-set): the set of functions that can reach a place that holds a function value.
> - [MLIR](/docs/glossary#mlir): a compiler framework for building intermediate languages; Eco's own is the eco [dialect](/docs/glossary#dialect).

## Two halves

The per-module half parses a module, resolves its names, type checks it, runs Elm's pattern checks and applies the optimizations that do not need concrete types. Its output is one typed graph per module, which the build caches on disk. It depends only on the module's source and the interfaces of the modules it imports, so an unchanged module is not compiled again.

The whole-program half links the cached graphs into one typed program rooted at `main` and runs a fixed list of steps over it. It specializes every function to the concrete types it is used at, works out which functions can reach each call, inlines, removes what nothing reaches any more, settles how each call is made, and writes the result as eco-dialect MLIR for the C++ [backend](/docs/backend).

![The parts of the Eco compiler and what passes between them](/images/docs/compiler-pipeline.svg)

Two properties of Elm make the whole-program half safe. Elm has no side effects, so inlining, deleting unreachable code or copying a function for one type changes nothing a program can observe. And the whole program is known, so the second half can start from `main` and see every use of every function.

## Compute each fact once, where it can be computed

The rule that shapes the compiler is that each fact is computed once, at the step that can compute it, and passed forward as data. The type of every expression is a fact about one module, so the front end records it. The concrete types a function is used at, the functions that can reach a call and how each call is made are facts about the whole program, so the second half decides them. Later steps read these decisions and never derive them again. The C++ passes follow the same rule one boundary further on: they read the compiler's decisions as attributes on the dialect's operations.

## Typed or erased, chosen once per build

Stock Elm's optimizer throws types away, because JavaScript does not need them. Eco's native path does need them, so Eco keeps a typed form of the optimized program beside Elm's erased one rather than changing Elm's. MLIR and native outputs take the typed path. JavaScript and HTML take the erased path, Elm's own optimizer and generator, so Eco's JavaScript is what Elm produces.

Both paths share one constraint generator, which records each expression's solver variable only in typed mode. We once kept two near-identical generators, and they drifted until they reported the same record-update error at different places in the source.

## The parts

The typed path has six parts, in the order a program passes through them.

- **[The front end](/docs/front-end)** is Elm's own parser, name resolution, type checker and pattern checks, kept faithful to Elm's error messages. Its one addition is that it keeps the type of every expression.
- **[Local optimization](/docs/local-optimization)** rewrites each module before types are concrete: pattern matches become decision trees and self-recursion becomes loops.
- **[Monomorphization](/docs/monomorphization)** starts from `main` and makes one specialization of each function for each concrete type it is used at, typing each one with the type checker's own unifier.
- **[Lambda-set specialization](/docs/lambda-set-specialization)** works out which functions can reach each call. It is not a separate pass: it runs inside monomorphization, in the same solver.
- **[Global optimization](/docs/global-optimization)** inlines, regroups curried functions by the arguments they really take, and records how every call is made.
- **[MLIR generation](/docs/mlir-generation)** writes the finished program out in the eco dialect. Everything has been decided by then, so it only reads decisions. [Bytes fusion](/docs/bytes-fusion) is a fast path inside it for `elm/bytes` encoders and decoders.

Beside them sit [JavaScript output](/docs/javascript-output), Elm's original generator, and [the build driver](/docs/build-driver), which runs everything over a project from the cache.

## The build and the tests run the same steps

The whole-program half is a list of pure functions: number every variable, apply the pre-monomorphization rewrites, monomorphize, inline and prune, then globally optimize, with checkers between the steps. The build and the test suites call the same functions in the same order, because a harness with its own copy of the pipeline drifts and ends up checking output the real compiler never produces.

## Compiler code must also run as JavaScript

The compiler is itself an Elm program, and before a native binary exists it runs under Node (see [The compiler compiles itself](/docs/bootstrap)), so the JavaScript engine's stack and heap limits apply to it. Recursion that grows with program size would overflow the stack on thousands of specializations, so graph algorithms use explicit work stacks and long chains such as `let` sequences are walked in tail-recursive loops that Elm compiles to plain loops.

On the compiler's own source, the native self-compile takes about a minute, several times faster than before this work, with roughly half the peak memory ([Performance](/docs/performance)).

## Further reading

- [A tour through the compiler](/docs/tour) — one small program followed through every stage.
- [The front end](/docs/front-end) — where the types come from.
- [Optimisations](/docs/optimisations) — every optimisation in one list.
- The full design document: [The compiler theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/compiler.md)
- Source: [`compiler`](https://github.com/eco-lang/eco-compiler/tree/master/compiler)
