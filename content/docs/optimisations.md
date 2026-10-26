---
title: "Optimisations"
description: "Every optimisation Eco performs, grouped by the stage of the compiler, backend or runtime that does it, with a short example of each."
section: "Introduction"
sectionOrder: 1
order: 5
---

An optimisation can only use what is known at the point it runs. Some facts are known within one module, some only once types are concrete, some only once the whole program is linked, and some only in the machine code. Each of Eco's optimisations therefore runs at the earliest stage that has the fact it needs, and this page lists them in that order, each with a sentence or two and a link to the article that explains it.

> **Background**
> - [Monomorphization](/docs/glossary#monomorphization): making one copy of a generic function for each type it is used at.
> - [Lambda set](/docs/glossary#lambda-set): the set of functions that can reach a particular call through a function value.
> - [Boxed and unboxed](/docs/glossary#boxed-and-unboxed): a value stored behind a pointer to a heap object, or held directly in a register or field.
> - [Nursery and eden](/docs/glossary#nursery-and-eden): the area where new objects are allocated, and collected young.
> - [Write barrier](/docs/glossary#write-barrier): extra code a garbage collector adds to every pointer store.

One principle runs through all of them: we judge an optimisation by the work it removes, not by how clever it is. A copying collector makes short-lived objects almost free and copies only those that survive into the old generation, so an optimisation that saves allocations can still change nothing in run time unless it also reduces what is retained. That lesson took a few experiments to learn.

The examples below are real output from Eco 0.2.0, with attributes trimmed. [A tour through the compiler](/docs/tour) shows several of them in the context of one whole program.

## Before types are concrete

These run on each module by itself, before the whole program is known, and every rewrite keeps the type the checker recorded. See [Local optimization](/docs/local-optimization).

**Decision trees.** A `case` is compiled into a tree of tests in which each part of the value is examined at most once, and a branch reached by several paths is shared rather than copied. A complete match needs no final test, because in a `case` over three constructors the third is whatever is left.

**Tail calls become loops.** A function that calls itself in tail position becomes a loop. `sumTo acc n = if n <= 0 then acc else sumTo (acc + n) (n - 1)` comes out as an `scf.while` loop over two `i64` values, with no call and no stack growth.

**Operator rewrites.** `&&` and `||` become conditionals, so the right-hand side is only evaluated when needed, and `|>` and `<|` become plain calls with no function value in between.

**Merging function boundaries.** `adder a = \b -> a + b` is written as a one-argument function that returns a function. Eco merges the two levels into one two-argument function, `Stage_adder_$_5 : (i64, i64) -> i64`, so a full call to `adder` builds no intermediate closure.

## Whole program

These need every module linked, starting from `main`. See [Global optimization](/docs/global-optimization).

**Monomorphization and unboxing.** Every generic function is copied once per type it is used at, and in each copy `Int`, `Float` and `Char` values are held unboxed, in registers and in the fields of the objects that contain them. `add : number -> number -> number`, used only on `Int`, becomes `Main_add_$_1 : (i64, i64) -> i64`. See [Monomorphization](/docs/monomorphization).

**Lambda-set specialization.** For every call through a function value, Eco works out which functions can arrive there. When only one can, the call goes straight to it. On the compiler compiling itself, it turns roughly three quarters of the generic closure applications into direct or fast calls, and raises the share of calls with a statically known target from about 84% to about 94%. See [Lambda-set specialization](/docs/lambda-set-specialization).

**Alias forwarding and eta-expansion.** A definition that only names another, such as `dup = twice`, disappears, and references to it go to `twice` directly. A definition that is a partial application, such as `inc = adder 1`, is rewritten to take its missing argument, so `inc` becomes a one-argument function that calls `adder` directly:

```mlir
^bb0(%_eta3: i64):
  %1 = "arith.constant"() {value = 1 : i64} : () -> i64
  %2 = "eco.call"(%1, %_eta3) <{callee = @Stage_adder_$_5}> : (i64, i64) -> i64
  "eco.return"(%2) : (i64) -> ()
```

**Inlining and pruning.** After monomorphization, small specializations are inlined into their callers, and those left without references are removed. A function that calls one of its own parameters, such as `twice f x = f (f x)`, gets a larger budget, because inlining it lets the function it was given be called directly.

**Direct and fast calls.** Each call through a function value is given a call kind. Either the callee's arity is known, or it is a single known function called by its fast entry point, or nothing is known and the runtime's generic apply has to inspect the closure. Code generation emits whatever the call kind says, and never works it out again. See [Closures and calls](/docs/closures-and-calls).

## Code generation

These happen while the program is written out as MLIR. See [MLIR generation](/docs/mlir-generation).

**Unboxed tuple returns and split parameters.** A function returning a small tuple hands its fields back without allocating a tuple (the backend writes them into a slot on the caller's stack), and a function taking one receives its fields as separate arguments. `divMod a b = ( a // b, modBy b a )` and `magnitude ( x, y ) = x * x + y * y` become:

```mlir
%3, %4 = "eco.call"(%1, %2) <{callee = @Agg2_divMod_$_1$sret}> : (i64, i64) -> (i64, i64)
%9 = "eco.call"(%7, %8) <{callee = @Agg2_magnitude_$_2$psplit}> : (i64, i64) -> i64
```

The tuple in between exists only as an SSA value, never on the heap.

**Bytes fusion.** Encoders and decoders from `elm/bytes` that are fully known at compile time become direct reads and writes on a buffer, a [reification](/docs/reification) of the library's opaque types. An encoder of three bytes becomes one allocation and three writes (trimmed):

```mlir
%11 = "bf.alloc"(%10) : (i32) -> !eco.value
%12 = "bf.cursor.init"(%11) : (!eco.value) -> !bf.cursor
%13 = "bf.write.u8"(%12, %r) : (!bf.cursor, i64) -> !bf.cursor
%14 = "bf.write.u8"(%13, %g) : (!bf.cursor, i64) -> !bf.cursor
%15 = "bf.write.u8"(%14, %b) : (!bf.cursor, i64) -> !bf.cursor
```

On the benchmark suite, decoder fusion makes a byte-decoding workload 2.6 times faster (27 ms against 71 ms). Decoders built with `map2` and `map3` do not fuse yet. See [Bytes fusion](/docs/bytes-fusion).

**Top-level constants.** A top-level value with no arguments can be computed once and cached. When its body is a literal or small closed arithmetic, it is instead written out at every place that uses it, so LLVM can fold it away entirely.

## Backend

These happen in the C++ backend and LLVM. See [The backend](/docs/backend) and [Lowering passes](/docs/lowering-passes).

**Inline bump allocation.** Allocating a fixed-size object is a pointer bump and one compare, inlined into the compiled code. Only the rarely taken branch calls the runtime, and that branch is also the only place a collection can start.

**Fast paths as markers.** The lowering emits allocations and some other fast paths as calls to marker functions, such as `__eco_alloc_inline`. Because the markers are opaque, the MLIR passes and the translation to LLVM leave them alone. They are expanded into their inline form just before statepoint rewriting, the step that records which stack values are heap pointers.

**Parallel LLVM partitions.** An optimised build is split into partitions that LLVM compiles on separate threads. This lets the backend compile the compiler's own source in about twenty seconds.

## Runtime

See [The runtime](/docs/runtime), [The garbage collector](/docs/garbage-collector) and [Runtime data structures](/docs/data-structures).

**A generational collector without a write barrier.** In Elm an object never changes after it is built, so an old object can never come to point at a younger one. The generational collector therefore needs no write barrier, and compiled code stores pointers with plain stores.

**Concurrent marking and parallel minor collections.** The old generation is marked on background threads while the program runs, and young collections are shared among several threads. On the compiler compiling itself, the worst pause is under 100 ms, where a single-threaded collector would pause for nearly three seconds.

**String and list forms.** A string can be a flat array, a slice of another string or a rope joining two, so slicing and repeated `++` do not copy. A list can mix single cons cells with views over dense arrays, which bulk operations such as `reverse` and `append` produce. On the compiler's own run, chunked lists cut the number of cons cells by roughly half. Both are [reifications](/docs/reification): the types mean what they always did, but are built differently.

## Further reading

- [A tour through the compiler](/docs/tour) — many of these optimisations, seen in one program's real output.
- [Performance](/docs/performance) — what they add up to on the benchmark suite, including where Eco is slower.
- [Global optimization](/docs/global-optimization) — the whole-program stage, where most of these run.
- [The garbage collector](/docs/garbage-collector) — the generational collector and why it needs no write barrier.
- The full design document: [Global optimization theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/global-optimization.md)
- Source: [`compiler/src/Compiler/GlobalOpt`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Compiler/GlobalOpt)
