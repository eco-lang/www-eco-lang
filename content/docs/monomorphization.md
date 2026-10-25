---
title: "Monomorphization"
description: "How Eco turns polymorphic Elm into one specialized copy of each function per concrete type, by re-running the type checker's unifier for every use, so that native code can store numbers unboxed."
section: "The compiler"
sectionOrder: 2
order: 4
---

A function that works for any type has to become one copy per type, because native code needs to know how big a value is and where its bits live. Elm's `identity : a -> a` is one function in JavaScript, where every value is a reference. In Eco an `Int` is a 64-bit integer passed in a register and a `String` is a pointer to the heap, so `identity` at `Int` and `identity` at `String` are different machine code. Monomorphization makes those copies, and it does it by running the type checker's own unifier again, once for each use.

> **Background**
> - [Specialization](/docs/glossary#specialization): one copy of a function for one concrete type.
> - [Boxed and unboxed](/docs/glossary#boxed-and-unboxed): a boxed value is a pointer to a heap object; an unboxed one is the raw number itself.
> - Union-find: a structure that keeps track of which things have been proved equal, by grouping them into sets.

## One copy per type

Take a small program with two polymorphic functions:

```elm
identity2 : a -> a
identity2 x =
    x


add : number -> number -> number
add a b =
    a + b


main =
    let
        i = identity2 42
        s = identity2 "hi"
        n = add 1 2
        f = add 1.5 2.5
        ints = List.map double [ 1, 2, 3 ]
        lens = List.map String.length [ "a", "bb" ]
    in
    ...
```

With inlining switched off, so that every copy stays visible, Eco produces these function signatures (trimmed to the name and type):

```mlir
Poly_identity2_$_1 : (!eco.value) -> (!eco.value)
Poly_add_$_2       : (i64, i64) -> (i64)
List_map_$_4       : (!eco.value, !eco.value) -> (!eco.value)
List_map_$_6       : (!eco.value, !eco.value) -> (!eco.value)
Poly_identity2_$_7 : (i64) -> (i64)
Poly_add_$_8       : (f64, f64) -> (f64)
```

`identity2` has two copies: one for `String`, taking and returning `!eco.value` (a boxed value), and one for `Int`, taking and returning a raw `i64`. `add` has one copy over 64-bit integers, whose body is `eco.int.add`, and one over 64-bit floats, whose body is `eco.float.add`. `List.map` has two copies, one for each list it is used on: the first maps `String`s to `Int`s, the second `Int`s to `Int`s, and code inside each knows whether list elements are stored unboxed.

The names follow one pattern, `Module_name_$_N`. The number is the specialization's position in a registry shared by the whole program, so it says nothing about the type; it only has to be unique. Every reference to a specialization is that number, which makes the result a closed graph: every reference points at an entry that exists.

At default settings the small copies disappear. The inliner that runs after monomorphization replaces `identity2 42` by `42` and `add 1 2` by a single `eco.int.add`, and the prune that follows removes the specializations nothing calls any more. Monomorphization creates the copies; later steps decide which survive.

This is the approach of MLton and of Rust generics and C++ templates, and the opposite of OCaml and, by default, GHC, which compile one copy of a polymorphic function over a uniform boxed representation. Copying costs code size and compile time. We think it is the right trade for Elm, because the whole program is known and unboxed numbers depend on it.

## Specialization is type inference, run again

The type checker has proved the program well typed, but it has not said what each type variable inside a polymorphic body becomes at one particular use. Eco answers that question with the type checker's own machinery. Each request to specialize one function at one concrete type is a demand. For each demand, Eco loads the function's definition into a fresh, empty store, states the demanded type as the first fact, and runs the unifier over the body. Every function the body mentions becomes a further demand, at whatever concrete type the unifier worked out for it. The process starts from `main` and ends when no demand is left.

The store is a union-find structure. Each type variable is one point; unifying two types merges their points into one group; and a group can be bound to a concrete type. Because every occurrence of a variable is the same point, a fact learned anywhere in the body reaches every place that variable appears, whatever order the facts arrive in. That matters in Elm, where concreteness often flows backwards, from a consumer to its producer: a list built in one place learns that it holds `Float`s only where it is later summed into a `Float`. A merging store handles that direction with no extra machinery.

Each demand gets a fresh store, so one specialization's facts can never bind a variable in another. Under a real unifier such a leak would be fatal, because a wrong binding becomes a wrong memory layout.

The order in which demands are processed does not change the result. Each store is independent of order, and the registry files each demand under a key, so two demands for the same function at the same type share one entry. The key compares types up to what code generation can see. A type variable that nothing ever fixed, such as the element type of an empty list passed to `List.length`, is always boxed, so all such variables compare equal regardless of their internal numbers; otherwise every demand would split into identical copies.

## `number` stays open until the end

Elm's `number` can be `Int` or `Float`, and the right answer often appears late. Eco therefore decides it in exactly one place: the prune that runs once the demand list is empty. Until then a `number` that nothing has fixed stays open, and the prune turns every one still open into `Int`, which is Elm's own default. Deciding at the end is what makes `Float` uses come out right, because an early guess of `Int` would be wrong exactly where a later consumer needs a `Float`.

This program exercises it:

```elm
main =
    let
        n = 30
        a = n + 1
        b = n * 1.5
        c = 10 + 3
    in
    text (String.fromInt a ++ " " ++ String.fromFloat b ++ " " ++ Debug.toString c)
```

The output starts like this (trimmed):

```mlir
%0 = "arith.constant"() {value = 30 : i64} : () -> i64
%1 = "arith.constant"() {value = 30.0 : f64} : () -> f64
%7 = "arith.constant"() {value = 10 : i64} : () -> i64
%8 = "arith.constant"() {value = 3 : i64} : () -> i64
%2 = "eco.int.add"(%7, %8) : (i64, i64) -> i64
%10 = "arith.constant"() {value = 1.5 : f64} : () -> f64
%3 = "eco.float.mul"(%1, %10) : (f64, f64) -> f64
%12 = "arith.constant"() {value = 1 : i64} : () -> i64
%4 = "eco.int.add"(%0, %12) : (i64, i64) -> i64
...
%18 = "eco.box"(%2) : (i64) -> !eco.value
%20 = "eco.call"(%18, %19) <{callee = @Elm_Kernel_Debug_toString_typed}> : (!eco.value, i64) -> !eco.value
```

The single `let n = 30` is used at `Int` (in `n + 1`) and at `Float` (in `n * 1.5`), so it is split into two constants, one of each type. A let-bound `number` used at several types is copied once per type, since one point in the store can hold only one answer. `c = 10 + 3` reaches only `Debug.toString`, which accepts any value, so nothing fixes its type; the prune closes it to `Int`, and the sum stays an unboxed integer until the one place it has to be boxed, the call into the `Debug` kernel.

When an open `number` meets a variable that accepts any value, as here, the number wins. Unifying it the other way would type an unboxed integer as a pointer.

## Lambda sets travel in the same store

Every function arrow loaded into a demand's store also carries a slot for a lambda set: the set of functions that can arrive at that place. The same unifier that merges types joins these sets. The sets become part of a specialization's key, so a higher-order function such as `List.map` gets one copy for each set of functions its callers pass, and inside each copy the calls through the function parameter can be made direct. [Lambda-set specialization](/docs/lambda-set-specialization) explains the analysis; the point here is that it costs monomorphization almost nothing extra, because the per-arrow typing and unification it needs were already being done.

## When the demand list never ends

The demand list is finite unless the program uses polymorphic recursion, which legal Elm can express through annotated mutual recursion. Such a program demands a function at a type that grows on every round, and nothing inside the algorithm can bound the growth. Two watchdogs stop it: one on the number of specializations of a single function, and one on the size of a demanded type. A trip is a property of the program, not a compiler bug, so it is reported to the user with the advice to add a concrete annotation at the recursive call.

## Two engines

Monomorphization has two engines. They share everything except how one definition is specialized: the demand list, the registry, the prune and the checks.

The *solver engine*, described above, is the default. The *substitution engine* carries a map from type variables to concrete types down each body. It works forward only, depends on the order in which it meets facts, and fails silently, and most of its machinery exists to retrofit the backward flow that a union-find store handles for free. In effect it is a second, weaker theory of Elm's types, which is why we do not use it by default.

The substitution engine stays for two reasons. First, there is a comparison mode that runs both engines on the same program and fails when their outputs differ, which checks the solver engine against an independent implementation. Second, it is lighter. When the compiler compiles itself while running as JavaScript under Node, the solver engine with lambda sets peaks at nearly 12 GB of V8 heap, and under a 12 GB cap the run never finishes: the garbage collector spirals. That bootstrap stage therefore uses the substitution engine and V8's maximum heap size. Its output only has to be a correct native compiler, which then compiles the compiler again with the default engine, so nothing shipped is built from the lighter engine's output ([The compiler compiles itself](/docs/bootstrap) describes that stage).

## Keeping it affordable

The compiler compiles itself, so the pass's cost on its own source sets the limit. Types are hash-consed: each distinct type is built once and shared, because otherwise the self-compile builds many times more type nodes than there are distinct types, and the garbage collector's cost grows with everything that survives.

Reachability is exact only after inlining, which orphans more specializations, so a second prune runs after the inliner. Pruned entries are emptied rather than renumbered, because lambda-set members, call edges and later passes all hold specialization numbers.

> **Designs we didn't use.** We considered querying a saved snapshot of the type checker's solved state instead of recording what monomorphization needs. It fails because the solved state has lost the instantiation edges that let-polymorphism needs, and it covers one module while monomorphization is whole-program. Its central idea, that the solver's roots are a type variable's identity, survived: the front end records exactly those roots.

## Further reading

- [Lambda-set specialization](/docs/lambda-set-specialization) — the analysis that runs inside monomorphization's store.
- [Global optimization](/docs/global-optimization) — inlining, pruning and call kinds after specialization.
- [Value representation](/docs/value-representation) — why `Int`, `Float` and `Char` can be stored unboxed.
- The full design document: [Monomorphization theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/monomorphization.md)
- Source: [`compiler/src/Compiler/MonoSolver`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Compiler/MonoSolver)
