---
title: "Lambda-set specialization"
description: "How Eco works out which functions can reach each call site, by attaching a set of functions to every function type during monomorphization, so that most calls through function values become direct calls."
section: "The compiler"
sectionOrder: 2
order: 5
---

In a higher-order language most calls go through a function value: `List.map f xs` calls whatever `f` happens to be. A call through an unknown closure has to read the closure at run time to find out what code to run and how many arguments it still wants. If the compiler can work out *which* functions can arrive at that call, and there is only one, it can call that function directly. Lambda-set specialization is how Eco works that out.

> **Background**
> - [Closure](/docs/glossary#closure): a function value together with the values it has captured.
> - [Lambda set](/docs/glossary#lambda-set): the set of functions that can reach one place that holds a function.
> - [Monomorphization](/docs/monomorphization): the pass that copies each function per concrete type; this analysis runs inside it.

## A set on every arrow

Two Elm values of type `Int -> Int` can come from different lambdas. The type checker does not tell them apart, but code generation wants to. So during monomorphization every function arrow in a type carries one more thing: a set of the functions that can be there. When the unifier merges two types, it also joins their sets, so a function value's identity flows wherever its type flows, with no separate dataflow analysis.

The sets also become part of each specialization's key. A higher-order function gets one copy for each set of functions its callers pass, and inside each copy the calls through its function parameter know their target.

Every consumer of the analysis asks one question: is this set a single known function? A set with one member can become a direct call. A set with two or more always uses the generic path, because Eco does not turn a function type into a sum over its members. The analysis is therefore judged on the single-member sets it finds, and on never claiming one falsely: a set that is missing a member looks smaller than it is, and a false singleton becomes a direct call to the wrong code.

## A direct call through a function parameter

```elm
twice : (a -> a) -> a -> a
twice f x =
    f (f x)


dup = twice

inc = adder 1

r3 = dup inc 10
```

`dup` is an alias, so the call is `twice inc 10`. The only function that ever reaches `twice`'s parameter `f` is `inc`, so its lambda set is `{inc}` and the specialization of `twice` knows it. With inlining switched off so that the copy stays visible, this is that specialization (trimmed):

```mlir
^bb0(%f: !eco.value, %x: i64):
  %2 = "eco.call"(%x) <{callee = @Stage_inc_$_3}> : (i64) -> i64
  %3 = "eco.call"(%2) <{callee = @Stage_inc_$_3}> : (i64) -> i64
  "eco.return"(%3) : (i64) -> ()
```

Both calls of `f` are now plain calls to `inc`'s code. The closure in `%f` is still passed, but nothing reads it: the set, not the value, says what code to run.

## On and off

The analysis has one switch, and it is on by default. Turning it off shows what it buys. In this program `pick` returns one of two lambdas, and `repeatApply` calls the result in a loop:

```elm
pick : Bool -> (Int -> Int)
pick flag =
    if flag then
        \x -> x + 1

    else
        \x -> x * 2


two = repeatApply (pick (step > 3)) 3 1
```

After the earlier passes have merged `pick`'s boundary, `pick` is one function of two arguments, and the value passed to `repeatApply` is `pick` applied to its first argument. That partial application is the only function that reaches `repeatApply`'s parameter, so the set has one member. Here is the call inside `repeatApply`'s loop with the analysis on (trimmed):

```mlir
%27 = "eco.papExtend"(%17, %19) {_call_kind = "singleton_fast",
        _fast_evaluator = @Lss_pick_$_1, _pap_prefix = 1, remaining_arity = 1}
        : (!eco.value, i64) -> i64
```

and with it off:

```mlir
%27 = "eco.papExtend"(%17, %19) {_call_kind = "generic_apply"} : (!eco.value, i64) -> i64
```

`singleton_fast` means the call jumps straight to `pick`'s code, passing it the one captured argument (the flag) from the partial application plus the new one. `generic_apply` means the runtime has to inspect the closure first: what function it holds, how many arguments it has, and how many it still needs.

Some calls stay generic, and should. In

```elm
fs = [ \x -> x + 1, \x -> x * 2, negate ]

three = List.foldl (\g acc -> g acc) 1 fs
```

three different functions can reach `g`, so its set has three members, and the call is made the generic way whether the analysis is on or off:

```mlir
%53 = "eco.papExtend"(%49, %41) {_call_kind = "segmentation_unknown"} : (!eco.value, i64) -> i64
```

## What it is worth

The best measurement is the compiler compiling itself, which is a large, very higher-order Elm program. We compared a compiler built with the lighter monomorphization engine, which has no lambda sets, against one built with the default engine and the analysis on, both compiling the same source. With lambda sets, roughly three quarters of the generic closure applications became direct or fast calls, and the share of calls with a statically known target rose from about 84% to about 94%.

The analysis is not free. It has been a large share of the compiler's own compile time, and on the compiler as a workload it has not been clear that the run time it saves outweighs that cost. The analysis and its solver have since been made much cheaper, but we have not repeated the cost-benefit measurement, so we claim no figure in either direction.

## Demand-driven, where the paper is staged

The design comes from Brandon and others, "Better Defunctionalization through Lambda Set Specialization" (PLDI 2023). Eco takes the paper's central idea, a set of functions on every arrow, solved by unification and used to specialize, but not its order of work.

The paper works in two passes. First it infers sets over the whole program, bottom-up in dependency order, and whatever a definition cannot know about its callers becomes a set *parameter* of that definition. Then a second pass runs top-down from the entry point and makes one copy of each definition for each set of concrete arguments its callers pass, filling the parameters in.

Eco does both inside monomorphization's list of demands. When a call to a global function is translated, Eco looks up a summary of that function, computed once and memoized: how its arrows' sets relate to one another. That is the bottom-up half. It then reads back the callee's type with the sets the call's arguments carry and files that as a new demand. That is the top-down half: a different set gives a different key, and so a different copy. Because demands start from `main`, code that nothing reaches is never analyzed at all.

Three things push Eco this way. Elm is polymorphic and the paper's language is not, so an arrow inside a polymorphic type has no concrete set until a specialization fixes the type; specializing by type and by set is one decision. Monomorphization already has everything the analysis needs, a store per demand, a unifier, a worklist and a registry of keys. And not holding an annotated copy of the whole program matters when the compiler compiles itself on a JavaScript heap.

The cost is that a summary is a fixed fact. A definition cannot hand an unknown to its callers to fill in, as the paper's parameters do. Where it cannot know, the set is recorded as "any function" or as unknown. Much of the lost precision comes back another way: the function's body is solved again in each specialization with the demand's concrete sets already in place, and two loads of the same annotation share their set slots.

Demands also arrive one at a time, so a specialization built for an early demand can be invalidated by a later one with more members under the same key. Eco stores the union of every demand filed under a key and re-translates a specialization, in rounds once the list is empty, when that union grows. Sets only grow and come from a finite universe, so the rounds end.

## Unknown is not empty

When a slot is read back at the end of a demand, it has one of four forms: a set of members; "any function", written ⊤; unknown, when nothing ever wrote to it; or a lower bound, "at least these members". An unwritten slot never reads back as empty. An empty set would claim the arrow is dead, and a set missing a member becomes a false singleton. ⊤ and unknown are treated alike by code generation but kept apart in the compiler, because they mean different things: ⊤ is deliberate widening, unknown is a flow that nothing recorded, and keeping them apart lets each be measured and fixed on its own.

## Kernels are opaque unless licensed

The analysis cannot see into the C++ [kernels](/docs/kernels), so every arrow that crosses a kernel boundary becomes ⊤ by default. That is always safe, and only costs precision. A kernel can instead carry a license in an audited table saying how function values pass through it; most licensed kernels pass functions only along the type variables their Elm type shares, so the set that comes out is the set that went in. About 250 kernels are licensed.

A wrong license is worse than none, because it produces a populated set that is missing members. Each row of the table therefore records its audit evidence, the audited C++ files are pinned by hash, and the default build fails when a pinned file changes without the table being reviewed.

> **Designs we didn't use.** Exporting unknowns as quantified set parameters is the paper's own answer, and we built a form of it: inclusion constraints instantiated per caller. It gave byte-identical output on every program we measured, so Eco does not carry them.

## Further reading

- [Monomorphization](/docs/monomorphization) — the demand list and store this analysis lives in.
- [Global optimization](/docs/global-optimization) — where single-member sets become direct and fast calls.
- [Closures and calls](/docs/closures-and-calls) — what the generic path costs at run time.
- The full design document: [Lambda-set specialization theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/lambda-set-specialization.md)
- Source: [`compiler/src/Compiler/MonoSolver`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Compiler/MonoSolver)
