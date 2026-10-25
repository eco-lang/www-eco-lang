---
title: "The compiler compiles itself"
description: "How Eco's Elm-written compiler is carried from the stock Elm compiler, through JavaScript builds of itself, to a single native eco binary, with two fixed-point checks that the compiler rebuilds itself byte for byte."
section: "Getting it right"
sectionOrder: 5
order: 4
---

The Eco compiler is an Elm program, and before Eco exists the only thing that can compile Elm is the stock Elm compiler, which produces JavaScript. So every native `eco` binary descends from a JavaScript one. The bootstrap is the chain of nine stages that makes that journey, and twice along the way it asks the compiler to rebuild itself and checks that the result is identical, byte for byte.

> **Background**
>
> - [Fixed point](/docs/glossary#fixed-point): a compiler that, compiled with itself, produces itself again unchanged.
> - [MLIR](/docs/glossary#mlir): the intermediate form Eco's front end emits and its C++ back end lowers to machine code.
> - [Kernel](/docs/glossary#kernel): code in JavaScript or C++ that implements what Elm itself cannot express, such as reading a file.
> - [Monomorphization](/docs/glossary#monomorphization): making a separate copy of each polymorphic function for every type it is used at.

## The chain

![The bootstrap chain from the stock Elm compiler to one native eco binary, with the JavaScript fixed-point check at stage 4 and the native one at stage 8](/images/docs/bootstrap-chain.svg)

| Stage | Built by | Produces |
|---|---|---|
| 1 | Stock Elm 0.19.1 | The compiler as JavaScript, with input and output done over HTTP to a small Node server |
| 2 | Stage 1 | The compiler as JavaScript, now with input and output through kernels |
| 3 | Stage 2 | The compiler as JavaScript again |
| 4 | Stage 3 | The compiler as JavaScript again, **which must equal stage 3's output** |
| 5 | Stage 3's compiler, after stage 4 passes | The compiler as MLIR, using a lighter specialization engine |
| 6 | The native back end | The first native compiler, lowered from stage 5's MLIR |
| 7 | Stage 6 | The compiler as MLIR with the default engine, and a native compiler lowered from it |
| 8 | Stage 7 | The same again, **which must equal stage 7's compiler** |
| 9 | The native back end, after stage 8 passes | One `eco` binary: stage 7's MLIR linked with the back end |

Each stage declares its inputs and outputs, and each check writes a stamp file that the next stage depends on. Building any stage builds everything before it, and editing any compiler or kernel source reruns the chain from the first stage that reads it. The chain trusts exactly one prebuilt binary: the stock Elm compiler, downloaded at a pinned version and checked against a recorded hash. No prebuilt Eco compiler is ever fed back in.

## Stages 1 and 2: escaping stock Elm

The compiler reads files and writes to the console through a handful of its own modules. Two source trees supply those modules under the same names. Stock Elm will link kernel code only from the Elm project's own packages, so a compiler built by stock Elm cannot touch the file system. The first tree works around that in plain Elm, sending every file operation as an HTTP request that a small Node server answers. The second tree implements the same modules as kernels: JavaScript in the JavaScript stages and C++ in the native ones.

Stage 1 builds the compiler with the HTTP tree. Stage 2 has that compiler build the compiler again with the kernel tree, and from then on nothing needs the server. Two compiler features exist mainly for this hop: compiling a package whose kernel code belongs to an author other than the Elm project, and taking a package from a directory on disk instead of the package registry.

Stage 1 is the only stage built without optimization. The HTTP tree's crash function uses Elm's placeholder for unfinished code, `Debug.todo`, which optimized builds forbid. Dropping optimization in one throwaway stage was cheaper than maintaining a workaround.

## The JavaScript fixed point

Stages 3 and 4 each have the newest compiler build itself once more, and stage 4 compares the two results:

```cmake
# -- Stage 4b: JS fixed-point check (eco-boot-2.js == eco-boot-3.js)
set(ECO_BOOT_VERIFY_STAMP "${CMAKE_CURRENT_BINARY_DIR}/eco-boot-verify.stamp")

add_custom_command(
    OUTPUT ${ECO_BOOT_VERIFY_STAMP}
    COMMAND ${CMAKE_COMMAND} -E compare_files ${ECO_BOOT_2_OUTPUT} ${ECO_BOOT_3_OUTPUT}
    COMMAND ${CMAKE_COMMAND} -E touch ${ECO_BOOT_VERIFY_STAMP}
    DEPENDS ${ECO_BOOT_2_OUTPUT} ${ECO_BOOT_3_OUTPUT}
    COMMENT "Stage 4b: JS fixed-point check (eco-boot-2.js == eco-boot-3.js)"
)
```

From the compiler's build file. If two generations are identical, the compiler's output no longer depends on which compiler built it. This check covers everything written in Elm: parsing, type checking, optimization and JavaScript generation. Stage 5 depends on the stamp, so no MLIR is produced by a JavaScript compiler that has not reproduced itself. Without that explicit edge the build tool would be free to start stage 5 as soon as stage 3's output existed, racing past the check.

## Stage 5: staying inside Node's heap

Every part of Eco that emits MLIR is Elm source, so the first MLIR the compiler ever produces has to come from the compiler running as JavaScript under Node. That self-compile is the heaviest step of the Node half of the chain, and it runs close to the largest heap V8 allows, 16 GB.

Running out of heap does not crash the compile. As it nears the limit, V8 spends more and more of its time collecting garbage to stay under it, and the compile slows until it never finishes. Several times, an optimisation that made the native compiler better has pushed this stage to that edge.

So the chain takes precautions. Every Node-hosted stage sets V8's heap to its 16 GB maximum. Stage 5 uses the lighter of the compiler's two specialization engines, which fits comfortably, because its only job is to produce a *correct* first native compiler; its MLIR is less optimized, but nothing that ships is built from it. And for as long as Eco can be bootstrapped from stock Elm through Node, which we intend to keep, any new optimisation has to leave this stage inside 16 GB, even if that means switching the optimisation off here.

Stage 5 also deletes the cached typed module files that specialization reads, because the JavaScript stages neither write nor invalidate them, and a stale one crashes specialization.

## The native fixed point

Stage 6 lowers stage 5's MLIR into the first native compiler. Stage 7 has it emit the compiler again, now on the native host where Node's heap limit no longer applies, so it uses the default, heavier engine, and lowers that MLIR into a second native compiler. Stage 8 repeats the step and compares.

The native rounds see what the JavaScript ones cannot: the MLIR generator, the lowering passes, the runtime, the garbage collector and the C++ kernels all take part in a native self-compile. The bootstrap's failure log records bugs found there that no JavaScript stage could reach, such as stale nursery pointers after a change to the pass that rewrites calls so the collector can find roots, and heap corruption while encoding bytes.

On Linux stage 8 compares the two executables. On macOS and Windows the linkers embed timestamps or build identifiers, so the stage compares the two compilers' MLIR output instead, which states the same fact without depending on the linker. Either way the check needs every step to be deterministic: the compiler, its MLIR output and, on Linux, the linker must produce the same bytes from the same input.

## Stage 9: one binary, checked by use

Until stage 9, compiling a program takes two tools: the native compiler, which emits MLIR, and the back end, which lowers MLIR to an executable. Stage 9 lowers stage 7's MLIR, the version whose compiler passed stage 8, and links it with the back end into one `eco` binary, so a user installs one tool. It starts only after stage 8 has passed.

`eco` then compiles the compiler once, and the stage succeeds if that works. It does not compare the result with `eco` itself. Only `eco` embeds the LLVM and MLIR back end, so it and any compiler it produces differ by construction, and a byte comparison could never pass. The real native fixed point is stage 8's, on compilers that do not embed the back end.

## Tests inside the chain

Two end-to-end test suites run at the earliest stage that can run them. The JIT suite needs only the stage 1 compiler. The AOT suite needs the stage 3 compiler and the native back end, so it can run right after the JavaScript fixed point. A native self-compile takes tens of minutes, so run in this order a back-end regression is reported before the expensive native rounds start, and is pinned to the few stages before the gate that caught it. A separate check compiles every test program with the stage 2 JavaScript compiler and the stage 6 native compiler and compares the MLIR byte for byte; any difference is a bug in one of them.

> **Designs we didn't use.** We did not check a prebuilt Eco compiler into the repository to start from: the chain would then trust a binary nobody can rebuild from source.

## Further reading

- [The build driver](/docs/build-driver) — what `eco make` does at each of these stages.
- [The backend](/docs/backend) — the native back end that lowers MLIR from stage 6 on.
- [Kernels](/docs/kernels) — the paired JavaScript and C++ kernels that let the same compiler run on both hosts.
- [How we know it works](/docs/verification) — the other test layers, and how the fixed points fit among them.
- The full design document: [Bootstrap theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/workflow/bootstrap.md)
- Source: [`compiler`](https://github.com/eco-lang/eco-compiler/tree/master/compiler)
