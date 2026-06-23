---
title: "Heap Representation"
description: "How eco represents Elm values across four models, from Elm semantics through function boundaries, SSA registers, and heap storage."
section: "Architecture"
sectionOrder: 2
order: 3
---

## Why Four Models?

A single Elm value looks different depending on where you observe it. An `Int` is a semantic integer in Elm source, a 64-bit register value inside a function, an `i64` passed at function boundaries, and either an inline 64-bit value or a heap pointer in stored data structures. These aren't just different views of the same thing: each representation has different rules, different operations, and different trade-offs.

eco defines four explicit representation models to keep these distinctions clear:

| Model | Where it applies | What it determines |
|-------|------------------|--------------------|
| **Logical** | Elm source, type checker | What the programmer sees |
| **SSA** | MLIR operands within a function | What register types values have |
| **ABI** | Function call boundaries | What callers and callees pass |
| **Heap** | Runtime object fields | How values are stored in memory |

The key insight: **rules in one model do not imply rules in another** unless explicitly linked. Bool is `i1` in SSA but `!eco.value` at ABI boundaries and in heap storage. Int is `i64` everywhere except as a logical `Int`. These distinctions matter for correctness: confusing them is a common source of codegen bugs.

## The Four Models

### Logical Representation

This is the programmer's view: `Int`, `Float`, `Bool`, `Char`, `String`, `List a`, `Maybe a`, records, custom types. It's what the type checker works with and what appears in type annotations. The logical model carries no information about machine layout.

### SSA Representation

Inside a function body, values live in MLIR SSA operands:

| Elm type | SSA type | Notes |
|----------|----------|-------|
| `Int` | `i64` | 64-bit signed integer |
| `Float` | `f64` | 64-bit float |
| `Char` | `i16` | Unicode code point |
| `Bool` | `i1` | Boolean, but only within a function |
| Everything else | `!eco.value` | Heap pointer (tagged 64-bit value) |

Bool uses `i1` in SSA because it's efficient for branching. But this representation doesn't cross function boundaries.

### ABI Representation

At function call boundaries (arguments and returns):

| Elm type | ABI type | Notes |
|----------|----------|-------|
| `Int` | `i64` | Pass by value |
| `Float` | `f64` | Pass by value |
| `Char` | `i16` | Pass by value |
| `Bool` | `!eco.value` | Boxed: True/False are embedded constants |
| Everything else | `!eco.value` | Heap pointer |

The critical difference from SSA: **Bool is `!eco.value` at ABI boundaries**, not `i1`. True and False are represented as embedded pointer constants (see [Memory Model § Embedded Constants](/docs/memory-model#embedded-constants)), so they travel as `!eco.value` between functions.

### Heap Representation

When values are stored as fields in heap objects (records, tuples, cons cells, closures):

| Elm type | Heap storage | Notes |
|----------|-------------|-------|
| `Int` | `i64` unboxed | 8 bytes inline |
| `Float` | `f64` unboxed | 8 bytes inline |
| `Char` | `i16` unboxed | Padded to 8 bytes |
| `Bool` | `!eco.value` boxed | Embedded True/False constants |
| Everything else | `!eco.value` boxed | Heap pointer |

Only three primitive types (Int, Float, and Char) can be stored **unboxed** (inline) in heap structures. Bool is always boxed because True and False are specific bit patterns in the pointer encoding, not raw 0/1 values. String and all compound types are always boxed as heap pointers.

## Boundaries and Transitions

Values cross between models at well-defined boundaries. The compiler inserts boxing/unboxing operations at these transitions.

### Heap → SSA (Projection)

When extracting a field from a heap object, the projection type matches the **physical storage**, not the logical type:

```
-- Record { age : Int, active : Bool }
-- Heap layout: [age: i64 (unboxed)] [active: !eco.value (boxed)]

project field "age"    → i64          (unboxed field, read directly)
project field "active" → !eco.value   (boxed field, read as pointer)
```

The [monomorphization](/docs/monomorphization) pass computes layout metadata that tells the code generator exactly which fields are unboxed. The projection operation consults this metadata; it never guesses based on the logical type.

### SSA → Heap (Construction)

When building a heap object, the construction operation stores values according to the layout's unboxed bitmap:

```
-- Constructing { age = 25, active = True }
-- Unboxed bitmap: 0b01 (age is unboxed, active is not)

construct record [%age_i64, %active_eco_value]
    with unboxed_bitmap = 1
```

The bitmap is computed from the SSA operand types: `i64`, `f64`, and `i16` operands produce unboxed fields; `!eco.value` operands produce boxed fields.

### SSA ↔ ABI (Function Boundaries)

When calling a function, Bool values must be converted:

```
-- Calling a function that takes Bool:
-- SSA has:  %flag : i1
-- ABI needs: !eco.value

%boxed_flag = eco.box %flag : i1 → !eco.value    (before call)
%unboxed    = eco.unbox %result : !eco.value → i1 (after return)
```

Int, Float, and Char pass through unchanged since their SSA and ABI types match.

## The Unboxed Bitmap

Every container type (record, tuple, cons cell, custom type constructor) has an **unboxed bitmap**, a bitmask indicating which fields are stored inline as raw values versus as heap pointers.

This bitmap serves two critical purposes:

1. **Code generation**: The [code generator](/docs/code-generation) uses it to emit the correct projection and construction operations.
2. **Garbage collection**: The [garbage collector](/docs/garbage-collection) uses it to distinguish pointers from raw values during heap traversal. Without it, the GC would try to follow a raw `i64` as if it were a pointer, a guaranteed crash.

### Example: Record with Mixed Fields

```elm
type alias Point = { x : Int, y : Int, label : String }
```

Layout computed during [monomorphization](/docs/monomorphization#layout-computation):

```
RecordLayout
    fieldCount = 3
    unboxedCount = 2
    unboxedBitmap = 0b011      -- x and y are unboxed
    fields:
        x     → index 0, MInt,    isUnboxed = True
        y     → index 1, MInt,    isUnboxed = True
        label → index 2, MString, isUnboxed = False
```

Heap memory layout:

```
[Header : 8 bytes]
[unboxed_bitmap : 8 bytes]     ← 0b011
[x : i64]                      ← raw 64-bit integer
[y : i64]                      ← raw 64-bit integer
[label : HPointer]             ← pointer to heap string
```

The GC reads the bitmap, sees that fields 0 and 1 are unboxed (not pointers), and only traces field 2.

### Container Types

Different container types store the bitmap differently:

- **Records**: Dedicated `unboxed_bitmap` field after the header.
- **Tuples**: Bitmap encoded in the header's size field (2-3 bits for Tuple2/Tuple3).
- **Cons cells**: Single `unboxed_head` flag in the header (the head may be unboxed, the tail is always a pointer).
- **Custom types**: Bitmap packed with the constructor tag in a combined `ctor_unboxed` field.
- **Closures**: Bitmap packed in the closure's `packed` field alongside capture counts.

## Embedded Constants

Six common values are represented directly in the pointer encoding, with no heap allocation and no memory access needed:

| Constant | Meaning |
|----------|---------|
| Unit | `()` |
| True | `True` |
| False | `False` |
| Nil | Empty list `[]` |
| EmptyString | `""` |
| Nothing | `Nothing` |

These use nonzero bits in the `constant` field of the [logical pointer](/docs/memory-model#logical-pointers) encoding. When `constant ≠ 0`, the value is an embedded constant, not a heap address. The GC skips these during tracing.

This is why Bool can't be unboxed as a simple 0/1 in heap storage: True and False are specific pointer-encoded constants that must travel as `!eco.value`. Unboxing them would lose the constant encoding.

## Closure Captures

Closures follow **SSA representation rules** for their captured values:

- `i64`, `f64`, `i16` captures are stored unboxed in the closure.
- All other values (including Bool as `i1`) are stored as `!eco.value`.

```
-- Closure capturing an Int and a Bool:
-- captures: [%count : i64, %flag : i1]
--
-- %flag is i1 in SSA but must be boxed to !eco.value for storage
-- capture_unboxed bitmap = 0b01 (only first capture is unboxed)
```

The closure's packed field encodes `n_values` (number of captured values), `max_values` (total capacity including future arguments), and an unboxed bitmap for the captures. See [Code Generation § Closures](/docs/code-generation#closures) for the full closure implementation.

## Debugging Representation Bugs

When something goes wrong with value representation, the symptoms often appear far from the cause:

| Symptom | Likely cause |
|---------|-------------|
| Crash during GC | Bitmap mismatch: GC traced a raw value as a pointer |
| Wrong value at runtime | Projection type doesn't match storage type |
| Type error at call boundary | ABI/SSA representation confusion (e.g., Bool as `i1` vs `!eco.value`) |
| Memory corruption | Layout metadata doesn't match actual heap struct |

The debugging checklist:

1. **Check the unboxed bitmap**: does it match the field types in the layout?
2. **Check projection operations**: does the result type match the physical storage type?
3. **Check construction operations**: does the bitmap match the SSA operand types?
4. **Check ABI boundaries**: are Bool values properly boxed/unboxed at function calls?

eco's [MLIR verification infrastructure](/docs/code-generation#lowering-to-llvm) catches many of these issues at compile time, but layout mismatches between the Elm compiler and C++ runtime can slip through to runtime crashes.
