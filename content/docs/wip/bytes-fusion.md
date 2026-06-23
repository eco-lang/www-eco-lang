---
title: "Bytes Fusion"
description: "How eco eliminates interpreter overhead from Elm's Bytes.encode and Bytes.decode by fusing combinator chains into direct cursor operations at compile time."
section: "Compilation"
sectionOrder: 3
order: 5
---

## The Problem

Elm's `Bytes.Encode` and `Bytes.Decode` modules use an interpreter-style design. You build a description of the operation using combinators, and then a runtime interpreter walks that description to perform the actual encoding or decoding:

```elm
encoder : Encoder
encoder =
    Bytes.Encode.sequence
        [ Bytes.Encode.unsignedInt32 BE 42
        , Bytes.Encode.float64 LE 3.14
        , Bytes.Encode.string "hello"
        ]
```

In the standard Elm runtime (JavaScript), calling `Bytes.Encode.encode encoder` does two things:

1. **Builds a data structure**: each combinator allocates an encoder node (a closure or record) describing what to write.
2. **Interprets that data structure**: the runtime walks the encoder tree, dispatching on each node type to perform the actual byte writes.

This has overhead: intermediate allocations for the encoder/decoder tree, dispatch overhead for each node, and multiple passes over the structure (one to compute size, one to write). For a compiled native language, this is unnecessary work.

## Why Fusion Is Possible

The `elm/bytes` API has a crucial property: **it's an opaque DSL builder**. Encoders and decoders are opaque types: user code can construct them via combinator functions (`unsignedInt32`, `sequence`, `map2`, etc.) but **cannot inspect or destructure** the resulting values.

This opacity is the key insight. Because the API is sealed:

- The compiler can see the full construction chain at compile time (it's just a series of known function calls).
- User code cannot observe the intermediate encoder/decoder values, so the compiler is free to eliminate them entirely.
- The construction-then-interpretation pipeline can be replaced with direct operations, and no Elm code can tell the difference.

In other words, the Bytes API is a **compile-time-visible DSL** even though it's sealed at runtime. The compiler recognizes the combinator calls, understands what byte operations they describe, and generates direct code that skips the interpreter entirely.

## The Solution: Compile-Time Fusion

Bytes Fusion intercepts `Bytes.encode` and `Bytes.decode` calls during [MLIR generation](/docs/code-generation) and replaces the interpreter pipeline with fused cursor-based operations:

```
Without fusion:
  1. Build encoder tree (allocations)
  2. Walk tree to compute total size
  3. Allocate buffer
  4. Walk tree again to write bytes

With fusion:
  1. Compute size at compile time (when possible)
  2. Allocate buffer
  3. Write bytes directly via cursor operations
```

The fused path has zero intermediate allocations, no dispatch overhead, and the buffer size is often known at compile time.

## Two Phases

The fusion pipeline has two phases:

### Phase 1: Reification

The **reifier** pattern-matches the monomorphized AST to recognize encoder and decoder combinator calls. Each recognized pattern becomes a node in a simple tree:

For encoders:
```
unsignedInt8 value    →  EU8 value
unsignedInt32 BE value →  EU32 BigEndian value
float64 LE value      →  EF64 LittleEndian value
string text           →  EUtf8 text
bytes blob            →  EBytes blob
sequence [a, b, c]    →  [reify(a), reify(b), reify(c)]
```

For decoders, the tree captures the full decoding pipeline including `map`, `map2`, `andThen`, and loop combinators. Variable bindings are resolved through an expression cache: if a decoder is bound to a `let` variable and referenced later, the reifier traces through the binding.

If any combinator is unrecognized or the pattern is too complex (e.g., a decoder constructed dynamically), reification fails and the compiler falls back to the normal kernel call. Fusion is an optimization, not a requirement, and correctness is guaranteed either way.

### Phase 2: Emission

The **emitter** generates MLIR operations from the reified node tree using a custom **BF (ByteFusion) dialect**:

For an encoder:
1. Compute the total buffer width (sum of all write sizes).
2. Emit `bf.alloc` to allocate the buffer.
3. Emit `bf.init_write_cursor` to create a cursor positioned at the start.
4. For each encoder node, emit the corresponding `bf.write_*` operation, threading the cursor through each operation (SSA-style: each write returns a new cursor).
5. Return the buffer.

For a decoder:
1. Emit `bf.init_read_cursor` on the input bytes.
2. For each decoder node, emit `bf.require` (bounds check) followed by the `bf.read_*` operation.
3. Thread the cursor through all operations.
4. Wrap the result in `Maybe` (Just on success, Nothing if bounds check fails).

## The BF Dialect

The BF dialect is a custom MLIR dialect for cursor-based byte operations. The core type is `!bf.cursor`, a pair of pointers `(current_ptr, end_ptr)` that tracks position in a byte buffer.

**Write operations** advance the cursor and return a new one:

```
bf.write_u8    cursor, value          → new_cursor    (1 byte)
bf.write_u16   cursor, value {BE/LE}  → new_cursor    (2 bytes)
bf.write_u32   cursor, value {BE/LE}  → new_cursor    (4 bytes)
bf.write_f64   cursor, value {BE/LE}  → new_cursor    (8 bytes)
bf.write_utf8  cursor, string         → new_cursor    (variable)
```

**Read operations** return the value and a new cursor:

```
bf.read_u8     cursor                 → value, new_cursor
bf.read_u16    cursor {BE/LE}         → value, new_cursor
bf.read_f64    cursor {BE/LE}         → value, new_cursor
bf.read_bytes  cursor, length         → bytes, new_cursor
```

The cursor threading is SSA-style: each operation consumes a cursor and produces a new one. This makes the data flow explicit and enables MLIR's optimization passes to reason about the sequence of operations.

## Static Width Computation

When all encoder elements have known sizes, the total buffer size is computed at compile time:

| Element | Width |
|---------|-------|
| `unsignedInt8` / `signedInt8` | 1 byte |
| `unsignedInt16` / `signedInt16` | 2 bytes |
| `unsignedInt32` / `signedInt32` | 4 bytes |
| `float32` | 4 bytes |
| `float64` | 8 bytes |
| `string` / `bytes` | dynamic |

For the example at the top of this page: `unsignedInt32` (4) + `float64` (8) + `string` (dynamic). If the string length is unknown, a `bf.width` operation queries it at runtime. When all widths are static, the buffer is allocated at its exact size, with no reallocation or growth needed.

## Loop Support

Decoder loops are recognized in two forms:

**Count loops**: When the number of iterations is known (from a previously decoded value or a constant), the loop runs a fixed number of times:

```elm
-- Decode 10 unsigned 32-bit integers
Bytes.Decode.loop (10, []) (\(remaining, acc) ->
    if remaining == 0 then Done (List.reverse acc)
    else Bytes.Decode.map (\v -> Loop (remaining - 1, v :: acc))
            (Bytes.Decode.unsignedInt32 BE)
)
```

**Sentinel loops**: When the loop terminates on a sentinel value (e.g., a zero byte marking end of data), the loop checks each decoded value against the sentinel.

Both forms are lowered to structured control flow loops (`scf.while`) in MLIR with cursor threading through the loop body.

## Example: Fused Encoder

Given this Elm encoder:

```elm
encodePoint : Int -> Int -> Encoder
encodePoint x y =
    Bytes.Encode.sequence
        [ Bytes.Encode.unsignedInt32 BE x
        , Bytes.Encode.unsignedInt32 BE y
        ]
```

Without fusion, this builds a sequence node containing two `unsignedInt32` nodes, then interprets the tree to write 8 bytes.

With fusion, the compiler generates:

```
1. bf.alloc 8                          -- exact size known at compile time
2. cursor₀ = bf.init_write_cursor buf
3. cursor₁ = bf.write_u32 cursor₀, x {BE}
4. cursor₂ = bf.write_u32 cursor₁, y {BE}
5. return buf
```

No intermediate data structures. No interpreter dispatch. Two direct memory writes into a pre-sized buffer.

## LLVM Lowering

The BF dialect is lowered to LLVM by `BFToLLVM.cpp`:

- `!bf.cursor` becomes an `{ i8*, i8* }` struct (current pointer, end pointer).
- `bf.alloc` becomes a call to the runtime's byte buffer allocator.
- `bf.write_*` operations become pointer stores with endian byte-swaps where needed (via LLVM's `bswap` intrinsic).
- `bf.read_*` operations become pointer loads with bounds checking and byte-swaps.
- The cursor advance is simple pointer arithmetic.

After lowering, LLVM's optimization passes can further optimize the generated code, inlining the byte writes, eliminating redundant bounds checks, and vectorizing sequential writes when possible.

## Benefits

1. **Zero intermediate allocations**: no encoder/decoder data structures are built at runtime.
2. **No dispatch overhead**: direct read/write operations instead of interpreter-style node dispatch.
3. **Static buffer sizing**: when all element sizes are known, the buffer is allocated at the exact size.
4. **Better LLVM optimization**: fused operations expose more optimization opportunities than opaque kernel calls.
5. **Graceful fallback**: when fusion can't be applied, the standard kernel implementation handles the operation correctly.
