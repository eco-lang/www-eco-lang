---
title: "Code Generation"
description: "How eco generates native code through the ECO MLIR dialect and progressive lowering to LLVM."
section: "Compilation"
sectionOrder: 3
order: 3
---

## MLIR and Progressive Lowering

eco doesn't generate LLVM IR directly. Instead, it uses **MLIR** (Multi-Level Intermediate Representation), a compiler infrastructure from the LLVM project that supports multiple "dialects" of IR at different abstraction levels.

The idea is progressive lowering: start with high-level operations that match Elm's semantics, then lower them step by step to LLVM. Each step is a focused transformation that's easier to get right than a single giant translation.

```
MonoGraph (from Monomorphization + GlobalOpt)
    ↓
ECO Dialect (custom Elm operations)
    ↓  Bytes Fusion (where applicable)
    ↓  JoinPoint Normalization
    ↓  Control Flow to SCF
    ↓  CheckEcoClosureCaptures (verification)
    ↓  RC Elimination (verification)
    ↓  Undefined Function Check
LLVM Dialect (via EcoToLLVM)
    ↓
LLVM IR → Native Code
```

## The ECO Dialect

The ECO dialect defines MLIR operations for Elm's runtime semantics. Rather than expressing everything in terms of low-level memory operations, the initial IR uses high-level operations that capture programmer intent:

### Data Construction

| Operation | Purpose |
|-----------|---------|
| `eco.constant` | Embedded constants: Unit, True, False, Nil |
| `eco.string_literal` | String constants |
| `eco.box` / `eco.unbox` | Convert between primitives and heap objects |
| `eco.construct.list` | Construct a cons cell |
| `eco.construct.tuple2` / `tuple3` | Construct tuples |
| `eco.construct.record` | Construct a record |
| `eco.construct.custom` | Construct an ADT value |

### Data Access

| Operation | Purpose |
|-----------|---------|
| `eco.project.list_head` / `list_tail` | Destructure a list |
| `eco.project.tuple2` / `tuple3` | Project a tuple field |
| `eco.project.record` | Project a record field by index |
| `eco.project.custom` | Project an ADT field |
| `eco.get_tag` | Get the constructor tag from an ADT value |

### Control Flow

| Operation | Purpose |
|-----------|---------|
| `eco.call` | Function call (direct or indirect) |
| `eco.case` | Multi-way branch on constructor tag |
| `eco.joinpoint` / `eco.jump` | Local join points (for compiled pattern matching) |
| `eco.return` | Return from function |

### Closures

| Operation | Purpose |
|-----------|---------|
| `eco.papCreate` | Create a partial application (closure) |
| `eco.papExtend` | Apply more arguments to a closure |

### Type Mapping

[MonoTypes](/docs/monomorphization) map to MLIR types:

| MonoType | MLIR Type | Notes |
|----------|-----------|-------|
| `MInt` | `i64` | Unboxed 64-bit integer |
| `MFloat` | `f64` | Unboxed 64-bit float |
| `MBool` | `i1` | Unboxed boolean |
| `MChar` | `i32` | Unboxed Unicode code point |
| `MString` | `!eco.value` | Heap-allocated string |
| `MList _` | `!eco.value` | Heap-allocated list |
| `MTuple _` | `!eco.value` | Heap-allocated tuple |
| `MRecord _` | `!eco.value` | Heap-allocated record |
| `MCustom _ _ _` | `!eco.value` | Heap-allocated ADT |
| `MFunction _ _` | `!eco.value` | Closure (heap-allocated) |

The key distinction: primitives (`Int`, `Float`, `Bool`, `Char`) have their own MLIR types and can live in registers. Everything else is `!eco.value`, a tagged heap pointer (see [Memory Model § Logical Pointers](/docs/memory-model#logical-pointers)). For the full picture of how values transition between SSA types, ABI types, and heap storage, see [Heap Representation](/docs/heap-representation).

## Codegen Architecture

The MLIR code generator is organized into 11 focused modules:

| Module | Responsibility |
|--------|---------------|
| `Backend.elm` | Entry point, module assembly |
| `Context.elm` | Codegen state: SSA counters, variable mappings, type registry |
| `Types.elm` | MonoType → MlirType conversion |
| `Ops.elm` | MLIR operation builders |
| `Names.elm` | Symbol naming |
| `TypeTable.elm` | Type table generation for debug printing |
| `Intrinsics.elm` | [Compiler intrinsics](/docs/kernel-functions#intrinsics-the-fast-path) for arithmetic, boolean, and bitwise ops |
| `Patterns.elm` | Decision tree navigation and pattern test generation |
| `Expr.elm` | Expression lowering and call ABI (largest module) |
| `Lambdas.elm` | Lambda/closure processing, PAP wrappers |
| `Functions.elm` | Top-level node generation |

Processing order: build signatures for all specializations → generate each node's function body → process pending lambdas (hoisted closures) → generate main entry point → emit kernel function declarations → emit type table.

## Closures

Elm lambdas are hoisted to top-level functions during code generation. A lambda like:

```elm
let offset = 10
in List.map (\x -> x + offset) numbers
```

becomes a top-level function with `offset` as an explicit parameter, plus a closure that captures the value of `offset`:

```mlir
func.func @lambda_0(%offset: i64, %x: i64) -> i64 {
    %result = eco.int.add %offset, %x : i64
    eco.return %result : i64
}

-- At the call site:
%closure = eco.papCreate @lambda_0, arity=2, captured=[%offset]
-- The closure is passed to List.map, which calls it with each element
```

Partial application uses the same mechanism. `eco.papCreate` creates a closure with captured values, and `eco.papExtend` adds more arguments. When all arguments are provided (the closure is "saturated"), the underlying function is called directly. The `eco.papExtend` operation is lowered **inline** rather than as a runtime call, enabling LLVM to optimize saturated calls. Float arguments require `i64` ↔ `f64` bitcasts since closures store all captured values as uniform 64-bit slots.

For more on how the compiler eliminates generic closure wrappers and generates direct typed calls, see [Typed Closure Calling](/docs/typed-closure-calling).

## Type Table

The type table enables runtime debug printing (`Debug.log`) with full type awareness. During code generation, a `TypeRegistry` tracks all types encountered:

```elm
type alias TypeRegistry =
    { nextTypeId : Int
    , typeIds : Dict MonoTypeKey Int     -- MonoType → TypeId
    , typeInfos : List (Int, MonoType)   -- registered types
    , ctorLayouts : Dict TypeKey (List CtorLayout)
    }
```

Types are registered lazily, only when first encountered. Nested types are registered depth-first (child types before parents). The complete type graph is emitted as an `eco.type_table` operation with four arrays:

- **types**: Type descriptors (kind, sub-kind, references to fields/ctors)
- **fields**: Field info for records, tuples, and constructors
- **ctors**: Constructor info for custom types
- **strings**: Deduplicated name table for field and constructor names

At runtime, `eco_dbg_print_value(value, typeId)` looks up the type descriptor, dispatches on the type kind (Primitive, List, Tuple, Record, Custom, Function), and recursively formats nested structures using field names and constructor names from the string table.

## Lowering to LLVM

During MLIR generation, [Bytes Fusion](/docs/bytes-fusion) intercepts `Bytes.encode` and `Bytes.decode` calls and replaces the interpreter-style kernel with fused cursor-based operations when the combinator pattern is recognized. This happens as an alternative codegen path: when fusion isn't applicable, the standard kernel call is emitted.

After MLIR generation, several passes transform the ECO dialect toward LLVM:

### JoinPoint Normalization

Analyzes `eco.joinpoint` operations and classifies them for structured control flow lowering. A joinpoint is marked as an SCF candidate if it's looping (contains a self-jump), has a normalized continuation (starts with a jump to itself), and has either a simple case dispatch pattern or a single exit.

Joinpoints that match these criteria get `scf_candidate` and `scf_case_loop` attributes. The next pass consumes these attributes.

### Control Flow to SCF

Converts `eco.case` operations to MLIR's Structured Control Flow dialect, producing **expression-valued** case statements that match Elm's semantics.

Elm is expression-oriented: every `case` and `if` evaluates to a value. The SCF dialect represents this naturally:

```mlir
-- Before: eco.case as control flow
eco.case %flag [0, 1] result_types [i64] {
    eco.return %n : i64
}, {
    %doubled = eco.int.mul %n, %two : i64
    eco.return %doubled : i64
}

-- After: scf.if as expression (produces a value)
%result = scf.if %flag -> (i64) {
    %doubled = arith.muli %n, %two : i64
    scf.yield %doubled : i64
} else {
    scf.yield %n : i64
}
```

Two-way cases become `scf.if`. Multi-way cases (more than two alternatives) become `scf.index_switch`. Looping joinpoints marked by the previous pass become `scf.while`. Nested cases compose naturally as nested `scf.if`: the structure is preserved, not flattened to a CFG.

This is more than cosmetic. SCF preserves the expression structure that MLIR optimization passes can reason about, avoids introducing phi nodes for case results, and keeps debug information aligned with source structure.

### CheckEcoClosureCaptures

A verification pass that validates closure capture integrity. For each `eco.papCreate` operation, it checks that the number of captured values doesn't exceed the function's parameter count and that captured operand types match the corresponding parameter types. It also walks lambda function bodies to verify that no SSA value crosses function boundaries, catching bugs where a lambda uses a variable that wasn't properly captured.

### RC Elimination

A verification pass that confirms no reference counting operations exist in the IR. eco uses a tracing garbage collector (see [Garbage Collection](/docs/garbage-collection)), not reference counting. The six forbidden operations (`eco.incref`, `eco.decref`, `eco.decref_shallow`, `eco.free`, `eco.reset`, `eco.reset_ref`) should never appear. If any do, it's a codegen bug and compilation fails with clear error messages.

This pass is also a placeholder for future hybrid memory management strategies (Perceus-style RC, uniqueness types, arena allocation) that might validly use some of these operations.

### Undefined Function Check

Validates that every function called by `eco.call` has a corresponding `func.func` definition or declaration. In practice, this catches missing kernel function declarations: user-defined functions always have definitions. Indirect calls (through closures) are skipped since the callee isn't known at compile time.

### EcoToLLVM: Final Lowering

The main lowering pass converts all remaining ECO operations to the LLVM dialect. It's internally organized into 10 modules by concern:

| Module | Patterns | Concern |
|--------|----------|---------|
| Types | 2 | Constants, string literals |
| Heap | 17 | Boxing, allocation, construct/project |
| Closures | 4 | PAP create/extend, direct/indirect calls |
| ControlFlow | 5 | case, joinpoint, jump, return, get_tag |
| Arith | 59 | All arithmetic, comparison, bitwise, conversion ops |
| Globals | 3 | Global variables |
| ErrorDebug | 4 | Crash, expect, debug print, safepoints |
| Func | 1 | Kernel function lowering |

Key transformations:

- **`!eco.value` → `i64`**: The generic heap pointer type becomes a 64-bit integer (tagged pointer encoding, see [Memory Model § Logical Pointers](/docs/memory-model#logical-pointers)).
- **Heap allocation**: `eco.construct.*` operations become calls to C++ runtime functions (`eco_alloc_cons`, `eco_alloc_record`, etc.) that allocate on the thread-local heap.
- **Closure calls**: Saturated calls load the function pointer from the closure and call it with captured values plus new arguments. Unsaturated calls go through `eco_pap_extend`.
- **Embedded constants**: `eco.constant Unit` becomes the integer `1 << 40`, `True` becomes `3 << 40`, etc. No heap allocation needed. See [Memory Model § Embedded Constants](/docs/memory-model#embedded-constants).
- **Arithmetic**: [Compiler intrinsics](/docs/kernel-functions#intrinsics-the-fast-path) emit typed ECO operations (`eco.int.add`, `eco.float.mul`, etc.) that are lowered directly to MLIR arithmetic (`arith.addi`, `arith.mulf`). Division includes a zero-guard. Modulo uses floored semantics (Elm convention, not truncated C convention). Trigonometric functions lower to LLVM intrinsics (`llvm.sin`, `llvm.sqrt`). This covers ~59 operation patterns across integer, float, boolean, comparison, and bitwise categories.

After this pass, the module is valid LLVM dialect IR. LLVM takes it from there: optimization, register allocation, instruction selection, and machine code emission.
