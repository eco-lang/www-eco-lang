---
title: "The garbage collector"
description: "How Eco's generational, concurrent garbage collector works without any write barrier, because in Elm an old object can never point at a younger one."
section: "The runtime"
sectionOrder: 4
order: 5
---

Most generational collectors, such as those in the JVM and V8, put a write barrier on every pointer store so they can track pointers from old objects to young ones. Eco's collector has none, because in Elm an old object can never point at a younger one. The same fact lets it mark the old generation and promote survivors on background threads while the program runs, again without barriers. On the compiler compiling itself, its worst pause is under a tenth of a second, against nearly three seconds for a single-threaded collector.

> **Background**
>
> - [Nursery and eden](/docs/glossary#nursery-and-eden): the young generation, where new objects are allocated; eden is the part that fresh objects go into.
> - [Tenuring](/docs/glossary#tenuring) (promotion) is moving an object that has survived long enough into the old generation.
> - A [write barrier](/docs/glossary#write-barrier) is extra code on every pointer store that tells the collector about it.
> - A [safepoint](/docs/glossary#safepoint) is a point in compiled code where the collector is allowed to run.

## Why immutability is enough

In Elm a value is built only from values that already exist, so every pointer stored into a new object leads to something of the same age or older. If nothing writes into an object once the program can see it, no old object can ever gain a pointer to a younger one. A young collection then needs only the roots and the young generation. It never searches the old generation for pointers into the nursery, so there is no remembered set, no card table, and no check on each store to maintain them.

The argument does not need the heap to be free of cycles, and it is not. A closure that calls itself holds its own pointer, and mutually recursive closures point at each other. Those edges are written while the objects are being created, in the same allocation, so they join objects of the same age. The collector traces cycles like any other graph.

The same property removes the barriers a *concurrent* collector usually needs. No object that existed when marking began is ever written, so every pointer the program holds later leads either to something reachable at that moment or to something allocated since. Background marking therefore needs only a snapshot of the roots at the start, and it treats everything allocated during the cycle as live. It needs no barrier recording overwritten pointers, and no second pause to re-mark.

## Keeping the heap frozen

*Immutable values* are a property of the language; a *frozen heap* is a property of the runtime, and Eco needs both. The heap is written by compiled code and by C++ that could store anywhere, so each writer keeps its own rule:

1. Compiled code stores only into objects it allocated since its last safepoint. Such an object cannot have moved or aged.
2. Recursive closures are wired up inside the same allocation, with no safepoint in between.
3. A kernel that fills a container across calls into user code, any of which may collect, sets the container's *builder* bit. A builder is traced and copied but never promoted, so it stays young while it is written, and the bit is cleared before Elm code can see it.
4. A large object that holds pointers, such as a big array, is always allocated young, because its kernel fills it with young pointers afterwards.
5. Long-lived mutable runtime state, such as the scheduler's process records, lives off the heap and is scanned as a root.

A breach of these rules is not survivable. The default nursery promotes in the background, so a late write could leave an old object pointing into eden after eden has been reset. Each writer therefore keeps its rule, and validation builds check it with a census that hashes surviving objects and reports any hash that changes.

## The heap

![Heap layout: one reserved address range, old generation of size-class blocks at the bottom, nursery region at the top holding eden and rotating survivor extents](/images/docs/heap-layout.svg)

The heap is one reserved range of address space below 2^43 bytes, with the old generation at the bottom and the nursery at the top. A heap pointer is the object's address (see [Value representation](/docs/value-representation)), so "is this object young?" is a bounds compare.

The old generation never moves. It is made of blocks, each serving one size class or a mix, with a bitmap per block recording which cells are live. Because liveness lives in the bitmaps, a block with no marks can be released without being scanned. Large strings and byte buffers are split in two: a small header sits in the nursery and points at a payload that lives in a large-object space and is never copied.

Values that never die, such as computed top-level constants, interned literals and closures that capture nothing, are copied once into a permanent space outside the heap that the collector never visits.

## One object, bit by bit

Every object starts with an 8-byte header. The tag says what kind of object it is, which fixes its size and the layout of its children, so the collector never needs Elm types (from the runtime's heap definitions):

```cpp
typedef struct {
    u32 tag : TAG_BITS;
    u32 color : 2; // White, Grey, or Black for tri-color mark-and-sweep.
    u32 pin : 1; // Memory-pinned object (prevents relocation).
    u32 age : 2; // Nursery promotion counter; doubles as on-free-list
                 // sentinel for Tag_Free cells (see above).
    u32 unboxed : 6; // 2 bits per slot; used by Cons/Tuple2/Tuple3/ElmArray.
    u32 refcount : 15; // Reference count (unused currently).
    u32 builder : 1; // Builder flag: object is under construction; pinned
                     // to nursery (no aging, no promotion) while set.
    u32 size; // Object size in type-specific units.
} Header;
```

Packed least significant bit first, the fields are `tag` in bits 0–4, `color` 5–6, `pin` 7, `age` 8–9, `unboxed` 10–15, `refcount` 16–30, `builder` 31 and `size` 32–63. At allocation everything except the tag, the kinds and the size is zero, so the compiler builds the whole header as one 64-bit constant with this formula (from the backend's lowering helpers):

```cpp
constexpr unsigned HeaderUnboxedShift = 10;  // tag:5 + color:2 + pin:1 + age:2
constexpr unsigned HeaderSizeShift = 32;
constexpr uint64_t composeHeader(uint64_t tag, uint64_t unboxedBits,
                                 uint64_t sizeField) {
    return tag | (unboxedBits << HeaderUnboxedShift)
               | (sizeField << HeaderSizeShift);
}
```

Take the list `5 :: rest`, a cons cell whose head is a raw `Int`:

![Layout of the cons cell for 5 :: rest: header word 0x0000001800000406, then the raw Int 5, then the tail pointer](/images/docs/cons-cell-layout.svg)

- The tag for a cons cell is 6.
- The head is a raw `Int`, slot kind `01`, so `unboxed` is 1, shifted to bit 10: 1 × 2^10 = `0x400`.
- A cons cell's size field is its size in bytes, 24 (header, head, tail), shifted to bit 32: 24 × 2^32 = `0x18_0000_0000`.

Adding them gives the header word `0x6 + 0x400 + 0x18_0000_0000 = 0x0000001800000406`. The next word is the raw integer `0x0000000000000005`, and the third is `rest`: an address, or `0x6` if `rest` is `[]`.

The kind bits matter more than they look. Read as a value word, `0x5` is `True` (bit 2 set, constant code 1). Only the `01` kind in the header tells the collector that this slot is the number 5 and must not be interpreted at all.

## Allocation: one compare

Compiled code allocates by bumping a pointer through eden, inline. The backend expands each allocation into this sequence (from the backend's comment on the allocation fast path, LLVM IR):

```text
%state = call ptr @eco_bump_state()          ; memory(none) gc-leaf
%top   = load ptr addrspace(1), ptr %state   ; bump.ptr at +0
%end   = load ptr addrspace(1), ptr %state+8 ; bump.end at +8 (clamped)
%new   = gep i8, %top, SIZE
%miss  = icmp ugt %new, %end
br %miss, slow, fast                          ; !prof slow=1 fast=1<<20
slow:  %r = call ptr addrspace(1) @eco_alloc_inline_slow(SIZE)  ; statepointed
fast:  store %new, %state                       ; publish the bump
cont:  %obj = phi [ %top, fast ], [ %r, slow ]
```

The end of the bump area is clamped in advance to the point where a young collection should start, so one unsigned compare means both "eden is full" and "time to collect". The slow branch is the only place compiled code can collect. Header and field stores follow straight after, with no safepoint in between, so the collector can never see a half-built object. In ahead-of-time builds the first call is replaced by a thread-local load.

## A young collection

A young (minor) collection starts when a bump misses. It empties eden completely, copying live objects into a free survivor extent with several threads at once. A thread claims an object by an atomic update of its header, copies it, and then publishes the forwarding address, so no two threads copy the same object.

A minor collection never promotes anything itself. Objects that survived the *previous* collection sit in their own extent, and that whole extent is handed to a tenure job that promotes what is still reachable, on a background thread, while the program runs. The tenure job keeps its forwarding addresses in a side table rather than in headers, and allocates only from old-generation blocks reserved for it, so it shares no state the program writes. Until an extent is retired, a pointer to an unmoved original is still valid, and because neither the original nor its copy is ever written, the two are interchangeable. That is why tenuring needs no read barrier. At most three survivor extents are in use at once.

## Marking the old generation

The old generation is collected by one mark cycle that spans several young collections. The pause that starts a cycle marks the old-generation targets of every root and every young object, then hands that set to background marker threads, which mark while the program runs. Later pauses only help a marker that has fallen behind, and the minor collection after marking finishes classifies blocks for sweeping. A cycle starts when the old generation is filling, when much of it has become garbage, or when the program asks for a collection.

Every collection decision is a function of the program's own state, never of how far a helper thread has got. We hold to this because it makes concurrent changes testable: a synchronous mode reproduces the concurrent one counter for counter. The concurrent protocols are also written as TLA+ models (see [Model-checking the collector](/docs/concurrency-models)).

## Numbers

The measure we use is the compiler compiling itself natively. The worst pause is under 100 ms, and only 1 in 100 pauses is longer than about 20 ms. A single-threaded collector, doing the same work with the program stopped, pauses for nearly three seconds on its major collections. Total time in the collector is a few seconds per self-compile, partly because of the concurrent work and partly because the compiler itself allocates and promotes little.

> **Designs we didn't use.** *Pretenuring* allocates an object directly in the old generation to save a copy. We do not use it because an object allocated old and filled afterwards is an unrecorded old-to-young pointer, which would bring barriers back.

## Further reading

- [Value representation](/docs/value-representation) — the value word and slot kinds the collector reads.
- [Runtime data structures](/docs/data-structures) — builders and large strings in practice.
- [Model-checking the collector](/docs/concurrency-models) — the TLA+ models of marking and tenuring.
- [The runtime](/docs/runtime) — the one-mutator rule and how roots are found.
- The full design document: [Garbage collector theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/runtime/garbage-collector.md)
- Source: [`runtime/src/allocator`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/allocator)
