---
title: "Eco at a glance"
description: "The five ideas behind Eco's design and a one-paragraph summary of each part of the system: compiler, backend, runtime, kernels, and the checks that hold them together."
section: "Introduction"
sectionOrder: 1
order: 3
---

Eco is a compiler split across two languages. The half that understands Elm is written in Elm; the half that produces machine code is written in C++ on top of MLIR and LLVM. Most of Eco's design follows from two facts: Elm's guarantees make a simple runtime and fast code possible, and the two halves must agree on every detail without any type system that sees both.

> **Background**
> - [MLIR](/docs/glossary#mlir) and [dialect](/docs/glossary#dialect): a framework for typed intermediate languages, and one such language.
> - [Monomorphization](/docs/glossary#monomorphization): making one copy of a polymorphic function per concrete type.
> - [Write barrier](/docs/glossary#write-barrier): extra code a generational collector adds to pointer stores.
> - [Fixed point](/docs/glossary#fixed-point): a compiler that rebuilds itself and gets identical output.

## The five ideas

### Values never change, so the collector can be simple

Once an Elm value is built and the program can see it, nothing writes to it again. A generational collector, which collects young objects often and old ones rarely, normally needs a write barrier to record each time an old object comes to point at a young one. In Elm that cannot happen: the young object did not exist when the old one was last written. Eco's collector has no write barrier. It collects the young generation, the nursery, by copying the survivors out, and because it moves objects it must know exactly which stack slots hold pointers, which the backend arranges with LLVM.

What matters is that values never change, not that they never form cycles. A recursive closure captures itself, and the collector traces cycles like any other graph. The runtime and the C++ kernels do build objects in place, but only objects the program cannot see yet. One thread per process, the eco thread, runs Elm code and owns the heap. Helper threads mark and promote in the background, again with no barrier, and service threads for IO never touch the heap at all.

### The whole program is known, so every function is specialized

Elm has no dynamic loading, so the compiler sees every use of every function. Starting from `main`, it makes a separate copy of each polymorphic function for each concrete type it is used at. The backend can then keep `Int`, `Float` and `Char` unboxed in registers and call functions directly. A type variable that no use pins down stays boxed, so a value of unknown type always has one layout.

Specialization needs the types that type checking finds, and Elm's optimizer throws them away. Rather than change Elm's optimizer, Eco keeps a typed copy of the optimized program alongside it. That gives the compiler two paths, chosen by the output format: a typed path for native code and MLIR, and Elm's own erased path for JavaScript and HTML.

### One value, four representations

The same Elm value takes different forms in different places, and Eco names four of them: how it is passed across a call (the ABI form), how it appears in the intermediate code (the SSA form), how it is stored in a heap object (the heap form), and what it means in Elm (the logical form). The commonest code-generation bug in Eco is a phase assuming that one form implies another.

`Bool` is the standard example. Inside a function it is a one-bit integer, but in heap fields, closures and call arguments it is one of two constant words, never a raw bit. A phase that stores a raw bit in a heap field because a `Bool` is one bit elsewhere corrupts the heap. Only `Int`, `Float` and `Char` are ever stored unboxed, and a value changes form only at a few named places such as calls, captures and construction. See [Value representation](/docs/value-representation).

No type system spans the Elm half and the C++ half, so the rules that link these forms are written down as a catalog of 417 numbered invariants. Each phase is written and tested against the rules rather than against what its neighbours happen to do, and each check names the rule it enforces. See [The numbered invariants](/docs/invariants).

### A custom dialect between the two halves

Everything that crosses from the Elm compiler to the C++ backend is an operation in Eco's own MLIR dialect. The compiler is an Elm program and cannot call MLIR's C++ libraries, so it writes the program out as MLIR bytecode, and the backend, linked into the same `eco` process, reads it back in. A dialect of Eco's own lets the C++ passes reason in Eco's terms (boxed values, constructors, closures, groups of allocations) before LLVM sees anything.

The compiler decides cross-cutting facts once, such as a value's memory layout or how each call is made, and attaches each decision to the operations as an attribute. The C++ passes read these decisions and never work them out again, because two halves that each derive the same fact drift apart. See [The eco dialect](/docs/eco-dialect).

### The compiler compiles itself

The compiler is a large Elm program that allocates heavily, which makes it the best test of the whole stack. A staged chain starts from the stock Elm compiler, which can only build JavaScript, builds a JavaScript Eco, then a native Eco, and checks twice that the compiler rebuilt by itself is byte-for-byte identical. That is why the JavaScript backend stays: it is the first link of the chain and the reference for correct behaviour. See [The compiler compiles itself](/docs/bootstrap).

## The parts

![How Eco turns Elm source into a native program](/images/docs/overview-pipeline.svg)

**The compiler** turns Elm source into eco-dialect MLIR in two halves with a cache between them. The first half handles each module on its own: parsing, name resolution, type checking and the optimizations that need no concrete types. The second half links every module into one typed program and runs a fixed list of whole-program steps over it: specialize, inline, prune, optimize, then write MLIR. See [The compiler](/docs/compiler).

**The backend** turns that MLIR into native code in one fixed sequence. A stack of small passes lowers the eco dialect to LLVM's dialect; LLVM records, at every point where the collector might run, which stack slots hold heap pointers; LLVM optimizes and emits object files in parallel; and a link step joins them with the prebuilt runtime and kernels. The in-memory JIT used by the tests and the ahead-of-time compiler users run share all of this and differ only at the last step. See [The backend](/docs/backend).

**The runtime** is linked into every program. It has two halves: the garbage collector described above, and a cooperative scheduler that runs Elm's tasks, effect managers, timers, HTTP and ports on the eco thread. See [The runtime](/docs/runtime).

**The kernels** are Elm's built-in functions and Eco's IO libraries, written in C++ to work directly on Eco's heap. Elm's own kernels are ported from their JavaScript originals so that unmodified Elm packages run; the public `eco/system` library adds files, processes, sockets and an HTTP server. The compiler alone decides how each kernel is called, and the C++ decides only what it does. See [Kernels](/docs/kernels).

**Closures and calls** cut across the compiler, backend and runtime. Every Elm function value is a closure on the heap whose header records everything needed to apply it, so the runtime can apply any closure to any number of arguments without knowing anything else about it. The compiler emits a faster call only where it can prove the faster call correct. See [Closures and calls](/docs/closures-and-calls).

**Verification** layers checks so that each kind of bug meets the cheapest check that can catch it: structural checks on the compiler's intermediate forms, whole Elm programs with their expected output, expected-text tests for generated MLIR and each lowering pass, unit and property tests for the runtime, and TLA+ models of the collector's concurrency. See [How we know it works](/docs/verification).

## Shipping one binary

Eco is distributed as a single `eco` binary per platform: Linux x86_64, macOS on Apple Silicon and Windows x86_64. The Elm front end and the C++ backend run in one process because users should install one tool, not two cooperating programs piped together.

Generated code targets a fixed CPU model for each architecture (x86-64-v3 on Intel and AMD, Apple M1 on Apple Silicon) rather than the machine doing the compiling. The compiler is itself a binary that Eco builds, and a compiler tuned to the build machine once carried AVX-512 instructions that crashed on machines without them. On Linux the toolchain is statically linked against the musl C library and carries its own linker, so it depends on neither the host's C library nor its linker.

## Further reading

- [Why Eco](/docs/why-eco) — what Eco is for, in brief.
- [A tour through the compiler](/docs/tour) — one program followed through every stage shown here.
- [Optimisations](/docs/optimisations) — every optimisation Eco does.
- [Glossary](/docs/glossary) — the terms used across these pages.
- The full design document: [Eco theory](https://github.com/eco-lang/eco-compiler/blob/master/THEORY.md)
- Source: [`compiler`](https://github.com/eco-lang/eco-compiler/tree/master/compiler), [`runtime`](https://github.com/eco-lang/eco-compiler/tree/master/runtime)
