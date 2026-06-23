---
title: "Type Preservation"
description: "How eco preserves and exploits type information from Elm source through every compilation phase to native code."
section: "Architecture"
sectionOrder: 2
order: 2
---

## The Problem

The standard Elm compiler discards types after type checking. This is fine for JavaScript, which is a dynamically typed language and doesn't need compile-time type information at code generation time.

Native code is different. To generate efficient machine code, the compiler needs to know:

- **Memory layout**: How many bytes does a record occupy? Which fields can be stored inline?
- **Unboxing**: Can this `Int` be kept in a register, or must it be heap-allocated?
- **Machine operations**: Should `+` emit an integer add or a floating-point add?
- **Debug printing**: How should `Debug.log` format this value at runtime?

eco's solution is **type preservation**: type information flows through every compilation phase, from Elm's canonical types all the way down to LLVM IR.

```
Can.Type (from type checker)
    ↓  PostSolve fixes incomplete types
Can.Type (complete)
    ↓  Typed Optimization attaches types to every expression
TOpt.Expr with Can.Type
    ↓  Monomorphization specializes to concrete types
MonoType (MInt, MFloat, MList MonoType, ...)
    ↓  MLIR Generation maps to IR types
MlirType (i64, f64, !eco.value, ...)
    ↓  EcoToLLVM
LLVM types
```

## PostSolve: Completing the Types

After the standard Elm type solver runs, some expressions have incomplete types. The PostSolve pass fixes these before the typed optimization phase.

### Group A vs Group B Expressions

Expressions fall into two groups based on how the type solver handles them:

- **Group A**: Expressions whose types are fully constrained by their context: `Int` literals in arithmetic, `Call`, `If`, `Case`, `Binop`, `Access`, `Update`. The solver computes meaningful types for these.
- **Group B**: Expressions whose types are not directly constrained: `Str`, `Chr`, `Float`, `Unit`, `List`, `Tuple`, `Record`, `Lambda`, `Let`. These get synthetic type variables that need structural computation.

For Group B expressions, PostSolve computes the type from structure. A `List` expression gets type `List elemType` where `elemType` comes from its first element. A `Lambda` gets a function type built from its argument types and body type. A `Let` gets the type of its body.

### Kernel Type Inference

Kernel functions (`VarKernel`) are runtime primitives implemented in C++. They don't have type annotations in Elm source, so PostSolve infers their types through two mechanisms:

**Alias seeding**: When an Elm definition is a direct alias for a kernel function, the definition's type annotation provides the kernel's type:

```elm
-- The type annotation on `add` seeds Kernel.Basics.add's type
add : Int -> Int -> Int
add = Kernel.Basics.add
```

**Usage inference**: When a kernel function is called, its type is inferred from the argument types and the solver's result type for the call expression:

```elm
-- PostSolve sees the call and infers:
-- Kernel.List.map : (Int -> String) -> List Int -> List String
result = Kernel.List.map toString [1, 2, 3]
```

PostSolve uses a "first-usage-wins" strategy: once a kernel function's type is recorded, subsequent usages don't override it. This prevents conflicts when the same kernel function is used at different concrete types across the program (monomorphization handles that later).

### One-Way Type Unification

PostSolve includes a one-way unifier for matching polymorphic scheme types against concrete types. This is used when inferring kernel types from constructor arguments and binary operator operands:

```
unifySchemeToType(TVar "a", Int)
    → Just { "a" → Int }

unifySchemeToType(TType List [TVar "a"], TType List [String])
    → Just { "a" → String }
```

The unifier is one-way: it matches a polymorphic scheme against a concrete type, computing a substitution. It doesn't perform full bidirectional unification: that's the type solver's job.

## TypedOptimized AST

The Typed Optimization pass transforms the Canonical AST into a new representation where **every expression carries its type**:

```elm
type Expr
    = Bool A.Region Bool Can.Type
    | Int A.Region Int Can.Type
    | Str A.Region String Can.Type
    | VarLocal Name Can.Type
    | VarGlobal A.Region Global Can.Type
    | VarKernel A.Region Name Name Can.Type
    | Call A.Region Expr (List Expr) Can.Type
    | Function (List (Name, Can.Type)) Expr Can.Type
    | If (List (Expr, Expr)) Expr Can.Type
    | Case Name Name (Decider Choice) (List (Int, Expr)) Can.Type
    -- Every variant carries Can.Type as its last argument
```

A `typeOf` function can extract the type from any expression by pattern matching on the last argument. This makes type-directed transformations straightforward in later passes.

### What Changes from Canonical

Beyond attaching types, the Typed Optimization pass also:

- **Compiles pattern matching to decision trees**: Elm's `case` expressions with nested patterns become efficient `Decider` trees with `Leaf`, `Chain`, and `FanOut` nodes. This avoids redundant tests at runtime.
- **Tracks container hints**: Destructuring paths carry hints (`HintList`, `HintTuple2`, `HintCustom`) that tell later passes what kind of projection operation to use.
- **Builds dependency graphs**: `LocalGraph` and `GlobalGraph` track which definitions reference which, enabling dead code elimination and ordered processing.
- **Marks tail calls**: Tail-recursive functions are identified for loop-based code generation.

### Example Transformation

Given this Elm source:

```elm
add : Int -> Int -> Int
add x y = x + y
```

The TypedOptimized output (conceptually) is:

```elm
Define
    (Function
        [("x", Int), ("y", Int)]
        (Call region
            (VarKernel region "Basics" "add" (Int -> Int -> Int))
            [VarLocal "x" Int, VarLocal "y" Int]
            Int)
        (Int -> Int -> Int))
    deps
    (Int -> Int -> Int)
```

Every subexpression (the function, the call, each variable reference) carries its type. This is the input to [Monomorphization](/docs/monomorphization).

## What Type Preservation Enables

### Unboxing Optimization

With concrete types known at every point, the compiler can identify where primitive values (Int, Float, Char) can be stored directly in machine registers or inline in data structures, rather than as heap-allocated boxed objects. A `List Int` can store its elements as raw 64-bit integers alongside the list spine, avoiding a pointer chase per element. See [Monomorphization § Layout Computation](/docs/monomorphization#layout-computation) for how layouts are computed.

### Type-Specific Machine Operations

The type flow enables generating different machine code for different types. `x + y` where `x : Int` emits an integer add instruction (`arith.addi`), while `x + y` where `x : Float` emits a floating-point add (`arith.addf`). Without type information, the compiler would need runtime dispatch.

### Runtime Type Table

Types that survive to MLIR generation are registered in a **TypeRegistry** during code generation. The complete type graph is emitted as an `eco.type_table` operation in the MLIR output. At runtime, this enables `Debug.log` to format any value with full type awareness, printing record field names, constructor names, and recursively formatting nested structures. See [Code Generation § Type Table](/docs/code-generation#type-table) for the implementation.
