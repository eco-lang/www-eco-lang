---
title: "Roadmap"
description: "Track the evolution of eco from first commit to stable release."
statuses:
  v0.1.0: released
  v0.2.0: released
  v0.2.1: current
  v0.3.0: planned
  v0.4.0: planned
  v1.0.0: planned
  v1.1.0: planned
---

## v0.1.0: Genesis

The initial release establishing the foundation of the eco compiler infrastructure.

- [x] Forked from Guida compiler port.
- [x] eco bytecode dialect established, compilation via LLVM to x86 binaries.
- [x] Standard library scaffolding (core, json, bytes, http, regex, url, parser, time)
- [x] Internal eco kernel providing the IO the compiler needs (files, http, console)
- [x] Innovative bytes fusion DSL compilation.
- [x] Full program optimisation and monomorphisation pass.
- [x] Extensive test suite confirming compiler correctness.
- [x] Simple garbage collector.
- [x] Self-compilation.
- [x] NodeJS embedding of Platform.Worker with JS ports.
- [x] Linux only.
- [x] Tidy ups (strip debug symbols, don't link unused stuff).

## v0.2.0: Platforms, Compiler and Runtime

Support the platforms that Elm developers use.

- [x] Support for Mac.
- [x] Support for Windows.
- [x] New Eco Kernel packages suited to CLI and server-side environments (files, webserver, sockets, posix).
- [x] Completion of all standard libraries (browser, virtual-dom)
- [x] CI nightly builds with extensive testing.

Core compiler techniques establishing the optimising compiler architecture.

- [x] Closure elimination, lambda set specialization.
- [x] Optimizations (UTF-8 String support, chunked lists, inlining and fast calls)
- [x] New monomorphizer engine based on the type solver.

Runtime 

- [x] Garbage collector performance, lower pause times and concurrent collection work.
- [x] Runtime modelling and testing with TLA+ to help verify threaded GC algorithms.

## v0.2.1: Gap Fill

The remaining Elm standard libraries under elm-explorations/.

- [ ] Support for elm-explorations/webgl and elm-explorations/linear-algebra.
- [ ] Support for elm-explorations/test.
- [ ] Support for elm-explorations/benchmark.
- [ ] Support for elm-explorations/markdown.

## v0.3.0: Optimize and Threads

First true multi-threaded Elm.

- [ ] Multi-threading support (actors, typed mail boxes, Task spawning)

Advanced optimizations, and production-grade output quality.

- [ ] Incremental compilation.
- [ ] Kernel calls removed, replaced with MLIR templates and intrinsics.
- [ ] Escape analysis as borrow inference.
- [ ] Functional but in-place opportunistic mutation.
- [ ] What optimisations can MLIR yield ? Loop fusion, vectorization ?

## v1.0.0: Stable

The first stable release with long-term support commitment.

- API stability guarantee and migration tooling
- Comprehensive test suite with 95%+ coverage
- Full documentation with interactive examples
- Production deployment guides and best practices

## v1.1.0: Beyond

Community-driven features, and enterprise-grade tooling.
