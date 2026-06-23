---
title: "Here is eco"
description: "An introduction to the eco compiler, its goals, and origins."
section: "Compilers"
sectionOrder: 1
order: 1
image: /images/intro-banner.png
---


## Elm Compiler Optimized

eco is an Elm compiler and runtime intended to bring Elm’s qualities to a wider domain of application: 
native executables, high performance server processes, and cloud backends. The goal is to make it possible to 
write systems in a high level, purely functional language with strong static guarantees. eco is a 
bet that you can have Elm’s safety and clarity with zero compromise on performance, across the whole stack.

eco is a re‑implementation of the Elm compiler, written in Elm itself. The name stands for **Elm Compiler 
Optimized**, reflecting its dual focus on staying true to Elm’s design while pushing hard on performance 
and optimizing compilation techniques.
 
From a technical perspective, eco is a production‑oriented compiler that targets both **native code** and 
**JavaScript**. It retains Elm’s familiar guarantees - strong static typing, purity, and a focus on maintainable,
front‑end applications-while extending the range of deployment options. The ability to compile Elm down to 
native code opens the door to new classes of applications and performance profiles, while continuing to support
JavaScript keeps eco compatible with the existing Elm ecosystem.

A distinctive design choice in eco is that it **preserves type information throughout the entire compilation
pipeline**. The original Elm compiler targeting JavaScript throws away most type information earlier in the
process. eco takes the opposite approach: it keeps rich type data available to later stages, enabling optimizations 
that would otherwise be impossible or much harder to perform. Types are not just for catching errors at compile
time; they can also guide the generation of efficient machine code.

eco’s aim is to be a **high‑performance, production‑grade Elm compiler** designed with modern hardware in mind.
By combining Elm’s declarative model and strong types with an aggressively optimizing backend, eco seeks to
make it practical to write large, performance‑sensitive systems in Elm without giving up the language’s clarity
and reliability.

In short, eco stands on the shoulders of the original Elm compiler and Guida, extending their ideas into a 
new compiler that is self‑hosted, optimization‑driven, and ready to target both JavaScript and native 
code-while remaining firmly rooted in the values and design of Elm.

## Status

The overall status of the 0.1.0 release is alpha, reflecting the maturity of the code at this time. There 
will be bugs (please find some!), possibly even severe ones. The bundled kernel IO code is an internal compiler
API exposed for convenience; experiment with it but don't get too comfortable and don't rely on it. A more
complete set of IO APIs will follow and replace this API.

The full pipeline works today: Elm source compiles through a typed AST, whole-program monomorphisation and 
optimisation, a custom MLIR dialect, and LLVM down to native x86 binaries (AOT) or JIT execution, backed by 
a generational garbage collector and effect-manager runtime. 

Linux x86_64 only. eco is now building and passing tests on Windows and Mac and these platforms will follow
up soon in a 0.2.0 release.

The compiler is capable of building itself, which is a complex 160K LOC program, which goes along way towards
proving the implementation is real-world capable.

## What can it do today ?

* Build new native Elm programs using the Eco internal compiler kernel for File IO, HTTP, and console.
* Build existing Platform.Worker programs, with ports written in Javascript and run native code via NodeJS.
* Build new Platform.Worker programs, with zero Javascript and ports implemented in C/C++.
* Build existing Elm programs to Javascript output identical to the original compiler.

## What are the next steps ?

Builds for Mac and Windows will follow very soon in a 0.2 release. Any technical risks have already been
overcome, it is just a question of creating nice distribution bundles for these.

Once that is in place, a set of IO APIs for CLI and server side use will be created for the long term and
the existing IO APIs that support the compiler will be internalized into the compiler.

Consult the roadmap for more details.

## Acknowledgements

eco has a clear lineage. It is forked from **Guida**, which in turn is a fork of the original **Elm** compiler. 
 
The original Elm compiler and the Elm language were created by **Evan Czaplicki**, whose work defined the 
foundations this project relies on: the language design, the type system, and the surrounding ecosystem. 
 
**Décio Ferreira** ported the Elm compiler from Haskell to Elm, making it possible to have a self‑hosting
toolchain. 
 
eco builds directly on these efforts. It would not exist without Evan’s years of work on Elm 
and Décio’s work on Guida, and I am grateful to both of them.
