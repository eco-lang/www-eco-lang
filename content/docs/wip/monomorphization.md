---
title: "Monomorphization"
description: "How eco eliminates polymorphism by specializing functions to their concrete type instantiations for native code generation."
section: "Compilation"
sectionOrder: 3
order: 1
---

## The Challenge

Elm supports parametric polymorphism. A function like `identity : a -> a` works with any type: you can call `identity 42` or `identity "hello"` and the same definition handles both. In JavaScript, this is free: everything is a pointer-sized value and the runtime figures out the rest.

Native code doesn't have that luxury. Machine instructions operate on concrete types: 64-bit integers, 64-bit floats, pointers. The compiler must know the exact type at every call site to generate the right instructions.

There are two strategies for handling this:

1. **Box everything**: Represent all values uniformly as heap-allocated pointers (like JavaScript). Simple but slow: every integer access requires a pointer dereference.
2. **Monomorphize**: Generate specialized copies of each polymorphic function for every concrete type it's used with. More code, but each copy is fully optimized for its types.

eco chooses monomorphization. The cost is code size growth, but the benefit is that the generated code is as efficient as hand-written type-specific code, with no runtime dispatch overhead.

## The Worklist Algorithm

Monomorphization starts from `main` and discovers all needed specializations by following call edges:

```
1. Seed the worklist with main at its concrete type
2. While the worklist is non-empty:
   a. Dequeue a work item (function + concrete type)
   b. If already processed, skip
   c. Build a type substitution from the function's annotation to the concrete type
   d. Walk the function body, applying the substitution to every expression
   e. When a call to another function is encountered:
      - Compute the concrete type at this call site
      - Enqueue the callee at that type (if not already processed)
   f. Register the specialized function in the output
3. Return the fully specialized MonoGraph
```

This is demand-driven: only functions reachable from `main` at types actually used in the program get specialized. Dead code is naturally eliminated.

### Example

```elm
identity : a -> a
identity x = x

double : Int -> Int
double n = n + n

main = identity (double 21)
```

The worklist processes:

1. `main` at type `Int`: discovers call to `identity` at `Int -> Int` and `double` at `Int -> Int`
2. `identity<Int>`: specializes `identity` with substitution `{ a → Int }`
3. `double<Int>`: specializes `double` (already concrete, no substitution needed)

Each specialization gets a unique `SpecId`. The `SpecializationRegistry` maps `(function, concrete type) → SpecId` and prevents duplicate work.

## MonoType: The Concrete Type System

After monomorphization, all types are concrete `MonoType` values:

```elm
type MonoType
    = MInt                                         -- 64-bit signed integer
    | MFloat                                       -- 64-bit float
    | MBool                                        -- Boolean
    | MChar                                        -- Unicode code point
    | MString                                      -- Heap string
    | MUnit                                        -- Unit value
    | MList MonoType                               -- List with element type
    | MTuple TupleLayout                           -- 2-tuple or 3-tuple
    | MRecord RecordLayout                         -- Record with named fields
    | MCustom IO.Canonical Name (List MonoType)    -- Custom type (ADT)
    | MFunction (List MonoType) MonoType           -- Function type
    | MVar Name Constraint                         -- Constrained type variable
```

Most type variables are eliminated during specialization. The `MVar` variant survives only for kernel function ABIs that genuinely work on any type (see [Constraints](#constraints) below).

## Layout Computation

A key output of monomorphization is concrete **layouts** for compound types. These tell the code generator exactly how to allocate and access each structure.

### Record Layout

```elm
type alias RecordLayout =
    { fieldCount : Int
    , unboxedCount : Int
    , unboxedBitmap : Int        -- bitmask: which fields are stored inline
    , fields : List FieldInfo
    }

type alias FieldInfo =
    { name : Name
    , index : Int
    , monoType : MonoType
    , isUnboxed : Bool           -- True for MInt, MFloat stored inline
    }
```

For a record `{ name : String, age : Int, score : Float }`, the layout would have `fieldCount = 3`, `unboxedBitmap = 0b110` (age and score are unboxed), and field entries with concrete types and indices.

### Tuple Layout

```elm
type alias TupleLayout =
    { arity : Int                -- 2 or 3
    , unboxedBitmap : Int
    , elements : List (MonoType, Bool)  -- (type, isUnboxed)
    }
```

### Constructor Layout

Custom type constructors also get concrete layouts:

```elm
type alias CtorLayout =
    { name : Name
    , tag : Int
    , fields : List FieldInfo
    , unboxedCount : Int
    , unboxedBitmap : Int
    }
```

These layouts are computed during monomorphization and stored in the `MonoGraph`. The MLIR code generator consumes them directly: it never re-derives layouts from type definitions.

### Unboxing Rules

Only `Int`, `Float`, and `Char` are stored unboxed (inline) in heap structures. `Bool` is always boxed as an `!eco.value` (True and False are embedded pointer constants, see [Memory Model § Embedded Constants](/docs/memory-model#embedded-constants)). `String` and all compound types are always boxed as heap pointers.

The unboxed bitmap is a bitmask indicating which fields in a container are stored inline rather than as pointers. This bitmap is stored in the heap object's header and used by both the code generator (for correct projection) and the garbage collector (to distinguish pointers from raw values during tracing). See [Heap Representation](/docs/heap-representation) for the full picture of how these layout decisions map to the four representation models (Logical, SSA, ABI, Heap), and [Memory Model § Object Layout](/docs/memory-model#object-layout) for the runtime memory layout.

## Constraints

Type variables in monomorphized code carry constraints:

```elm
type Constraint
    = CEcoValue     -- Always boxed: any heap pointer
    | CNumber       -- Must resolve to Int or Float
```

**`CEcoValue`** marks type variables in [kernel function](/docs/kernel-functions) ABIs that accept any boxed value. These survive to MLIR codegen where they become `!eco.value` (the generic heap pointer type). For example, `List.cons` takes any value and a list, and its first argument is `CEcoValue` regardless of the element type. See [Kernel Functions § Three ABI Modes](/docs/kernel-functions#three-abi-modes) for the full details of how kernel ABIs are determined.

**`CNumber`** marks Elm's `number` typeclass (used by arithmetic operations). These *must* be resolved to either `MInt` or `MFloat` before code generation. Any remaining `CNumber` at codegen time is a compiler bug: it means the monomorphizer failed to determine whether an arithmetic operation is on integers or floats. For number-polymorphic kernels that can't resolve `CNumber` statically, the [NumberBoxed](/docs/kernel-functions#numberboxed-number-polymorphic) ABI mode handles runtime dispatch.

## Closure Capture Analysis

When monomorphizing lambda expressions, the pass computes which variables are captured from the enclosing scope:

```
For: \x -> x + y    (where y is defined in outer scope)
Captures: [(y, MInt)]
Parameters: [(x, MInt)]
```

The list of captures and their types become part of the closure's layout, telling the code generator what values to store when creating the closure at runtime. See [Code Generation § Closures](/docs/code-generation#closures) for how closures are implemented.

## The Specialization Registry

The registry prevents duplicate specialization and provides a stable mapping between function identities and numeric IDs:

```elm
type SpecKey = SpecKey Global MonoType (Maybe LambdaId)
type alias SpecId = Int

type alias SpecializationRegistry =
    { nextId : Int
    , mapping : Dict SpecKey SpecId
    , reverseMapping : Dict SpecId (Global, MonoType, Maybe LambdaId)
    }
```

The `LambdaId` component handles anonymous closures that need separate specializations. A lambda inside a polymorphic function may be specialized at different types, and each specialization gets its own `SpecId`.

## Trade-offs

Monomorphization increases code size: `List.map` used with three different function types generates three copies. In practice, this growth is bounded because:

- Elm programs have finite type instantiations (no infinite type recursion)
- Dead code is naturally eliminated (only reachable specializations are generated)
- The functions that are heavily polymorphic (like `List.map`) are typically small

The performance benefit is substantial: no boxing overhead, no runtime type dispatch, and the optimizer sees fully typed code. This is the same strategy used by Rust and (partially) by OCaml's flambda2, and it's the right trade-off for a compiled functional language targeting native performance.

## What Comes Next

Monomorphization is **staging-agnostic**: it preserves Elm's curried type structure. A function `Int -> Int -> Int` remains `MFunction [Int] (MFunction [Int] Int)`, nested, matching Elm's semantics. All calling-convention decisions (how to group arguments, when to create closures) are deferred to [Global Optimization and Staged Currying](/docs/staged-currying).

This separation keeps the monomorphizer focused on one job: type specialization. It doesn't need to know about calling conventions, closure staging, or ABI normalization.
