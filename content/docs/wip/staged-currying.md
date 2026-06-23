---
title: "Staged Currying"
description: "How eco compiles curried functions efficiently by analyzing argument staging and normalizing calling conventions."
section: "Compilation"
sectionOrder: 3
order: 2
---

## The Problem

Every function in Elm is curried. A function `add : Int -> Int -> Int` is semantically a function that takes one `Int` and returns another function that takes one `Int` and returns an `Int`. You can partially apply it: `add 1` produces a new function.

Naive compilation would honor this literally: each argument creates a new closure:

```
add(1)      → allocate closure capturing 1, return it
result(2)   → allocate nothing, compute 1 + 2, return 3
```

That's two function calls and a heap allocation for what should be a single integer addition. When `add` is called with both arguments at once (which it almost always is), this overhead is wasted.

Staged currying solves this by analyzing how functions are actually used and generating code that takes multiple arguments at once when possible, while still supporting partial application when needed.

## Staging Signatures

A **staging signature** describes how a function groups its arguments:

- `[3]`: Take all 3 arguments at once, return the result.
- `[2, 1]`: Take 2 arguments, return a closure that takes 1 more.
- `[1, 1, 1]`: Fully curried: each argument produces a new closure.

For a function written as `\a b -> \c -> body`:
- The programmer wrote two lambda nesting levels: one taking `a, b` and one taking `c`.
- The natural staging is `[2, 1]`: the first stage accepts 2 arguments, returns a closure for the remaining 1.

The staging signature determines the calling convention: how many arguments the generated native function accepts directly, and at what points it creates closures for the remaining arguments.

### Real-World Example

```elm
map2 : (a -> b -> c) -> List a -> List b -> List c
map2 f xs ys = ...
```

In practice, `map2` is almost always called with all three arguments. Staging `[3]` means the generated code takes all three at once: no intermediate closures. If someone writes `map2 f`, partial application is handled by a wrapper that captures `f` and waits for `xs` and `ys`.

## Global Optimization: Where Staging Happens

Staging analysis runs in the **Global Optimization (GlobalOpt)** pass, after [monomorphization](/docs/monomorphization). This separation is deliberate: monomorphization handles type specialization without worrying about calling conventions, and GlobalOpt handles all ABI decisions without worrying about polymorphism.

GlobalOpt runs several phases:

### Phase 0: Inlining and Simplification

Small functions are inlined. This can expose new optimization opportunities and simplify staging analysis.

### Phase 0.5: Wrap Top-Level Callables

Ensures all top-level function-typed values are represented as closures before staging analysis begins. Bare kernel function references and global variable references are wrapped in alias closures so the staging solver has a uniform input.

### Phase 1: Build Staging Graph

Constructs a constraint graph connecting all the places where function values are produced and consumed (see [The Staging Solver](#the-staging-solver) below). This graph captures data flow: which closures flow to which call sites, which branches must agree on a staging signature, and which variables alias the same function value.

### Phase 2: Solve Staging

Runs a union-find solver over the constraint graph to group connected producers and slots into equivalence classes. Within each class, majority voting picks the canonical staging signature. This resolves the [branch problem](#the-branch-problem) and propagates staging decisions across the entire program.

### Phase 3: Rewrite with Staging

Applies the solver's decisions by eta-wrapping closures whose natural staging differs from the canonical one. After this phase, all closures have types matching their parameter counts.

### Phase 4: Annotate Call Metadata

Computes `CallInfo` metadata that the [MLIR code generator](/docs/code-generation) needs for each call site:

```elm
type alias CallInfo =
    { callModel : CallModel           -- FlattenedExternal or StageCurried
    , stageArities : List Int         -- Full staging signature
    , isSingleStageSaturated : Bool   -- All args provided in one call?
    , initialRemaining : Int          -- PAP's remaining arity
    , remainingStageArities : List Int
    }
```

The `CallModel` distinguishes kernel functions (which always take all arguments at once, `FlattenedExternal`) from user-defined functions (which respect staging, `StageCurried`).

## The Branch Problem

When a `case` or `if` expression returns a function, different branches may have different natural stagings:

```elm
chooser : Bool -> (Int -> Int -> Int)
chooser b =
    if b then
        \x y -> x + y        -- natural staging: [2]
    else
        \x -> \y -> x * y    -- natural staging: [1, 1]
```

The first branch creates a function taking two arguments at once. The second creates a function taking one argument and returning a closure for the second. The caller of `chooser` can't know which branch was taken, so it can't know how to invoke the result.

This violates **GOPT_003**: all branches of a case/if that return functions must have compatible staging signatures.

## The Staging Solver

The branch problem is actually a special case of a more general challenge: staging must be consistent across the entire program, not just within a single `case` expression. A function value can flow through variable bindings, function parameters, record fields, and data structure elements before it's eventually called. Every location it passes through must agree on the same staging signature.

eco solves this with a **graph-based constraint solver** that propagates staging decisions across the entire program.

### Producers and Slots

The solver models two kinds of entities:

- **Producers**: Every closure or function definition that creates a function value. Each producer has a *natural segmentation* determined by its parameter structure (e.g., `\x y -> \z -> body` has natural segmentation `[2, 1]`).

- **Slots**: Every location where a function value can be stored: variable bindings, function parameters, closure captures, record fields, case/if branch results, tuple elements, etc.

When a producer flows to a slot (e.g., a closure is assigned to a variable), the solver creates an edge connecting them. When two slots must have the same staging (e.g., both branches of an `if` expression flow to the same result), the solver **unifies** them into the same equivalence class.

### Solving with Union-Find

The solver uses a union-find data structure to build equivalence classes:

1. **Build the graph**: Walk the entire program, creating producer and slot nodes and edges for every data flow path.
2. **Unify connected nodes**: When a producer flows to a slot, or when two slots must agree (e.g., branches of a case expression), merge them into the same class.
3. **Majority vote**: Within each equivalence class, collect the natural segmentations from all producers. The most common segmentation wins. Ties are broken by preferring larger first groups (more arguments at once = fewer intermediate closures).
4. **Rewrite**: Producers whose natural segmentation differs from the canonical one get eta-wrapped to match.

### Example: Variable Propagation

```elm
f = \x y -> x + y    -- Producer P1, natural seg [2]
g = f                 -- Slot S1
h = g                 -- Slot S2
r = h 1 2             -- Call site: needs staging for h
```

The graph connects: P1 → S1 → S2. After solving, the equivalence class `{P1, S1, S2}` has canonical staging `[2]`. The call site at `h 1 2` looks up the staging for S2 and finds `[2]`.

### Example: Branch Resolution

The `chooser` example from above is solved automatically by the graph:

```elm
chooser b =
    if b then
        \x y -> x + y      -- Producer P1, natural seg [2]
    else
        \x -> \y -> x * y   -- Producer P2, natural seg [1, 1]
```

Both branches flow to the same if-result slot, so P1 and P2 end up in the same equivalence class. Majority voting picks `[2]` (tie broken by larger first group). P2 gets eta-wrapped to `[2]`.

### Eta-Wrapping

To convert a `[1, 1]` function to `[2]`, the solver wraps it:

```elm
-- Original [1,1]: \x -> \y -> x * y
-- Wrapped to [2]: \x y -> (\x -> \y -> x * y) x y
```

The wrapper takes both arguments at once and immediately applies them to the original function. At runtime, the intermediate closure is never allocated: the wrapper calls through directly.

### Worked Example

```elm
process : Int -> (Int -> Int -> Int)
process n =
    case n of
        0 -> \x y -> x              -- staging [2]
        1 -> \x -> \y -> y          -- staging [1, 1]
        2 -> \x y -> x + y          -- staging [2]
        _ -> \x -> \y -> x - y      -- staging [1, 1]
```

All four branches flow to the same case-result slot. The equivalence class has four producers: two with `[2]` and two with `[1, 1]`. Tie-breaker: `[2]` wins (larger first group = fewer allocations). Branches 1 and 3 (the `[1, 1]` cases) get eta-wrapped to `[2]`. The caller always sees a function that takes two arguments at once.

### The Staging Subsystem

The staging solver is implemented in `compiler/src/Compiler/GlobalOpt/Staging/` as a set of focused modules:

| Module | Purpose |
|--------|---------|
| `GraphBuilder` | Builds the constraint graph from the monomorphized program |
| `Solver` | Union-find solver with majority voting |
| `Rewriter` | Applies the solution by eta-wrapping non-conforming producers |
| `ProducerInfo` | Computes natural segmentations for each producer |
| `UnionFind` | Union-find data structure for equivalence classes |

## Kernel Functions

[Kernel functions](/docs/kernel-functions) (runtime primitives in C++) have fixed ABIs: they always take all arguments at once (`FlattenedExternal` call model). They cannot be stage-curried.

When a kernel function is partially applied in Elm code, a PAP (partial application) wrapper is generated:

```elm
-- Elm code:
mappedList = List.map f

-- At runtime:
-- A PAP closure is created that captures f
-- When called with a list argument, it invokes List.map(f, list)
```

The wrapper accumulates arguments until all are available, then calls the kernel function with everything at once.

## Why This Separation Matters

By isolating staging in GlobalOpt:

- **[Monomorphization](/docs/monomorphization)** stays simple: it just specializes polymorphic code and preserves Elm's curried type structure. No closure wrappers, no staging decisions.
- **GlobalOpt** is the single place where all calling-convention complexity lives. It flattens types, normalizes branches, and computes metadata.
- **[MLIR codegen](/docs/code-generation)** is straightforward: it switches on `callInfo.callModel` and uses pre-computed arities. No independent staging analysis.

This three-way separation means each pass is easier to understand, test, and debug in isolation. A staging bug is always in GlobalOpt, never in monomorphization or codegen.
