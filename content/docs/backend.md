---
title: "The backend"
description: "How Eco's C++ backend turns the compiler's eco-dialect module into a native executable or in-memory code, with exact garbage-collector roots and parallel code generation."
section: "The backend"
sectionOrder: 3
order: 1
---

The backend takes the program the Elm-written compiler hands over and turns it into machine code. It makes no decisions about what a value means; the compiler has settled that. What it decides is how to make the code safe for a collector that moves objects, and how to produce code fast when the program is the Eco compiler itself, a single module of tens of thousands of small functions.

> **Background**
>
> - [MLIR](/docs/glossary#mlir) — a compiler framework in which a program is a set of typed operations grouped into [dialects](/docs/glossary#dialect).
> - [Lowering](/docs/glossary#lowering) — rewriting operations into simpler ones closer to the machine.
> - [Safepoint](/docs/glossary#safepoint) — a point where the collector may run; [statepoints and stack maps](/docs/glossary#statepoint-and-stack-map) record where the heap pointers are at each one.
> - [JIT and AOT](/docs/glossary#jit-and-aot) — compiling in memory and running at once, versus writing a binary to disk.

## One fixed sequence

Every module takes the same path, whichever tool asked for it.

![The path of one module through the backend](/images/docs/backend-pipeline.svg)

The compiler writes the module as MLIR bytecode and calls the backend, which lives in the same `eco` executable. The backend loads the module and checks it against [the eco dialect](/docs/eco-dialect), the typed contract between the two halves. About twenty [lowering passes](/docs/lowering-passes) then rewrite it into LLVM's own dialect, each placed where the fact it needs becomes decidable. The module is split into partitions, LLVM compiles each partition on its own thread, and a link step joins the objects with the prebuilt runtime and kernel libraries.

The product compiler, the bootstrap compiler, a developer tool and the test JIT all compile through one shared routine. Separate copies drifted: one tool set the data layout before rewriting statepoints and another after, and programs behaved differently depending on which tool built them. Now the tools differ only in what they do with the finished code.

## Finding every heap pointer

Eco's collector moves objects. At every call that might collect, it must know each stack slot and register holding a heap pointer, and be able to replace it with the object's new address. Eco gets this from LLVM rather than computing it by hand. Every boxed value is lowered to a pointer in a separate address space, which Eco's collector strategy marks as garbage-collected memory, and LLVM's statepoint pass works out from liveness which of those pointers survive each call.

A test fixture shows the effect (trimmed). `%root` is live across two calls that may allocate:

```mlir
func.func @test_loop_root(%root: !eco.value, %other: !eco.value) -> !eco.value {
  %r1 = "eco.call"(%root) <{callee = @alloc_thing}> : (!eco.value) -> !eco.value
  %r2 = "eco.call"(%r1) <{callee = @alloc_thing}> : (!eco.value) -> !eco.value
  "eco.return"(%root) : (!eco.value) -> ()
}
```

Nothing in the input mentions roots. In the LLVM output each call becomes a `gc.statepoint`, and `%root` comes back from each through `gc.relocate`, so the value returned is the twice-relocated pointer. The stack maps go into a section of each object file that the collector reads from the running image, so every link step must keep it.

One danger follows. Compiled code sometimes reads a heap pointer as an integer, to test a tag bit; if that integer is used after a statepoint, it is stale. So Eco places statepoints *before* LLVM's optimizer, not after it as LLVM intends, and until then writes such conversions in a form LLVM cannot fold away.

## Whole-program facts first, then split

Some facts need the whole program: which functions can ever run, which can never trigger a collection (so their calls need no statepoint), and where a callee's allocation check can move into its caller. All three are decided in MLIR, before the split, and travel into each partition as attributes that the partition checks again. They must be decided in MLIR because an MLIR context can be shared between threads and an LLVM context cannot: deciding them after translation would need every worker to see every other partition.

The splitter gives each function one owner, balancing partitions by operation count; elsewhere it appears only as a declaration. Losing inlining across partitions measures within noise on the compiler's run time. The analyses assume a closed world: an executable exposes only its entry point, so no outside caller can break them.

## What comes out

The output follows the file name: `.o` stops after code emission, `.so` or `.node` gives a shared library or Node addon with a small embedding interface (start a program, send to and subscribe to ports), and any other name links an executable. Elm code still runs on one thread that owns the heap; host threads only queue messages.

Users unpack a bundle and run `eco make` with no toolchain installed, so the link uses nothing from the host. On Linux, executables link statically against musl with a bundled LLVM linker; shared libraries use a second set of archives built for glibc, since a static musl object cannot load into a Node process. macOS and Windows have their own link paths.

The JIT compiles in memory through the same routine, which is how thousands of end-to-end tests run without linking. It must register the stack maps and unwind tables of each object it loads, because the collector finds roots by walking the stack.

## Built for compile time

On the compiler's own source the backend takes about twenty seconds. What makes it fast: no repeated linear symbol lookups, partitions compiled in parallel, splitting done in MLIR so translation also runs per partition, and MLIR passes run in parallel. The total CPU time is several minutes, spread across many cores.

> **Designs we didn't use.** Escape analysis as a pass over the lowered MLIR, to keep values out of the heap, allocated more, not less, because at that level nearly everything looks as if it escapes. The compiler decides which values stay out of the heap instead, while it still knows the program's structure.

## Further reading

- [The eco dialect](/docs/eco-dialect) — the operations and types the backend accepts, and what its verifier checks.
- [Lowering passes](/docs/lowering-passes) — the twenty or so passes, and why each sits where it does.
- [Value representation](/docs/value-representation) — how a boxed value is encoded in one word.
- [The garbage collector](/docs/garbage-collector) — the collector that reads the stack maps.
- The full design document: [The backend theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/backend/backend.md), and for the drivers, [native drivers theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/backend/native-drivers.md)
- Source: [`runtime/src/codegen`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/codegen)
