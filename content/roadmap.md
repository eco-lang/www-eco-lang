---
title: "Roadmap"
description: "Track the evolution of eco from first commit to stable release."
statuses:
  v0.1.0: released
  v0.2.0: current
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

## v0.2.0: Platforms

Support the platforms that Elm developers use.

- [ ] Support for Mac.
- [ ] Support for Windows.
- [ ] Tidy ups (strip debug symbols, don't link unused stuff).

## v0.3.0: Core

Ecosystem growth, APIs and build maturity.

- [ ] New Eco Kernel packages suited to CLI and server-side environments (files, sockets, posix).
- [ ] Multi-threading support (actors, typed mail boxes, Task spawning)
- [ ] Completion of all standard libraries (browser, virtual-dom)
- [ ] Support for elm-test.
- [ ] Optimizations (UTF-8 String support, closure elimination, representation streamlining)
- [ ] CI nightly builds with extensive testing.

## v0.4.0: Optimize

Advanced optimizations, and production-grade output quality.

- [ ] Closure elimination, lambda set specialization.
- [ ] Perceus reference counting algorithm as alternative to garbage collection.
- [ ] More compiler front end optimisation, tail recursion modulo cons, and so on.
- [ ] What optimisations can MLIR yield ? Loop fusion, vectorization ?

## v1.0.0: Stable

The first stable release with long-term support commitment.

- API stability guarantee and migration tooling
- Comprehensive test suite with 95%+ coverage
- Full documentation with interactive examples
- Production deployment guides and best practices

## v1.1.0: Beyond

Community-driven features, and enterprise-grade tooling.
