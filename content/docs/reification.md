---
title: "Reification"
description: "How eco gives an Elm library type a different implementation from the library's own without changing anything a program can observe: string and list layouts in the runtime, elm/bytes encoders compiled to buffer writes, and where the technique could go next."
section: "Introduction"
sectionOrder: 1
order: 7
---

An Elm module can export a type without its constructors, so that the rest of the program reaches its values only through the functions the module provides. That separates an API from its implementation, and it leaves eco free to implement the same API another way. We call this *reification*: taking an existing abstraction and making it concrete in a different way to the original. eco reifies strings and lists in its runtime, and `elm/bytes` encoders and decoders in its compiler. No program can tell the difference, except by how fast it runs.

> **Background**
>
> - An [opaque type](/docs/glossary#opaque-type) is a custom type exported without its constructors, so only its own module can build or take apart its values.
> - A [kernel](/docs/glossary#kernel) is a library function with no Elm body. eco implements Elm's kernels in C++ ([Kernels](/docs/kernels)).
> - A [dialect](/docs/glossary#dialect) is a family of MLIR operations; bytes fusion writes its output in one of its own.

The word has other uses in programming languages, most often for turning something implicit into a value a program can hold. Ours can run the other way: bytes fusion turns a value, an encoder, into code.

## Strings: one type, several layouts

In stock Elm a `String` is a JavaScript string. In eco it has six heap forms, among them a flat UTF-16 array, a compact form for ASCII text, a slice that shares another string's buffer, and a rope that joins two strings without copying either. The API is unchanged. `String.slice` on a long string now shares instead of copying, and repeated `++` on long strings no longer copies quadratically, but every form of a string compares, orders and prints the same as every other.

The runtime chooses a form for each string it builds. Kernels reach strings only through a small interface, so adding a form changes kernels only where they create strings. [Runtime data structures](/docs/data-structures) describes the forms and how the runtime chooses between them.

## Lists: chunks behind the constructors

`List` is not opaque: `[]` and `::` are its constructors, and any program can match on them. Its layout is still hidden, because a match is the only way to look inside a list, and the compiler writes every match. eco's lists can mix 24-byte cons cells with *chunk views* over dense arrays, which bulk operations such as `reverse` and `append` produce, and compiled code tests which one it holds before taking a head or a tail. On the compiler compiling itself, chunked lists cut the number of cons cells by roughly half.

## Encoders: a value becomes code

Strings and lists change how values are stored. Bytes fusion goes further and changes what the program does. In `elm/bytes` an `Encoder` is an opaque value, a tree that describes what to write, which the library walks twice: once to size the buffer and once to fill it. Since a program can only hand the tree to `encode`, nothing depends on the tree being built at all.

```elm
encodeRgb : Int -> Int -> Int -> Bytes
encodeRgb r g b =
    E.encode (E.sequence [ E.unsignedInt8 r, E.unsignedInt8 g, E.unsignedInt8 b ])
```

Where the compiler can read an encoder's shape from the program, it works out the size, allocates the buffer once and writes each value straight into it (trimmed):

```mlir
%11 = "bf.alloc"(%10) : (i32) -> !eco.value
%12 = "bf.cursor.init"(%11) : (!eco.value) -> !bf.cursor
%13 = "bf.write.u8"(%12, %r) : (!bf.cursor, i64) -> !bf.cursor
%14 = "bf.write.u8"(%13, %g) : (!bf.cursor, i64) -> !bf.cursor
%15 = "bf.write.u8"(%14, %b) : (!bf.cursor, i64) -> !bf.cursor
```

Decoders get the same treatment, and on our benchmark suite a fused decoder makes a byte-decoding workload 2.6 times faster. Bytes fusion is the largest use of the technique in eco, and [Bytes fusion](/docs/bytes-fusion) covers it in full: how sizes are computed, why decoders fuse whole or not at all, and how a cursor survives the garbage collector.

## The original stays the reference

Every reification in eco keeps the original implementation as both its reference and its fallback. Anything bytes fusion cannot read stays a call to the `elm/bytes` kernel, which is always correct, so a shape it misses costs speed, never a wrong result. In the runtime, tests run every string operation on every form, and the answers must agree.

Immutability is what makes the technique safe. A slice can share another string's buffer, and fused code can compute a value at a different point from the source, only because no Elm value ever changes once it is built.

## Where it could go next

The technique applies wherever a library hides its representation behind a custom type, and Elm's libraries do that often. Two candidates stand out. Neither is built.

`Vec4` and the other vector and matrix types of `elm-explorations/linear-algebra` are opaque, and their kernels build each one in the browser as a small `Float64Array`. Native code could keep a `Vec4` as four floats in registers instead, and compile arithmetic on it inline, rather than allocate a heap object for every result.

`Html` is built from `VirtualDom.Node`, which is also opaque. A WebAssembly build of an Elm application could build and diff the virtual DOM in its own heap and send the browser only the patches, with no change to programs written against `elm/html`. The open question there is what it costs to cross from WebAssembly into the browser's DOM, which every patch has to do.

> **Designs we didn't use.** A faster representation could instead be offered as a new API, such as a mutable buffer type, for programmers to opt into. That would split programs and packages into those that use it and those that do not. Reification gives the speed to unmodified Elm code.

## Further reading

- [Bytes fusion](/docs/bytes-fusion) — the compiler's largest reification, in full.
- [Runtime data structures](/docs/data-structures) — the string and list forms, and how the runtime chooses between them.
- [Kernels](/docs/kernels) — the C++ implementations that reified code falls back on.
- Source: [`compiler/src/Compiler/Generate/MLIR/BytesFusion/Reify.elm`](https://github.com/eco-lang/eco-compiler/blob/master/compiler/src/Compiler/Generate/MLIR/BytesFusion/Reify.elm)
