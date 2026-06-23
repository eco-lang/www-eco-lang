---
title: "Kernel Functions"
description: "How eco calls C++ runtime primitives from compiled Elm code, including compiler intrinsics and three ABI modes for handling polymorphism at function boundaries."
section: "Compilation"
sectionOrder: 3
order: 4
---

## What Are Kernel Functions?

Kernel functions are C++ implementations of Elm's core library operations such as `List.map`, `String.append`, `Basics.modBy`, and so on. Unlike user-defined functions that the compiler monomorphizes to concrete types, kernels have **fixed C++ implementations** that must work across multiple type instantiations.

This creates a fundamental tension. The Elm type system says `List.cons : a -> List a -> List a` works with any element type. But C++ doesn't have Elm-style polymorphism. The C++ `Elm_Kernel_List_cons` function has a concrete signature that must handle integers, strings, records, and anything else the programmer puts in a list.

However, many core operations never reach a C++ kernel at all. Compiler **intrinsics** intercept arithmetic, boolean, and bitwise operations during [code generation](/docs/code-generation) and emit direct MLIR operations, bypassing the kernel ABI entirely. The kernel calling mechanism described below only applies when intrinsics don't match.

## Intrinsics: The Fast Path

Before the compiler consults the kernel ABI, it checks whether the operation can be handled as a **compiler intrinsic**. Intrinsics are selected based on **monomorphized argument types**. After [monomorphization](/docs/monomorphization) resolves whether an operation is on `Int` or `Float`, the code generator can emit a type-specific MLIR operation directly.

For example, `Basics.add` with two `Int` arguments becomes:

```
%result = eco.int.add %lhs, %rhs : i64, i64 → i64
```

No function call, no boxing, no C++ kernel involved. The arguments stay as unboxed `i64` values in registers, and LLVM optimizes the operation further (constant folding, vectorization, etc.).

Intrinsics cover three categories:

**Arithmetic** (`Basics` module): `add`, `sub`, `mul`, `div`, `modBy`, `remainderBy`, `negate`, `abs`, `pow`, `sqrt`, `min`, `max`, for both `Int` and `Float` variants. Also trigonometric functions (`sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `log`) and type conversions (`toFloat`, `round`, `floor`, `ceiling`, `truncate`).

**Comparisons**: `lt`, `le`, `gt`, `ge`, `eq`, `neq`, for both `Int` and `Float`. Int comparisons produce `eco.int.lt` etc., float comparisons produce `eco.float.lt` etc.

**Boolean and bitwise** (`Basics` + `Bitwise` modules): `not`, `and`, `or`, `xor` for booleans; `and`, `or`, `xor`, `complement`, `shiftLeftBy`, `shiftRightBy`, `shiftRightZfBy` for bitwise integer operations.

This means the `NumberBoxed` kernels (`Basics.add`, `sub`, `mul`, `pow`) are rarely used in practice: intrinsics handle the concrete `Int` and `Float` cases directly after monomorphization. The C++ kernel path only activates when an operation remains polymorphic (which is rare after monomorphization) or when no intrinsic exists (e.g., `String.fromNumber`, `List.cons`).

## Three ABI Modes

The compiler determines how to call each kernel function based on its type signature. There are three modes:

### UseSubstitution (Monomorphic)

For kernels with no type variables in their signature:

```elm
Basics.modBy : Int -> Int -> Int
-- ABI: (i64, i64) → i64
```

The call-site types are applied directly. These kernels have fully typed ABIs, with no boxing or indirection needed. The C++ implementation receives and returns concrete machine types.

### PreserveVars (Polymorphic)

For kernels with type variables that remain polymorphic:

```elm
List.cons : a -> List a -> List a
-- ABI: (!eco.value, !eco.value) → !eco.value
```

Type variables become `!eco.value`, the generic heap pointer type. The C++ implementation receives boxed values and works through the uniform pointer representation. This is the most common mode for collection operations.

### NumberBoxed (Number-Polymorphic)

For kernels that are polymorphic over Elm's `number` type (Int or Float):

```elm
Basics.add : number -> number -> number
-- ABI: (!eco.value, !eco.value) → !eco.value
```

The `number` constraint could resolve to either Int or Float. Rather than generating two C++ implementations, the kernel receives a boxed value and dispatches by checking the runtime type tag:

```cpp
// Simplified: Basics.add dispatches on runtime tag
if (tag == Tag_Int) {
    return boxInt(unboxInt(a) + unboxInt(b));
} else {
    return boxFloat(unboxFloat(a) + unboxFloat(b));
}
```

The number-boxed kernels are: `Basics.add`, `Basics.sub`, `Basics.mul`, `Basics.pow`, and `String.fromNumber`.

## ABI Mode Selection

The compiler selects the ABI mode during [monomorphization](/docs/monomorphization) based on the kernel's type signature:

1. If the kernel is in an always-polymorphic module (e.g., `Debug`): **PreserveVars**
2. If the type has no free type variables: **UseSubstitution**
3. If the type has `number`-constrained variables and the kernel is in the number-boxed list: **NumberBoxed**
4. Otherwise: **PreserveVars**

This selection happens once per kernel function and determines the calling convention used at every call site.

## Boxing at Call Boundaries

When the call site has unboxed values but the kernel expects boxed `!eco.value`, the [code generator](/docs/code-generation) inserts boxing and unboxing operations:

```
-- Elm: List.cons 42 myList
-- Call-site types: Int → List Int → List Int
-- Kernel ABI: (!eco.value, !eco.value) → !eco.value

%boxed_42 = eco.box %int_42 : i64 → !eco.value     -- box the Int
%result = call @Elm_Kernel_List_cons(%boxed_42, %list)
-- result is !eco.value, used as-is (lists are always boxed)
```

When the kernel returns a boxed value but the call site needs an unboxed result:

```
-- Elm: Basics.modBy 10 n  (monomorphic kernel, no boxing needed)
%result = call @Elm_Kernel_Basics_modBy(%ten, %n) : (i64, i64) → i64
-- result is already i64, no unboxing needed
```

The boxing/unboxing is determined entirely by the ABI mode; the code generator never guesses. See [Heap Representation § Boundaries and Transitions](/docs/heap-representation#boundaries-and-transitions) for the general model of how values cross between representations.

## Type Inference for Kernels

Kernel function types are inferred during the [PostSolve](/docs/type-system) phase. This is trickier than it sounds because of aliasing.

In Elm's core libraries, many kernel functions are exposed through Elm wrappers:

```elm
-- In String.elm:
fromFloat : Float -> String
fromFloat = Elm.Kernel.String.fromNumber
```

Here `fromFloat` is an alias for the kernel function `String.fromNumber`, but with a more specific type (`Float` instead of `number`). The compiler must use the **definition's own type** (from the type solver), not the first-usage-wins type from the kernel environment. Otherwise, `fromFloat` would inherit `number -> String` instead of `Float -> String`, leading to incorrect boxing.

## Container Specialization

Some kernels benefit from element-aware specialization at the Elm wrapper level, even though the C++ ABI remains boxed.

`List.cons` is the primary example. The C++ kernel always uses the boxed ABI: it receives an `!eco.value` head and tail. But the Elm wrapper can be specialized per element type: `List_cons_Int`, `List_cons_String`, etc. This enables the [monomorphizer](/docs/monomorphization) to compute element-specific layouts, allowing **unboxed storage** in cons cells. A `List Int` stores its head as an inline `i64` rather than a pointer to a boxed integer.

The specialization happens at the Elm level (separate monomorphized wrappers per element type). The C++ kernel call inside each wrapper still uses the boxed ABI, but the wrapper knows the element type and can unbox/box at the boundary.

## C++ Implementation Patterns

### Boxed ABI (Polymorphic)

```cpp
// List.cons : a -> List a -> List a
extern "C" uint64_t Elm_Kernel_List_cons(uint64_t head, uint64_t tail) {
    auto* heap = ThreadLocalHeap::get();
    auto* cons = heap->allocate<Cons>();
    cons->head = Export::toPtr(head);
    cons->tail = Export::toPtr(tail);
    return Export::toHPointer(cons);
}
```

All parameters are `uint64_t` (the C representation of `!eco.value`). The function allocates on the [thread-local heap](/docs/memory-model#thread-local-heaps) and returns a logical pointer.

### NumberBoxed ABI

```cpp
// String.fromNumber : number -> String
extern "C" uint64_t Elm_Kernel_String_fromNumber(uint64_t boxedNum) {
    auto* ptr = Export::toPtr(boxedNum);
    if (ptr->header.tag == Tag_Int) {
        return String::fromInt(static_cast<ElmInt*>(ptr)->value);
    } else {
        return String::fromFloat(static_cast<ElmFloat*>(ptr)->value);
    }
}
```

The function receives a boxed value and dispatches on the runtime tag. This is the only place in eco where runtime type dispatch occurs; all other polymorphism is resolved by [monomorphization](/docs/monomorphization) at compile time.

### Unboxed ABI (Monomorphic)

```cpp
// Basics.modBy : Int -> Int -> Int
extern "C" int64_t Elm_Kernel_Basics_modBy(int64_t modulus, int64_t x) {
    if (modulus == 0) return 0;
    int64_t result = x % modulus;
    // Elm uses floored division semantics (not truncated C semantics)
    if ((result > 0 && modulus < 0) || (result < 0 && modulus > 0)) {
        result += modulus;
    }
    return result;
}
```

Fully typed parameters, with no boxing overhead. These kernels are as efficient as hand-written C++ for the specific types they handle.

## MLIR Integration

Kernel functions are **declared** (not defined) in the generated MLIR:

```
func.func private @Elm_Kernel_List_cons(!eco.value, !eco.value) → !eco.value
    attributes {is_kernel = true}
```

The `is_kernel` attribute marks these as external symbols resolved at link time against the C++ runtime library. The linker connects the MLIR-generated call sites to the C++ implementations.

The [code generator](/docs/code-generation) emits kernel declarations based on which kernels are actually used in the program. Unused kernels are never declared, keeping the generated module minimal.
