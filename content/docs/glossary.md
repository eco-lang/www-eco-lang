---
title: "Glossary"
description: "Short definitions, in eco's terms, of the compiler, runtime and verification terms used across the eco documentation, each linked to the article that explains it."
section: "Introduction"
sectionOrder: 1
order: 7
---

These are the terms used across the eco documentation. Each is defined as eco uses it, which is sometimes narrower than the general meaning, and links to the article that explains it in full.

## ABI

The application binary interface: how a value is passed across a function call. In eco's ABI an `Int`, `Float` or `Char` is passed as a raw machine value and everything else, `Bool` included, as one 64-bit value word. See [Value representation](/docs/value-representation).

## Boxed and unboxed

An *unboxed* value is a raw machine number held directly in a register or field. A *boxed* value is a 64-bit word that is either a pointer to a heap object or a small constant embedded in the word itself. eco unboxes only `Int`, `Float` and `Char`. See [Value representation](/docs/value-representation).

## Closure

A heap object that represents an Elm function value: a pointer to the code, plus the values it has captured or been given so far. Its header records how many arguments it still needs and what kind each slot holds, so the runtime can apply any closure without knowing its type. See [Closures and calls](/docs/closures-and-calls).

## Dialect

A typed intermediate language defined inside MLIR, with its own operations and types. eco's own dialect, `eco`, is the contract between the compiler written in Elm and the backend written in C++. See [The eco dialect](/docs/eco-dialect).

## eco thread

The one thread in each process that runs Elm code and owns the heap. Other threads do IO and background collection, but only the eco thread builds or reads Elm values. See [The runtime](/docs/runtime).

## Fixed point

The state where a compiler, rebuilt from its own source by itself, produces byte-for-byte identical output. eco's bootstrap checks for a fixed point twice, once on the JavaScript-hosted compiler and once on the native one. See [The compiler compiles itself](/docs/bootstrap).

## JIT and AOT

*Just-in-time* compilation turns code into machine code in memory just before running it. *Ahead-of-time* compilation writes an executable to run later. eco's tests use an in-memory JIT, users run the AOT compiler, and the two share all of the backend except the final step. See [The backend](/docs/backend).

## Kernel

A function with no Elm body, implemented by the platform. Stock Elm writes its kernels in JavaScript. eco reimplements them in C++ so that unmodified Elm packages run natively, and adds its own kernels for IO. See [Kernels](/docs/kernels).

## Lambda set

For a place in the program that holds a function, the set of functions that can actually arrive there. When the set has one member, a call through that function value can become a direct call. See [Lambda-set specialization](/docs/lambda-set-specialization).

## LLVM

A widely used compiler backend that optimises a low-level intermediate language and emits machine code for many processors. eco hands LLVM its program after its own passes have lowered it, and uses LLVM's support for precise garbage collection. See [The backend](/docs/backend).

## Lowering

Rewriting a program from a higher-level form into a lower-level one, one step at a time. eco's backend lowers the eco dialect through a series of small passes until only LLVM's own dialect is left. See [Lowering passes](/docs/lowering-passes).

## MLIR

A framework from the LLVM project for defining typed intermediate languages and lowering them step by step toward LLVM. eco's compiler writes its output as MLIR, and the backend reads it. See [MLIR generation](/docs/mlir-generation).

## Model checking

Checking a model of a system by exploring every state it can reach, rather than testing some runs of it. eco model-checks TLA+ models of its collector's concurrency, including deliberately broken variants that must fail. See [Model-checking the collector](/docs/concurrency-models).

## Monomorphization

Making a separate copy of each polymorphic function for each concrete type it is used at, so that every copy knows the size and form of its values. eco monomorphizes the whole program starting from `main`. See [Monomorphization](/docs/monomorphization).

## Mutator

The garbage-collection term for code that allocates objects and changes pointers, as opposed to the collector. In eco the only mutator is the eco thread. See [The garbage collector](/docs/garbage-collector).

## Nursery and eden

The nursery is the young part of eco's heap, collected often. New objects are allocated in eden, part of the nursery, by bumping a pointer. Each minor collection copies eden's survivors into one of a few survivor extents in the same nursery. See [The garbage collector](/docs/garbage-collector).

## Opaque type

A custom type that its module exports without its constructors, so the rest of the program can build and take apart its values only through the module's functions. `elm/bytes`' `Encoder` and `elm/virtual-dom`'s `Node` are opaque. See [Reification](/docs/reification).

## Partial application

A function applied to fewer arguments than it needs, such as `add 1`. In eco the result is a new closure holding the arguments given so far, which runs the function once the rest arrive. See [Closures and calls](/docs/closures-and-calls).

## Reification

Making an existing abstraction concrete in a different way to the original: implementing an opaque type's API differently from its library, with no change any program can observe. eco reifies strings and lists in its runtime, and `elm/bytes` encoders and decoders in its compiler. See [Reification](/docs/reification).

## Safepoint

A point in compiled code where the garbage collector may run. At each safepoint the collector must be able to find every live heap pointer, because it may move the objects they point to. See [The garbage collector](/docs/garbage-collector).

## Specialization

Making a version of a function for one particular use, so it can be compiled with more facts known. Monomorphization specializes by type, and lambda-set specialization specializes calls by which functions can reach them. See [Monomorphization](/docs/monomorphization).

## SSA

Static single assignment: a form of intermediate code in which every value is defined exactly once. MLIR is in SSA form. In eco a value's SSA form can differ from its form at a call or in the heap: a `Bool` is a one-bit integer only in SSA. See [Value representation](/docs/value-representation).

## Staging and arity

A closure's arity is the number of arguments it takes in one application. eco calls each such group of parameters a stage: `\x y -> x + y` has one stage of two, while a function that returns another lambda has two stages of one. See [Closures and calls](/docs/closures-and-calls).

## Statepoint and stack map

A statepoint is LLVM's form of a call at which the collector may run: it records which values are heap pointers and returns their possibly moved addresses. The stack map is the table, emitted into the executable, that tells the collector where those pointers are in each stack frame. See [The backend](/docs/backend).

## Tenuring

Moving an object that has survived young collections into the old generation, also called promotion. eco tenures on a background thread while Elm code keeps running, which is safe without a barrier because neither the original nor its copy is ever written. See [The garbage collector](/docs/garbage-collector).

## TLA+

A language for writing precise models of concurrent and distributed systems, which a model checker can then explore. eco has eight TLA+ models of its collector's concurrency, each tied to the code it describes. See [Model-checking the collector](/docs/concurrency-models).

## Write barrier

Extra code a generational collector adds to every pointer store, to record when an old object comes to point at a young one. eco's collector has none, because an Elm object can never be changed to point at an object younger than itself. See [The garbage collector](/docs/garbage-collector).
