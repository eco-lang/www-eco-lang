---
title: "Value representation"
description: "How eco stores every Elm value as a 64-bit word that is either a raw machine number, a heap address, or a constant embedded in the word, and how one value can take different forms in different places."
section: "The runtime"
sectionOrder: 4
order: 2
---

An Elm `Bool` is a single bit inside a function, a 64-bit word when it is passed to an unknown closure, and the same word again when it is stored in a list. eco keeps four separate models of every value (inside a function, across a call, in the heap, and its Elm meaning) and converts at a small number of fixed points. Most of the design follows from making those conversions cheap, and from making a heap pointer nothing more than the object's address.

> **Background**
>
> - [Boxed and unboxed](/docs/glossary#boxed-and-unboxed): a boxed value is reached through a pointer; an unboxed one is stored directly as a machine number.
> - [SSA](/docs/glossary#ssa): the form of the compiler's intermediate code, where each value is defined once and has one machine type.
> - The [ABI](/docs/glossary#abi) is the agreement on how values are passed between functions.

## Four models of one value

Take `True`. In Elm it is just a constructor of `Bool`. Each of the four models gives it a different form:

| Model | Where it applies | `True` is | `5 : Int` is |
|---|---|---|---|
| Logical | Elm meaning: equality, ordering, pattern matching | `True` | `5` |
| SSA | inside one function body | `i1` value 1 | `i64` 5 |
| ABI | arguments, results, captured values | the word `0x5` | `i64` 5 |
| Heap | a field of a heap object | the word `0x5` | raw `i64` 5, marked as an Int slot |

The models are kept apart because each has a different job. Inside a function, LLVM wants the narrowest machine type, so a `Bool` is a one-bit integer it can branch on. Across a call or in a heap field, every value except a number has to fit in one uniform 8-byte slot, so `Bool` becomes a word. Each model's type is computed by one function of the value's specialized type, so every site that builds or reads a value agrees on its form.

Only three types are ever stored raw outside a function: `Int` (a 64-bit integer), `Float` (a 64-bit float) and `Char` (one 16-bit UTF-16 code unit). Everything else, `Bool` included, is a word. A type variable that [Monomorphization](/docs/monomorphization) left unconstrained is also a word, so an `Int` passing through an `a` parameter is boxed into a 16-byte heap object. That way the code that sees the value as `a` and the code that sees it as `Int` agree on a single word.

## The value word

Every boxed value is one 64-bit word with this layout:

![The 64-bit value word: bits 0-1 constant code, bit 2 pointer indicator, bits 3-42 pointer, bits 43-52 nullary constructor index, bits 53-63 reserved](/images/docs/value-word.svg)

The runtime declares it as a C bit-field, least significant bits first (from the runtime's heap definitions):

```cpp
typedef enum {
    Const_False = 0,
    Const_True  = 1,
    Const_Empty = 2,
    Const_NullCons = 3,
} Constant;

typedef struct {
    u64 constant : 2;            // bits 0-1
    u64 ptr_ind  : 1;            // bit 2: 0 = heap pointer, 1 = constant
    u64 ptr      : POINTER_BITS; // bits 3-42 (40 bits)
    u64 null_cons_idx : 10;      // bits 43-52
    u64 padding  : 11;           // bits 53-63, always 0
} HPointer;
```

The design rests on the low three bits. Every heap object is 8-byte aligned, so the low three bits of its address are always zero, and eco puts the constant code and the pointer indicator exactly there. For a heap pointer those bits are zero, and the 40-bit `ptr` field starting at bit 3 holds the rest of the address. The low 43 bits of the word therefore *are* the raw address: dereferencing needs no base register, no add and no shift. The heap is reserved below 2^43 bytes (8 TB) so that every address fits.

A word with bit 2 set is a constant embedded in the word. It is never allocated and never traced by the collector. The fixed words are:

| Value | Word | Why |
|---|---|---|
| `False` | `0x4` | indicator set, code 0 |
| `True` | `0x5` | indicator set, code 1 |
| `()`, `[]`, `Nothing`, `""`, `{}` | `0x6` | indicator set, code 2: one shared Empty |
| a nullary constructor at declaration index *i* | `(i << 43) \| 0x7` | indicator set, code 3, index in bits 43-52 |
| null | `0x0` | used only internally |

For `type Order = LT | EQ | GT`, `LT` is `0x7`, `EQ` is `0x0000080000000007` and `GT` is `0x0000100000000007`. Each saves a 16-byte heap object every time one is produced.

Bit 0 of `False` and `True` is the Bool's own one-bit value. Converting between the SSA form and the word is cheap: boxing a Bool is a select between `0x5` and `0x4`, and unboxing is a compare with `0x5`. Neither allocates.

This choice has a cost. `False` has constant code 0, the same as a heap pointer, so code can never test "is this a pointer?" by looking at the code bits. Bit 2 is the only legal test. Testing for null, or whether the word falls in the heap's address range, is ruled out too, because the range depends on where the heap happens to be reserved.

## One Empty for five types

A single word, `0x6`, stands for `()`, `[]`, `Nothing`, `""` and `{}`. Merging them is safe because Elm is typed: the type checker guarantees that each is only produced and matched where its own type is expected, so the word never has to say which empty it is. The cost is that a `case` cannot learn the constructor from the word alone, so when it meets Empty it reads a reserved tag instead.

The merge also means an embedded value must exist *only* in its embedded form. Equality concludes "not equal" as soon as one side is an embedded constant and the words differ. A heap object holding `LT`, or a heap string of length zero, would compare unequal to the real `LT` or `""`. Every producer returns the constant, and no zero-length heap string is ever built.

## A real example

Here is the list `[ 1, 2, 3 ]` and the value `Rect 2 3` as eco's compiler emits them for the shapes program used in [A tour through the compiler](/docs/tour) (trimmed: type annotations on operands removed):

```mlir
%30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value
%31 = "arith.constant"() {value = 3 : i64} : () -> i64
%32 = "eco.construct.list"(%31, %30) {head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value
%33 = "arith.constant"() {value = 2 : i64} : () -> i64
%34 = "eco.construct.list"(%33, %32) {head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value
%35 = "arith.constant"() {value = 1 : i64} : () -> i64
%25 = "eco.construct.list"(%35, %34) {head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value

%12 = "arith.constant"() {value = 2.0 : f64} : () -> f64
%13 = "arith.constant"() {value = 3.0 : f64} : () -> f64
%14 = "eco.construct.custom"(%12, %13) {constructor = "Rect", size = 2, slot_kinds = array<i8: 2, 2>, tag = 1} : (f64, f64) -> !eco.value
```

`[]` is `eco.constant` with kind 2, Empty, which becomes the word `0x6`. Each cons cell stores its `Int` head raw (`head_kind = 1`). `Rect` is constructor 1 of `Shape`, with two raw `Float` fields (kind 2 each).

## Slot kinds: how the collector tells numbers from pointers

Every slot of a heap object carries a two-bit kind: `00` boxed word, `01` raw Int, `10` raw Float, `11` raw Char. The collector reads only these kinds, so it can tell a raw integer from a pointer without knowing any Elm types. OCaml solves the same problem the other way, by stealing the low bit of every integer, which leaves it 63 bits. We prefer to keep `Int` at a full 64 bits and put the information in the object instead.

Four codes is exactly boxed plus three primitives, which is why only `Int`, `Float` and `Char` are ever raw. A raw Bool would spend a code for nothing, since boxing a Bool costs nothing. Small objects (cons cells, tuples) keep their kinds in the 8-byte object header. Larger ones (records, custom types, closures) keep them in a packed word after the header, with extra kind words at the end of the object when there are many fields, so a field always stays at its own position however many fields there are.

Layouts are pure functions of the type, recomputed at every site that builds or reads an object. Record fields go raw first, then boxed, each group sorted by name, so `{ x, y }` and `{ y, x }` share a layout. Custom-type fields keep declaration order. No layout table is stored anywhere.

## Where a value changes form

Conversions happen only at fixed seams, and each has one operation:

| Seam | Conversion | Cost |
|---|---|---|
| Into a call, capture or partial application | `eco.box` (a Bool, or a number whose target is an `a`) | Bool: a select. Number: allocates a 16-byte box |
| Out of a call | `eco.unbox` | Bool: a compare. Number: one load |
| Building a heap object | raw numbers stored as they are; a Bool boxed first | none |
| Reading a field | typed by the slot's kind | one load |
| Stack aggregate to heap and back | `eco.to_heap`, `eco.from_heap` | `eco.to_heap` allocates |

Code generation decides whether to convert by comparing the value's actual SSA type with the type the target expects, never by reasoning from the declared Elm type. A declared type that disagrees with how a value is stored is exactly the bug the four models exist to prevent.

Below this there is a fifth, mechanical form. Inside LLVM, a boxed value has the type `ptr addrspace(1)`, which is how LLVM knows which values are heap pointers the collector may move. It becomes a plain integer only at the instant it is written to or read from memory.

> **Designs we didn't use.** The word could store a 40-bit *offset* from a heap base rather than the address itself. We rejected it because every dereference pays an add and a shift, and its `True` and `False` share no bit with the one-bit Bool, so boxing and unboxing a Bool would no longer be a single select or compare.

## Further reading

- [Closures and calls](/docs/closures-and-calls) — how slot kinds drive argument conversion in closures.
- [The garbage collector](/docs/garbage-collector) — the object header, and why the heap sits below 2^43.
- [Runtime data structures](/docs/data-structures) — the forms of strings and lists behind a single word.
- [The eco dialect](/docs/eco-dialect) — the types `!eco.value`, `i64`, `f64` and the construction operations.
- The full design document: [Value representation theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/value-representation.md)
- Source: [`runtime/src/allocator`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/allocator)
