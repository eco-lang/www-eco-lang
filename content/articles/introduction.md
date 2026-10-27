---
title: "Here is eco"
description: "An introduction to the eco compiler, its goals, and origins."
section: "Compilers"
sectionOrder: 1
order: 1
image: /images/intro-banner.png
socialImage: /images/intro-social.png
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
**JavaScript**. It retains Elm’s familiar guarantees (strong static typing, purity, and a focus on maintainable
applications) while extending the range of deployment options. The ability to compile Elm down to
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
code, while remaining firmly rooted in the values and design of Elm.

For a longer account of what eco is for, see [Why eco](/docs/why-eco).

## Status

eco runs on Linux x86_64, macOS on Apple Silicon and Windows x86_64. The version number is still below 1.0
for a reason: there will be bugs (please find some!), possibly even severe ones. To install it and build a
first program, see [Getting started](/docs/getting-started).

The full pipeline works today. Elm source compiles through a typed AST, whole-program monomorphization and
optimization, a custom MLIR dialect, and LLVM, down to native executables, shared libraries and Node addons.
These run on a generational garbage collector and an effect-manager runtime. Along the way, closures are
removed by [lambda-set specialization](/docs/lambda-set-specialization), and the collector does much of its work
concurrently, with its threaded algorithms checked against [formal models in TLA+](/docs/verification).

The compiler builds itself. It is about 240,000 lines of Elm, and every build checks that it can rebuild itself
with byte-for-byte identical output, which goes a long way towards showing the implementation is capable of
real-world programs. See [The compiler compiles itself](/docs/bootstrap).

## What can it do today?

* Build native Elm programs for the command line and the server with [eco/system](/packages/eco/system):
  files, processes, streams, the terminal, sockets, an HTTP server and WebSockets.
* Build existing Elm programs to JavaScript, with output identical to the original compiler.
* Build Elm code into a shared library or a Node addon, so that it can sit inside a larger program written in
  another language.
* Build `Platform.worker` programs with zero JavaScript, with their ports implemented in C/C++.

## What are the next steps?

The next release fills the remaining gaps in the Elm package set: the elm-explorations packages, such as
webgl, linear-algebra, test, benchmark and markdown.

After that, the focus moves to threads and to deeper optimization: multi-threaded Elm built on actors with typed
mailboxes, incremental compilation, borrow inference from escape analysis, and in-place updates of values that
nothing else refers to.

See the [roadmap](/roadmap) for more details.

## Acknowledgements

eco has a clear lineage. It is forked from **Guida**, which in turn is a fork of the original **Elm** compiler.

The original Elm compiler and the Elm language were created by **Evan Czaplicki**, whose work defined the
foundations this project relies on: the language design, the type system, and the surrounding ecosystem.

**Décio Ferreira** ported the Elm compiler from Haskell to Elm, making it possible to have a self‑hosting
toolchain.

**Robin Heggelund Hansen**, the creator of Gren, gave permission for Gren's standard libraries to be copied
as the starting point for eco's system library, [eco/system](/packages/eco/system). Gren's streams, one of
Robin's notable innovations, are the model that library is built around.

eco builds directly on these efforts. It would not exist without Evan’s years of work on Elm
and Décio’s work on Guida, its system library owes its start to Robin’s work on Gren, and I am
grateful to all three of them.
