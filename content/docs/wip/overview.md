---
title: "Overview"
description: "What eco is, why it exists, and how the compilation pipeline transforms Elm source into native executables."
section: "Architecture"
sectionOrder: 2
order: 1
---

## What is eco?

eco (Elm Compiler Optimized) is a native compilation backend for the Elm programming language. It takes standard Elm source code and compiles it to native executables via MLIR and LLVM, rather than the JavaScript output produced by the standard Elm compiler.

The compiler itself is written in Elm. It reuses the standard Elm frontend (parsing, canonicalization, type checking) and replaces the JavaScript code generator with a pipeline that preserves type information through every stage, ultimately producing MLIR that is lowered to LLVM IR and then to machine code.

## The Core Insight: Elm's Immutability Changes Everything

The single most important idea in eco's design is that **Elm's immutability guarantee** fundamentally simplifies runtime memory management.

In a typical generational garbage collector, you need to handle the case where an old-generation object is mutated to point to a young-generation object. This is called an "old-to-young pointer," and tracking it requires a **write barrier**: extra code that runs on every pointer store, plus remembered sets or card tables to scan during collection.

Elm values are immutable. Once created, they never change. This means:

- **New objects can only point to older objects:** they can only reference values that already exist at the time of creation.
- **Old-to-young pointers cannot exist:** an old object can never be modified to point to something newer.
- **No write barrier is needed** for generational correctness.

This is not a minor optimization. It eliminates an entire category of runtime complexity: card tables, remembered sets, store buffers, and barrier code on every write. The complexity you *don't* see in eco's runtime is the complexity you would normally expect in a generational GC. For more detail on how this shapes the runtime, see [Memory Model](/docs/memory-model#immutability-changes-everything).

## Compilation Pipeline

eco transforms Elm source to native code through a series of well-defined passes. Each pass has a clear input, output, and set of invariants:

```
Elm Source
    ↓
[Standard Elm Frontend: Parse, Canonicalize, Type Check]
    ↓
PostSolve
    - Fix incomplete expression types
    - Infer kernel function types
    ↓
Typed Optimization
    - Preserve types on every expression
    - Compile pattern matching to decision trees
    ↓
Monomorphization
    - Specialize polymorphic functions to concrete types
    - Compute record/tuple/custom type layouts
    ↓
Global Optimization
    - Canonicalize closure staging
    - Normalize calling conventions across branches
    - Compute call metadata
    ↓
MLIR Generation (ECO Dialect)
    - Generate typed intermediate representation
    - Bytes fusion (fuse encode/decode to cursor ops)
    - Build type table for debug printing
    ↓
ECO Dialect Lowering
    - JoinPoint normalization
    - Control flow to SCF (Structured Control Flow)
    - CheckEcoClosureCaptures (verification)
    - RC elimination verification
    ↓
EcoToLLVM
    - Final lowering to LLVM dialect
    - Typed closure calling (direct calls where possible)
    ↓
LLVM IR → Native Code
```

### PostSolve and Typed Optimization

The standard Elm compiler discards types after type checking: JavaScript doesn't need them. eco's backend needs types for layout computation, unboxing, and machine-level code generation, so these passes fix incomplete types and attach type information to every expression in the AST. See [Type Preservation](/docs/type-system) for the full story.

### Monomorphization

Elm's parametric polymorphism (`List.map : (a -> b) -> List a -> List b`) must be resolved for native code. The monomorphizer generates specialized versions for each concrete type combination used in the program, computing field layouts and identifying opportunities for unboxed storage. The layout decisions feed into the [four representation models](/docs/heap-representation) that govern how values are stored and passed through the system. See [Monomorphization](/docs/monomorphization).

### Global Optimization and Staged Currying

Elm functions are semantically curried: `add : Int -> Int -> Int` can be partially applied as `add 1`. Naive compilation would create a closure for each argument. Global optimization analyzes how functions are actually used and determines efficient argument groupings (staging signatures), normalizing calling conventions across case branches. This phase also handles [kernel function](/docs/kernel-functions) ABI decisions: C++ runtime primitives have fixed calling conventions that the optimizer must respect. See [Staged Currying](/docs/staged-currying).

### MLIR Generation and Lowering

The monomorphized program is converted to MLIR using a custom ECO dialect with operations for Elm's runtime semantics (`eco.construct.list`, `eco.case`, `eco.call`, etc.). During generation, [Bytes Fusion](/docs/bytes-fusion) intercepts `Bytes.encode`/`Bytes.decode` calls and lowers them to direct cursor operations, eliminating interpreter overhead. The IR is then progressively lowered: first to MLIR's Structured Control Flow dialect, then to the LLVM dialect, and finally to LLVM IR for native code generation. During LLVM lowering, [Typed Closure Calling](/docs/typed-closure-calling) generates direct typed function calls for closures with known structure, eliminating generic wrapper overhead. See [Code Generation](/docs/code-generation).

### Runtime

The compiled code runs against eco's C++ runtime, which provides memory management via a generational garbage collector with thread-local heaps. Each thread owns its own nursery and old generation, eliminating cross-thread synchronization during normal operation. See [Memory Model](/docs/memory-model) and [Garbage Collection](/docs/garbage-collection).

## Design Philosophy

Three principles guide eco's design:

**Type preservation end-to-end.** Type information flows from Elm source through every compilation phase to the final native code. This enables unboxing optimizations, type-specific machine operations, and runtime debug printing with full type awareness. The type flow is: `Can.Type → TypedOptimized → MonoType → MlirType → LLVM types`.

**Start simple, prove correctness, then optimize.** Complexity is added only when necessary and is validated by invariant testing. The compiler backend maintains a catalog of invariants (over 80 documented in `invariants.csv`) that are mechanically checked at three levels: inline verifiers on MLIR operation creation (catching type mismatches immediately), dedicated verification passes like CheckEcoClosureCaptures (validating cross-operation invariants), and Elm-side property tests that inspect the generated MLIR AST before emission.

**Separation of concerns.** Each pass has a focused responsibility. Monomorphization handles type specialization without worrying about calling conventions. Global optimization handles ABI decisions without worrying about polymorphism. MLIR codegen consumes pre-computed metadata without making independent staging decisions. This makes each pass simpler to understand, test, and maintain.
