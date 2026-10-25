---
title: "Bytes fusion"
description: "How Eco compiles elm/bytes encoders and decoders whose shape it can read at compile time into code that writes or reads the buffer directly, and falls back to the elm/bytes kernel for everything else."
section: "The compiler"
sectionOrder: 2
order: 8
---

In elm/bytes an encoder is a value: a tree that describes what to write. The library builds that tree, walks it once to find the total size, and walks it again to write the bytes. When Eco can read the shape of an encoder from the program, it skips the tree: it works out the exact size, allocates the buffer once, and writes each value straight into it. Decoders get the same treatment. Anything Eco cannot read stays a call to the elm/bytes kernel, which is always correct.

> **Background**
>
> - A [kernel](/docs/glossary#kernel) is a built-in library function implemented in C++ rather than Elm; elm/bytes' encode and decode are kernels on the native path ([Kernels](/docs/kernels)).
> - A [dialect](/docs/glossary#dialect) is a family of MLIR operations. Fused code is written in a small dialect of its own, `bf`.
> - [Lowering](/docs/glossary#lowering) turns operations of one dialect into lower-level ones, here into loads, stores and calls to runtime helpers.

## An encoder, fused

```elm
encodeRgb : Int -> Int -> Int -> Bytes
encodeRgb r g b =
    E.encode (E.sequence [ E.unsignedInt8 r, E.unsignedInt8 g, E.unsignedInt8 b ])
```

This is the MLIR Eco emits for it. The listing is trimmed: operand types are removed, and so are the seven lines before it that still build the `Encoder` value (three `U8` constructors and a list), which nothing uses:

```mlir
      ^bb0(%r: i64, %g: i64, %b: i64):
        ...
        %10 = "arith.constant"() {value = 3 : i32} : () -> i32
        %11 = "bf.alloc"(%10) : (i32) -> !eco.value
        %12 = "bf.cursor.init"(%11) : (!eco.value) -> !bf.cursor
        %13 = "bf.write.u8"(%12, %r) : (!bf.cursor, i64) -> !bf.cursor
        %14 = "bf.write.u8"(%13, %g) : (!bf.cursor, i64) -> !bf.cursor
        %15 = "bf.write.u8"(%14, %b) : (!bf.cursor, i64) -> !bf.cursor
        "eco.return"(%11) : (!eco.value) -> ()
```

The size, 3, is a constant. One allocation gives a buffer of exactly that size, a cursor is placed at its start, and each write takes the cursor and returns the advanced one, so the order of the writes is explicit in the data flow. The unused `Encoder` construction does not survive into the executable: those operations have no effects, and the backend removes them as dead code. The x86-64 code the 0.2.0 compiler produces for `encodeRgb` allocates only the buffer and stores three bytes (trimmed: register saves removed):

```text
mov    $0x3,%edi
call   elm_alloc_bytebuffer
...
call   elm_bytebuffer_data
...
mov    %r15b,(%r12)
mov    %r14b,0x1(%r12)
mov    %bl,0x2(%r12)
```

Wider and mixed writes fuse the same way. An encoder of one `unsignedInt8` and two `unsignedInt16 BE` becomes `bf.alloc` of 5 bytes, one `bf.write.u8` and two `bf.write.u16` with `endianness = 1`.

## Size first, then one buffer

An encoder fuses from fixed-width integer and float writes, copies of a `Bytes` value, UTF-8 strings, `sequence` of a literal list, and one list idiom: `sequence (unsignedInt32 e (List.length xs) :: List.map f xs)`, where `f` reads as fixed-width writes. Before allocating, the fused code adds up the size. Fixed-width writes contribute constants, which are folded together. Each part whose width varies adds one term at run time: a string's UTF-8 width, a `Bytes` value's length, or the list length times the item width.

Knowing the size first gives one buffer, with no growth and no copying. It also removes the bounds checks. Every write was counted in the size, so a write can only run past the end if the count left it out.

A subtree that cannot be read, typically a function parameter used as the encoder for each element, does not send the whole encoder back to the kernel. It becomes an *opaque leaf*: an ordinary `Encoder` value, sized and written at the cursor by thin wrappers over the kernel's own size and write routines. Only that subtree goes through the kernel's walker. Everything else stays fused, in one buffer whose bytes agree with the kernel's byte for byte. An encoder that is nothing but one opaque leaf is left as a kernel call, because an allocation plus one walk costs more than calling the kernel.

## A decoder, fused

The decoder side fuses a count loop, the usual way to read a known number of items:

```elm
D.decode
    (D.loop ( 3, [] )
        (\( n, acc ) ->
            if n <= 0 then
                D.succeed (D.Done acc)

            else
                D.map (\x -> D.Loop ( n - 1, x :: acc )) D.unsignedInt8
        )
    )
    bytes
```

The output checks all the bytes the loop needs once, then reads one byte per step with no further check (trimmed: operand types and the overflow guard on the length removed):

```mlir
%29 = "bf.decoder.cursor.init"(%0) : (!eco.value) -> !bf.cursor
...
%38 = "bf.require"(%29, %37) : (!bf.cursor, i32) -> i1
...
%23 = "scf.if"(%39) ({
      %40 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value
      %53, %54, %55 = "scf.while"(%32, %29, %40) ({
          ^bb0(%41: i64, %42: !bf.cursor, %43: !eco.value):
            %44 = "arith.cmpi"(%41, %31) {predicate = 4 : i64} : (i64, i64) -> i1
            "scf.condition"(%44, %41, %42, %43) : (i1, i64, !bf.cursor, !eco.value) -> ()
      }, {
          ^bb0(%45: i64, %46: !bf.cursor, %47: !eco.value):
            %48, %49 = "bf.read.u8"(%46) : (!bf.cursor) -> (i64, !bf.cursor)
            %50 = "arith.constant"() {value = 1 : i64} : () -> i64
            %51 = "arith.subi"(%45, %50) : (i64, i64) -> i64
            %52 = "eco.construct.list"(%48, %47) {head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value
            "scf.yield"(%51, %49, %52) : (i64, !bf.cursor, !eco.value) -> ()
      }) : (i64, !bf.cursor, !eco.value) -> (i64, !bf.cursor, !eco.value)
      %56 = "eco.construct.custom"(%55) {constructor = "Just", size = 1, tag = 0} : (!eco.value) -> !eco.value
      "scf.yield"(%56) : (!eco.value) -> ()
}, {
      %57 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value
      "scf.yield"(%57) : (!eco.value) -> ()
}) : (i1) -> !eco.value
```

One `bf.require` covers `count × width` bytes, which is valid because every item has the same width. If it fails, the result is the embedded `Nothing` constant (`eco.constant` kind 2, the word shared by `Nothing`, `[]` and unit). If it passes, the loop reads, counts down and conses each byte onto the accumulator, and the result is wrapped in `Just`. A loop that stops at a sentinel value does not know its length, so it checks before each item instead.

The listing shows only the fused path. Just before it, the compiler still emits a call that builds the `Decoder` value for the loop, which nothing then uses. Unlike the encoder's leftover constructors, that call is not removed and appears in the native code. It is a small piece of wasted work, and we have not yet eliminated it.

## Decoders: whole or not at all

An encoder can be fused around an opaque part because the kernel's writer can write one subtree into the middle of a buffer. There is no way to hand the middle of a decode to the kernel and carry on, so a decoder fuses whole or not at all.

Fewer decoders fuse today than the recogniser has patterns for. It has patterns for `map` through `map5`, `andThen`, `succeed`, `fail` and length-prefixed strings. But by the time fusion runs, a decoder that takes arguments, such as `unsignedInt16 BE` or `string n`, has already been inlined into a hand-built decoder around a kernel read, and the recogniser does not read that form. In practice that leaves decoders built from argument-free reads such as `unsignedInt8`; our benchmark suite found nothing wider fusing. Even `D.map3 (\r g b -> ( r, g, b )) D.unsignedInt8 D.unsignedInt8 D.unsignedInt8` stays a call to the kernel in the 0.2.0 compiler, because the inliner has already turned the `map3` into a closure the recogniser does not read. In our view the next step is to teach the recogniser those inlined forms, rather than to hold back the inliner, because the inliner is what lets fusion see through helpers at all.

## The kernel is the reference

Fusion takes its correctness from the kernel. It replaces a call only when what it has read describes the whole encoder or decoder, and every case it does not recognise already has a correct answer: leave the call alone. A missed shape costs speed, never a wrong result. Elm values are immutable and expressions have no effects, and that is what lets fused code evaluate a value at a different point from the source, or twice, and get the same value.

Fused code and the kernel agree on failure: both give `Nothing` for the whole decode on any failing read, and both use the same strict UTF-8 validator. They get there differently. The kernel's decode interpreter throws from the failing read and catches the exception at the top of the decode. Fused code has no combinators to unwind, so it branches: each read sits inside the branch where its check passed, and the failure branch yields `Nothing`, throwing nothing and allocating nothing.

Recognition matches elm/bytes by package, module and function name, and nothing else. It never matches a project's own helper names. Helpers are reached by inlining instead: the inliner always unfolds the elm/bytes combinators and the compiler's own bytes helpers, so that they dissolve into the calls, list literals and `List.map` the recogniser reads.

## The bf dialect

The dialect's one type, `!bf.cursor`, is a position in a buffer, held as two plain pointers: the current position and the end. Its 30 operations allocate a buffer, read and write fixed-width values, copy bytes and UTF-8 strings, compute the run-time widths an encoder's size needs, check bounds, and hand an opaque `Encoder` to the kernel's walker. Reads are unchecked loads, and `bf.require` is a separate operation, so that one check can cover many reads, as in the count loop.

Generated code never computes an address inside a buffer or string header. It calls runtime helpers for a buffer's length and data pointer, a string's UTF-8 width, and strict UTF-8 decoding. Byte buffers and strings each have several internal forms, and because only the helpers know them, adding a form changes only the helpers. [Runtime data structures](/docs/data-structures) describes those forms.

We keep the dialect separate from eco for two reasons: the eco dialect stays stable, and fusion can be switched on or off without touching it. The two meet only at heap values.

## The cursor and the collector

A cursor is a raw pointer into a heap object, and heap objects move. A buffer smaller than 8 KiB lives in the nursery, which a minor collection copies ([The garbage collector](/docs/garbage-collector)). The machinery that relocates pointers across a collection only tracks pointers it knows are heap pointers, and the cursor is not one of them. Fused code can trigger a collection while a cursor is live: an encoder may call a function to compute a value it writes, and reading a `Bytes` value or a string allocates the result.

The lowering of `bf` handles this. Around every point that may collect while a cursor is live, it records the cursor's offset from the buffer's start, and afterwards rebuilds the cursor from the buffer, which the collector does track and relocate. A check then rejects the function at compile time if any use of a cursor can still be reached from its definition through such a point. That is not quite enough for an encoder that keeps writing after a collection, because the collector may copy a surviving object to the old generation on the assumption that nothing writes to it any more. A buffer written after such a point is therefore marked as a *builder*, which the collector keeps young until its last write.

In the common case none of this costs anything. A fused decode loop builds a list cell per item, but a later backend pass turns those cells into pushes onto a scratch stack that cannot collect and builds the list after the loop, so the loop has no point that may collect and its cursor is never rebuilt.

## What it is worth

Our benchmark suite has a pair of workloads that do the same work: encode a list of bytes, then decode it with a count loop over `unsignedInt8`. In `bytes-static` the decoder is known at compile time and fuses. In `bytes-dynamic` the item decoder is chosen at run time, so it does not. On Eco native, `bytes-static` takes 27 ms and `bytes-dynamic` 71 ms, so decoder fusion is worth 2.6x. Stock Elm's JavaScript takes about 245 ms and 240 ms for the two, because it treats them alike.

These are medians of 11 runs after 3 warm-ups, from a development build of the native compiler. Eco's times come from a 1 ms `Time.now`, so small figures are coarse. Both workloads also generate and encode the data, so the fused decoder's own speed-up is larger than the ratio of the totals.

> **Designs we didn't use.** Matching a project's own helpers by name, such as the compiler's list encoder, would fuse more of the compiler at once, but it would tie fusion to one codebase. We inline the helpers instead, and fusion matches what they unfold into.

## Further reading

- [MLIR generation](/docs/mlir-generation) — fusion is one of the specialised emitters layered on the core generator.
- [Lowering passes](/docs/lowering-passes) — where the `bf` lowering runs among the other passes.
- [Kernels](/docs/kernels) — the elm/bytes kernel that fusion falls back on.
- [The garbage collector](/docs/garbage-collector) — the nursery and the tenuring that the cursor has to survive.
- [Performance](/docs/performance) — the rest of the benchmark suite, wins and losses.
- The full design document: [Bytes fusion theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/bytes-fusion.md)
- Source: [`compiler/src/Compiler/Generate/MLIR/BytesFusion`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Compiler/Generate/MLIR/BytesFusion) and [`runtime/src/codegen/BF`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/codegen/BF)
