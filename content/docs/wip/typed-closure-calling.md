---
title: "Typed Closure Calling"
description: "How eco eliminates generic evaluator wrappers for closures by generating direct typed function calls, enabling LLVM to optimize across closure boundaries."
section: "Compilation"
sectionOrder: 3
order: 6
---

## The Problem: Generic Evaluator Wrappers

In a naive compiled functional language, every closure call goes through a generic wrapper. The closure stores a pointer to a wrapper function with a uniform signature like `void* (*)(void*[])`. Calling the closure means:

1. Pack the arguments into a `void*[]` array.
2. Call the generic wrapper through the function pointer.
3. The wrapper unpacks the array, casts each element to the correct type, calls the actual function, and repacks the result.

This is an opaque barrier to optimization. The optimizer can't see through the generic wrapper: it doesn't know what function will be called, what types the arguments have, or what the function body does. Inlining is impossible. Register allocation is pessimized. Every closure call pays for the flexibility of handling any closure, even when the compiler knows exactly which closure it's dealing with.

## The Solution: Two Entry Points

For closures with captured values, eco generates **two entry points** instead of one generic wrapper:

### Fast Clone

```
lambda$cap(capture₁, capture₂, ..., param₁, param₂, ...) → result
```

Captures are explicit typed parameters. This is a normal function call with fully typed arguments, so LLVM can inline it, optimize register allocation, and see through the call boundary. Used when the closure's structure is known at compile time.

### Generic Clone

```
lambda$clo(closure_ptr, param₁, param₂, ...) → result
```

Takes the closure pointer plus typed parameters. Loads captures from the closure structure and calls the fast clone. Used when the closure's structure varies at runtime (e.g., different branches produce different closures).

**Zero-capture closures** (plain function references) need no cloning: the original function serves as its own entry point.

## Closure Kind Analysis

The compiler tracks what kind of closure each value might be. There are three states:

| State | Meaning | Call strategy |
|-------|---------|---------------|
| **Known** (specific ID) | Definitely this exact closure structure | Fast clone: unpack captures, call directly |
| **Heterogeneous** | One of several possible closure structures | Generic clone: pass closure pointer |
| **Unknown** | No information (analysis gap) | Generic clone (conservative) |

### Merging at Join Points

When control flow merges (if/case branches), closure kinds are merged:

- If all branches produce the same closure kind → **Known** (homogeneous).
- If branches produce different closure kinds → **Heterogeneous**.
- If any branch has no closure info → **Heterogeneous** (conservative).

This determines the call strategy at each call site.

## How It Works in Practice

### Homogeneous Case: Direct Calls

```elm
applyBoth f g x = f (g x)

main =
    applyBoth (\a -> a + 1) (\b -> b * 2) 5
```

The compiler knows exactly which closure `f` and `g` are at the call site in `main`. Both have known closure kinds. The generated code uses fast clones, direct typed function calls:

```
-- No wrappers. Direct typed calls.
lambda_add1$cap : (i64) → i64
lambda_mul2$cap : (i64) → i64

-- In applyBoth (when called from main):
%tmp = call @lambda_mul2$cap(%x)       -- direct, typed
%result = call @lambda_add1$cap(%tmp)  -- direct, typed
```

LLVM can inline both calls, producing a single computation equivalent to `(x * 2) + 1`.

### Heterogeneous Case: Closure Pointer

```elm
chooser : Bool -> (Int -> Int)
chooser b =
    if b then
        \x -> x + 1        -- closure kind A (no captures)
    else
        let offset = 10
        in \x -> x + offset -- closure kind B (captures offset)
```

A function receiving the result of `chooser` doesn't know which branch was taken. The closure kind is **heterogeneous**. The generated code uses generic clones:

```
-- Load evaluator from closure, call with closure pointer + args
%evaluator = load %closure.evaluator
%result = call %evaluator(%closure, %x)
```

The generic clone unpacks the captures from the closure struct and calls the fast clone internally. This adds one level of indirection compared to the homogeneous case, but avoids the generic `void*[]` packing entirely.

## ABI Cloning Pass

The **ABI cloning pass** runs during [Global Optimization](/docs/staged-currying#global-optimization-where-staging-happens) to handle a subtle case: when a function parameter receives closures with **different capture structures** from different call sites.

Consider:

```elm
apply : (Int -> Int) -> Int -> Int
apply f x = f x
```

If `apply` is called in one place with a closure capturing `[Int]` and in another with a closure capturing `[Int, String]`, the fast clone for `f` would need different capture unpacking code. The ABI cloning pass solves this by creating separate copies of `apply`, one for each distinct capture ABI:

```
apply$abi1 : handles closures with captures [Int]
apply$abi2 : handles closures with captures [Int, String]
```

Each clone has a fast path tailored to its specific capture structure. Call sites are rewritten to target the appropriate clone.

## Inline papExtend

When a closure receives additional arguments (partial application extension), the `eco.papExtend` operation is lowered **inline** rather than as a runtime function call. This means the compiler generates the argument-packing code directly at the call site, enabling LLVM to optimize saturated calls (where all arguments are available) into direct function calls.

One detail: closures store all captured values as 64-bit slots. Float arguments and results require `i64` ↔ `f64` bitcasts since the closure storage is uniform `i64`. These bitcasts are zero-cost at the machine level (just a register reinterpretation) but must be emitted correctly to satisfy MLIR's type system.

## MLIR Annotations

The closure analysis results are encoded as MLIR attributes on operations:

### `_closure_kind` on Closure-Producing Operations

```
%closure = eco.papCreate @fn ... {_closure_kind = 42}
```

Annotates each closure-producing operation with its closure kind ID (or "heterogeneous" if the kind varies).

### `_dispatch_mode` on Call Sites

```
eco.call %f(%args) {_dispatch_mode = "fast", _closure_kind = 42}
eco.call %f(%args) {_dispatch_mode = "closure"}
eco.call %f(%args) {_dispatch_mode = "unknown"}
```

| Mode | When used | Lowering |
|------|-----------|----------|
| `"fast"` | Known homogeneous closure | Unpack captures, call fast clone directly |
| `"closure"` | Known heterogeneous | Load evaluator, call generic clone with closure pointer |
| `"unknown"` | Analysis gap | Same as closure, plus diagnostic warning |

Every closure call must have a `_dispatch_mode`: its absence indicates a pipeline bug.

## Relationship to Staged Currying

Typed closure calling is **orthogonal** to [staged currying](/docs/staged-currying):

- **Staged currying** decides how many arguments each function stage accepts (the segmentation).
- **Typed closure calling** decides how captured values are passed at call sites (the ABI).

Both are resolved during Global Optimization, before [MLIR generation](/docs/code-generation). A function might have staging `[2, 1]` (take 2 args, return a closure for 1 more) and use the fast clone for the inner closure call. The two optimizations compose without interference.

## Benefits

1. **No wrapper overhead**: direct typed calls instead of generic unpack/repack through `void*[]`.
2. **Inlining**: LLVM can inline small closures when the fast clone is called directly.
3. **Register allocation**: captures as typed parameters instead of memory indirection through a closure struct.
4. **Branch prediction**: direct calls are more predictable than indirect calls through function pointers.
5. **Smaller generated code**: no generic wrapper functions needed for the common (homogeneous) case.
