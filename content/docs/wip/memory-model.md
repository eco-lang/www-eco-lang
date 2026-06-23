---
title: "Memory Model"
description: "How eco manages memory with thread-local heaps, logical pointers, and a unified address space, all simplified by Elm's immutability."
section: "Runtime"
sectionOrder: 4
order: 1
---

## Immutability Changes Everything

The single most consequential property of Elm for runtime design is **immutability**. Once an Elm value is created, it never changes. This has a profound implication for garbage collection that eliminates an entire category of runtime complexity.

In a language with mutation (Java, Go, OCaml), a generational garbage collector must handle a dangerous scenario: an old-generation object is mutated to point to a young-generation object. This is called an **old-to-young pointer**, and the collector must know about it; otherwise, during a minor GC that only scans the young generation, the young object would appear unreachable and be collected even though the old object still references it.

The standard solution is a **write barrier**: extra code injected on every pointer store that records when an old object is modified. This requires runtime data structures (remembered sets, card tables, or store buffers) and adds overhead to every pointer write in the program.

Elm doesn't have this problem. Because values are immutable:

- **New objects can only point to older objects.** When you create a value, it can only reference things that already exist. You can't modify it later to point to something newer.
- **Old-to-young pointers are impossible.** An old object was created before the young object existed, and it was never modified afterward.
- **No write barrier is needed.** The generational invariant is maintained for free by the language semantics.

This isn't a minor optimization. The complexity that *doesn't* exist in eco's runtime (card tables, remembered sets, store buffers, barrier code on every pointer store) is the complexity you would normally spend most of your time debugging in a generational collector. eco's GC is simpler specifically because Elm's language design makes it simpler.

## Thread-Local Heaps

Each thread in eco owns a `ThreadLocalHeap` containing its own nursery and old generation. No cross-thread synchronization is needed during normal operation:

- **Allocation**: Pure bump-pointer in the thread-local nursery. No locks, no atomic operations.
- **Minor GC**: Operates only on the thread-local nursery. No coordination with other threads.
- **Major GC**: Operates only on the thread-local old generation. No coordination.

```
Thread 1: [Nursery₁] → [OldGen₁]
Thread 2: [Nursery₂] → [OldGen₂]
          ↑                    ↑
          └── carved from unified heap ──┘
```

The central `Allocator` singleton manages the unified address space and carves out regions for each thread at initialization. Once a thread has its regions, it operates independently.

The trade-off is that memory cannot be shared between threads. But Elm's concurrency model is message-passing: there's no shared mutable state by design. Thread-local heaps match the programming model naturally.

## Unified Address Space

The allocator reserves a single large address space (1GB by default) via `mmap` without committing physical memory upfront. This space is partitioned:

```
[0 .................. heap_reserved/2)    - Old generation regions
[heap_reserved/2 .................. end)  - Nursery regions
```

Physical memory is committed on demand as threads initialize and grow:

- Nursery blocks are committed when a thread initializes or when its nursery needs to grow.
- Old generation regions are committed when a thread initializes, and grow as objects are promoted.

Each thread gets its own contiguous regions within these spaces. The `Allocator` tracks committed ranges and hands out chunks to each `ThreadLocalHeap`.

### Configuration

Heap parameters are centralized in `HeapConfig`:

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `nursery_block_count` | (even) | Split between from-space and to-space |
| `alloc_buffer_size` | 128KB | Size of each block |
| `promotion_age` | 1 | GC cycles before promotion to old gen |
| `nursery_gc_threshold` | 90% | Occupancy that triggers minor GC |
| `use_hybrid_dfs` | true | List locality optimization |

Configuration is validated at `Allocator::initialize()` to catch invalid combinations (e.g., odd nursery block counts) early.

## Logical Pointers

All heap pointers in eco are **logical offsets**, not raw memory addresses:

```cpp
typedef struct {
    u64 ptr : 40;         // Offset into heap (8-byte granularity)
    u64 constant : 4;     // Embedded constant tag
    u64 padding : 20;     // Available for future use
} HPointer;
```

The 40-bit offset, with 8-byte alignment, addresses up to 8TB of heap space. This encoding has several benefits:

- **Compression**: 8-byte aligned offsets fit in 40 bits, leaving room for metadata in the same 64-bit word.
- **Relocation-friendly**: Offsets from a base are easier to adjust than raw addresses when memory regions are moved.
- **Embedded constants**: The `constant` field enables values to be represented without any heap allocation (see below).

The `fromPointerRaw` and `toPointerRaw` conversions are the only places in the codebase that touch `heap_base`. All pointer manipulation goes through these functions.

## Embedded Constants

Common constant values are represented directly in the pointer encoding: no heap allocation, no pointer chase:

| Constant | `constant` field value | Meaning |
|----------|----------------------|---------|
| Unit | 1 | `()` |
| True | 3 | `True` |
| False | 4 | `False` |
| Nil | 5 | Empty list `[]` |
| EmptyString | 7 | `""` |

When `constant ≠ 0`, the pointer is an embedded constant, not a heap address. The GC skips these during tracing. The [code generator](/docs/code-generation#ecotollvm-final-lowering) emits `eco.constant Unit` as the integer `1 << 40`: a single constant load, no allocation.

This is why Bool is always `!eco.value` in heap storage (not unboxed like Int/Float): True and False are specific bit patterns in the pointer representation, not 0/1 boolean values.

## Object Layout

This section describes the runtime memory layout of heap objects. For the compile-time perspective on how layouts are computed and how values transition between representation models (Logical, SSA, ABI, Heap), see [Heap Representation](/docs/heap-representation).

Every heap object starts with an 8-byte header:

```cpp
typedef struct {
    u32 tag : 5;      // Object kind (Int, Float, Cons, Tuple, Record, ...)
    u32 color : 2;    // GC tri-color marking (white, grey, black)
    u32 size : 25;    // Element count (not byte size)
    u32 age : 2;      // GC survival count (for promotion)
    u32 epoch : 2;    // GC epoch (for incremental marking)
    u32 pin : 1;      // Prevents relocation
    u32 reserved : 27;
} Header;
```

After the header, the layout depends on the object kind:

```
Cons cell:  [Header:8][head:8][tail:8]              = 24 bytes
Tuple2:     [Header:8][a:8][b:8]                    = 24 bytes
Tuple3:     [Header:8][a:8][b:8][c:8]               = 32 bytes
Record:     [Header:8][unboxed_bitmap:8][fields:N×8]
Custom:     [Header:8][ctor_tag/unboxed:8][fields:N×8]
Closure:    [Header:8][packed:8][evaluator:8][values:N×8]
```

**All heap objects are 8-byte aligned.** This is enforced by all allocation paths and required for the pointer compression to work (the 40-bit offset assumes 8-byte granularity).

### Size Calculation

The `getObjectSize()` function must match object layout exactly: it's used by the GC to know how far to advance past an object when scanning. Key points:

- **Fixed-size types**: `ElmInt`, `ElmFloat`, `Tuple2` have known sizes.
- **Variable-size types**: Use the header's `size` field to store element count.
- **Closure special case**: Uses `n_values` from the packed field, not the header size.
- **Always 8-byte aligned**: `(size + 7) & ~7`.

Getting this wrong is a common source of GC bugs: if the size is too small, the GC treats part of the next object as the current one; too large, it skips live data.

### Unboxed Fields

When a container holds `Int` or `Float` values, those values can be stored unboxed, as raw 64-bit integers or floats inline in the object, rather than as pointers to separate heap objects. The unboxed bitmap (computed during [monomorphization](/docs/monomorphization#unboxing-rules)) tells the GC which fields are raw values and which are pointers that need tracing.

## Key Invariants

Eight invariants govern eco's memory model:

1. **No old-to-young pointers.** Guaranteed by Elm's immutability. No write barrier needed.
2. **Forwarding pointers are ephemeral.** They only exist during GC. All pointers are resolved before the mutator resumes. See [Garbage Collection § Forwarding Pointers](/docs/garbage-collection#forwarding-pointers).
3. **Objects are 8-byte aligned.** Enforced by all allocation paths. Required for pointer compression.
4. **Headers are always first.** Every heap object starts with an 8-byte Header. Size calculation depends on this.
5. **Constants are never heap-allocated.** Nil, True, False, Unit, Nothing, EmptyString are embedded in the pointer representation.
6. **Allocation may trigger GC.** Callers must assume any allocation could move all live objects.
7. **Space membership is O(1).** Checking if a pointer is in from-space or to-space uses cached bounds for simple range comparison.
8. **Thread ownership is exclusive.** Each heap region is owned by exactly one thread. No cross-thread pointer sharing.
