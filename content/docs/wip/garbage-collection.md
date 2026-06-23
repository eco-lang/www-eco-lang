---
title: "Garbage Collection"
description: "eco's generational garbage collector: Cheney's copying collector for the nursery, mark-sweep with lazy sweeping for the old generation."
section: "Runtime"
sectionOrder: 4
order: 2
---

## Two Generations, Two Algorithms

eco uses a generational garbage collector based on the **weak generational hypothesis**: most objects die young. Elm programs allocate heavily (intermediate values, list cells, records) but most of these are short-lived. A generational design exploits this by collecting young objects frequently (cheap) and old objects rarely (more expensive but infrequent).

The GC pairs each generation with the algorithm best suited to its characteristics:

- **Nursery**: Cheney's semi-space copying collector. Optimal for high-churn, short-lived allocations.
- **Old generation**: Mark-sweep with lazy sweeping and incremental compaction. Space-efficient for long-lived objects.

## Nursery: Cheney's Copying Collector

Young objects live in the nursery, which uses a copying collector:

1. **Bump-pointer allocation**: Just increment a pointer. O(1), no fragmentation, no free-list search.
2. **Copy survivors to to-space**: When the nursery is full, only live objects are copied. Dead objects are never touched: garbage is free.
3. **Swap spaces**: The old from-space becomes the new to-space. Memory is implicitly reclaimed.

The cost of minor GC is proportional to the number of **survivors**, not the total number of allocations. If 95% of nursery objects are garbage (typical for Elm), only 5% pay the copying cost.

### Two-Region Semi-Space Design

The nursery uses two separate address regions (`low_blocks` and `high_blocks`) rather than interleaved blocks. One region serves as from-space, the other as to-space, swapping roles after each GC:

```
low_blocks:  [block₁][block₂][block₃]    ← from-space (this cycle)
high_blocks: [block₄][block₅][block₆]    ← to-space (this cycle)

After GC, spaces swap:
low_blocks:  [block₁][block₂][block₃]    ← to-space (next cycle)
high_blocks: [block₄][block₅][block₆]    ← from-space (next cycle)
```

This design enables **O(1) membership checks**: determining whether a pointer is in from-space or to-space is a simple bounds comparison (`ptr >= low_base && ptr < low_end`) instead of a set lookup. These bounds are cached in member variables for fast access.

When survivors exceed 75% of to-space capacity, both regions grow dynamically.

## Old Generation: Mark-Sweep

Long-lived objects promoted from the nursery live in the old generation. Mark-sweep doesn't require 2x space overhead like copying collection, making it more appropriate for objects that stick around.

### Marking Phase

Traces from roots (stack, globals), marking reachable objects using tri-color marking:

- **White**: Not yet visited (presumed dead)
- **Grey**: Discovered but children not yet scanned
- **Black**: Fully scanned (known live)

Starting from roots, grey objects are scanned: their children are marked grey, and the object itself becomes black. When no grey objects remain, all white objects are unreachable garbage.

### Lazy Sweeping

Instead of sweeping all objects immediately after marking, the old generation sweeps **on demand** when allocation needs free space. This spreads the sweeping cost across multiple allocation operations rather than concentrating it in one pause.

### Segregated Free Lists

Small objects use 32 size classes (8 to 256 bytes in 8-byte increments) for fast allocation:

- **Small objects (≤256 bytes)**: Check the segregated free list for the matching size class first. If empty, fall back to bump allocation.
- **Large objects**: Bump allocation from the current block.
- **When the current block is exhausted**: Trigger lazy sweep to reclaim memory, or acquire a new block.

### Incremental Compaction

When fragmentation exceeds a threshold, sparse blocks are evacuated incrementally, spreading the compaction cost across multiple allocation slow-paths rather than doing it all at once:

```
GC state machine:
Idle → Marking → Sweeping → Idle
                    ↓
              (if fragmented)
                    ↓
            Evacuating → FixingRefs → Idle
```

Compaction is optional and only triggers when fragmentation is high enough to warrant the cost of moving objects and updating pointers.

## Promotion

Objects are promoted from nursery to old generation after surviving a configurable number of minor GCs (default: 1). The age is tracked in the 2-bit `age` field of the [object header](/docs/memory-model#object-layout):

```cpp
u32 age : 2;    // Survives up to 3 GCs before promotion
```

When the nursery's `evacuate()` function encounters an object that has reached promotion age, it allocates in the old generation instead of to-space. Promoted objects are added to a buffer and their child pointers are scanned, since children might still be in the nursery and need evacuation.

With the default `promotion_age` of 1, an object that survives one minor GC is promoted on the next. This is aggressive, which keeps the nursery small and collection fast at the cost of potentially promoting some objects that would have died soon. The parameter is configurable in `HeapConfig` for tuning.

## Forwarding Pointers

When Cheney's algorithm copies an object, the original location becomes invalid. But other objects might still have pointers to the old location. The solution: leave a **forwarding pointer** at the old location that says "I moved here."

```cpp
typedef struct {
    struct {
        u64 tag : 5;              // Tag_Forward
        u64 color : 2;            // (unused)
        u64 forward_ptr : 40;     // Logical pointer to new location
        u64 unused : 17;
    } header;
} Forward;
```

During minor GC:

1. Object is copied to its new location (to-space or old gen).
2. Original location is overwritten with a `Tag_Forward` header containing the new address.
3. When other objects' pointers are updated, forwarding pointers are followed to find the new location.

**Forwarding pointers are ephemeral.** They only exist during GC. By the time the mutator (application code) resumes, all pointers have been updated to their final locations. The mutator never sees a forwarding pointer.

## List Locality Optimization

Elm programs create many linked lists. Standard Cheney's algorithm copies objects in breadth-first order, which can scatter list nodes across memory: one node here, the next node far away. This hurts cache performance when traversing lists.

eco uses an optional two-pass copying strategy for Cons cells to improve locality:

**Pass 1, Copy spine contiguously**: Walk the tail chain, copying each Cons cell immediately after the previous one in to-space. The entire list spine ends up contiguous in memory.

**Pass 2, Evacuate heads**: Walk the copied spine and evacuate each head element (which may be any type).

```
Before GC (scattered):
  [Cons₁] → ... → [Cons₂] → ... → [Cons₃]

After GC (contiguous spine):
  [Cons₁][Cons₂][Cons₃]  → heads nearby
```

Benefits:
- **Better cache prefetching** when traversing lists (hardware prefetchers detect sequential access)
- **Reduced TLB misses** for list-heavy code
- **No cost for non-list data** (non-Cons objects use standard BFS copying)

This is the "hybrid DFS" in `HeapConfig::use_hybrid_dfs`: depth-first treatment of list tails within an otherwise breadth-first Cheney algorithm. It's enabled by default.

## Execution Model

There is no separate collector thread. Each mutator thread runs its own GC on its own [thread-local heap](/docs/memory-model#thread-local-heaps):

- **Minor GC** is triggered when nursery occupancy exceeds `nursery_gc_threshold` (default 90%).
- **Major GC** is triggered when old generation committed bytes exceed a growth threshold.
- **Incremental work** (marking, compaction) is spread across allocation slow-paths.

Each thread's GC is stop-the-world *for that thread only*. Other threads continue executing. This avoids global synchronization while keeping the collector simple.

The `ThreadLocalHeap` coordinates nursery and old gen:

```
1. allocate() bumps pointer in nursery
2. When threshold exceeded → minorGC() evacuates survivors
3. Promoted objects go to thread-local old gen
4. When old gen grows large → majorGC() marks and sweeps
```

For Elm's typical use case (applications with message-passing concurrency) thread-local heaps match the programming model naturally. No shared heap means no global GC pauses.

## Debugging the GC

When something goes wrong, the key questions are:

1. **Was the object correctly evacuated?** Check that a forwarding pointer was left behind.
2. **Were its children correctly updated?** The `scanObject` (nursery) and `markChildren` (old gen) functions must visit every pointer field.
3. **Was its size calculated correctly?** `getObjectSize()` must match the actual [object layout](/docs/memory-model#object-layout): if it's too small, the GC corrupts adjacent objects.
4. **Is the pointer in the right region?** `isInFromSpace()` vs `isInToSpace()` should correctly classify the pointer.
5. **Which thread owns this memory?** Check the `ThreadLocalHeap` bounds.

The test suite uses RapidCheck (property-based testing) to verify three core properties:

- **Preservation**: GC preserves all reachable objects with correct values.
- **Collection**: GC reclaims unreachable objects.
- **Stability**: Multiple GC cycles maintain correctness.

When a property test fails, RapidCheck provides a reproduction string (`--reproduce <string>`) that reliably replays the minimal failing case.
