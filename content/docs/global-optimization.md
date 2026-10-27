---
title: "Global optimization"
description: "How eco, once the whole program is specialized, decides how every call is made — a direct call, a fast closure call or the runtime's generic apply — and writes that decision onto the call for code generation to read."
section: "The compiler"
sectionOrder: 2
order: 6
---

After monomorphization every function has concrete types, but nothing yet says how each call should be made: as a direct jump to a known function, as a fast call into a known closure, or through the runtime's generic apply. Global optimization makes all of those decisions in one place and writes each one onto its call. Its rule is to prove or decline. A missed proof costs only speed, because the generic path is always correct. A wrong proof is a silent miscompile.

> **Background**
>
> - A [closure](/docs/glossary#closure) is a function value together with the values it captured. A [partial application](/docs/glossary#partial-application) is a closure that holds some of its arguments.
> - [Staging and arity](/docs/glossary#staging-and-arity): a stage is the group of parameters a closure takes in one application. `\x y -> x + y` has one stage of two; a function that returns a lambda has two stages.
> - A [lambda set](/docs/glossary#lambda-set) is the set of functions that can reach a given call site, as worked out by [lambda-set specialization](/docs/lambda-set-specialization).

## A small example

This program, from the examples we compile for these docs, has the shapes global optimisation exists for: a function that returns a lambda, a definition that is just another name, and a partial application used as a function.

```elm
adder a = \b -> a + b

scale k =
    let k2 = k * k in
    \x y -> k2 * x + y

twice f x = f (f x)

dup = twice

inc = adder 1

main =
    let
        s = scale 3
        r2 = s 4 5
        r3 = dup inc 10
        ...
```

Here is what reaches MLIR, compiled with the inliner turned down (`ECO_INLINE_THRESHOLD=0`) so that each function stays visible (trimmed: operand types and most function attributes removed):

```mlir
  "func.func"() ({
      ^bb0(%k: i64, %x: i64, %y: i64):
        %3 = "eco.int.mul"(%k, %k) : (i64, i64) -> i64
        %5 = "eco.int.mul"(%3, %x) : (i64, i64) -> i64
        %6 = "eco.int.add"(%5, %y) : (i64, i64) -> i64
        "eco.return"(%6) : (i64) -> ()
  }) {function_type = (i64, i64, i64) -> (i64), sym_name = "Stage_scale_$_1"}
  "func.func"() ({
      ^bb0(%_eta3: i64):
        %1 = "arith.constant"() {value = 1 : i64} : () -> i64
        %2 = "eco.call"(%1, %_eta3) <{callee = @Stage_adder_$_5}> : (i64, i64) -> i64
        "eco.return"(%2) : (i64) -> ()
  }) {function_type = (i64) -> (i64), sym_name = "Stage_inc_$_3"}
  "func.func"() ({
      ^bb0(%f: !eco.value, %x: i64):
        %2 = "eco.call"(%x) <{callee = @Stage_inc_$_3}> : (i64) -> i64
        %3 = "eco.call"(%2) <{callee = @Stage_inc_$_3}> : (i64) -> i64
        "eco.return"(%3) : (i64) -> ()
  }) {function_type = (!eco.value, i64) -> (i64), sym_name = "Stage_twice_$_4"}
```

Four things happened.

- `scale` is one function of three integers. [Local optimization](/docs/local-optimization) merged the two function boundaries, and global optimisation gave the closure the type of its real parameters. In `main`, `s 4 5` became a single direct call, `Stage_scale_$_1(3, 4, 5)`. The merge has a cost: `k * k` now runs on every call of `s` rather than once when `s` is built. Here that is one multiplication.
- `inc` was written with no parameters. Eta-expansion gave it the one its type declares (`%_eta3`), so it is an ordinary one-argument function that calls `adder` directly.
- `dup` has gone. It was only another name for `twice`, and alias forwarding pointed every use of it at `twice` itself. `main` calls `Stage_twice_$_4` directly.
- Inside `twice`, the two calls of `f` became direct calls of `Stage_inc_$_3`. The lambda set for `f` held only `inc`, so global optimisation devirtualised the calls. The parameter `%f` is still passed but is no longer read.

## Prove the call, or leave it generic

Elm functions are curried. A function of type `Int -> Int -> Int` can be applied to both arguments at once or to one at a time. Monomorphization writes every function type in curried form and says nothing about stages; global optimisation chooses them.

The fallback is always available. A closure's header says how many arguments it still needs and how to call it, so the runtime can apply any closure to any number of arguments ([Closures and calls](/docs/closures-and-calls) shows how). The fast paths are another matter. They load captured values from fixed positions and jump to fixed code with no check at run time. Every pass in this phase therefore declines by default and acts only on a narrow license it can check.

Staging is decided here and nowhere else, and in our view this is the only safe place to decide it. When the specializer and the code generator each work out call shapes for themselves, they can disagree, and the code generator ends up guessing arities from context. With one deciding phase, monomorphization can ignore staging altogether, and [MLIR generation](/docs/mlir-generation) only reads the record it is given.

## The steps, in order

![The steps around global optimisation, in order](/images/docs/global-optimization-steps.svg)

Two steps run *before* monomorphization, and their job is to put a visible callee at more call sites, because a lambda set can only shrink to one member where a call names a concrete lambda or a top-level function.

- **Alias forwarding** replaces a reference to a definition such as `dup = twice`, or `Basics.add`, which only names a C++ kernel, with a reference to its target. Nothing is copied, so the lambda-set analysis then tracks the target itself rather than a wrapper.
- **Eta-expansion** gives a definition the parameters its type declares but its code does not write, as with `inc`. It moves any work before the added parameters from once per partial application to once per call, so a cheapness test limits it to bodies whose early work is building a value, a small call, or a kernel that does not allocate.

The rest run on the specialized program.

- **Inline and simplify.** Small non-recursive specializations are inlined on their concrete types, repeatedly, until the bodies stop changing. Kernel calls are priced from a hand-audited table of what each kernel does. One rewrite copies a tail-recursive higher-order function, such as a fold, into a caller that passes it a lambda literal, so that the loop calls the lambda directly.
- **Prune** drops the specializations that inlining left unreachable. It is a separate step because whether a function is dead is a property of the whole program, and a callee's body must survive until the inliner has finished.
- **Wrap callables.** Every function-valued top-level definition that is not already a closure becomes one, so the next step has a parameter list to work from.
- **Regroup closure types.** Every closure gets the type `[its parameters] -> [the rest] -> result`. A closure's own parameter count is the one fact about staging that holds everywhere, so it is the only fact this step writes.
- **Stamp single-callee calls.** Where a call's lambda set has one member, this step marks the call for a fast closure call, or turns it into a direct call of the one matching specialization, as in `twice`.
- **Annotate every call** with a record of its call kind and the grouping of its arguments, which code generation reads.

Every lambda carries an identity number that the lambda-set analysis keys on. A pass that copies code, as the inliner does, must give the copy fresh numbers: two different bodies under one number would be a silent miscompile. All passes take their numbers from one minting module, and a check rejects numbers that are missing or duplicated.

## The four call kinds

Each call leaves global optimisation with one of four kinds. They appear in the MLIR as the `_call_kind` attribute on a closure application:

| Call kind | Meaning | Where it shows up |
|---|---|---|
| `direct_known_segmentation` | the callee's stages are known, so arguments are applied knowing how many each stage takes | `scale 2 1` above: two arguments given to a known three-argument function |
| `singleton_fast` | the call's lambda set has one member, so code generation calls that closure's code directly | the step function inside `List.map (scale 2 1)` in the same program |
| `segmentation_unknown` | the callee is known only from its type; the runtime splits the arguments by the closure header | `g acc` in `List.foldl (\g acc -> g acc) 1 [ \x -> x + 1, \x -> x * 2, negate ]`, where three different functions arrive |
| `generic_apply` | nothing is known; the runtime does all of it | `f acc` in a `repeatApply f n acc` loop, but only with lambda-set specialization turned off; with it on, the same call is `singleton_fast` |

Calls to kernels and to top-level functions with all their arguments are plain `eco.call`s and need no kind at all. Two lines from the example show the first two kinds (trimmed):

```mlir
%4 = "eco.papExtend"(%6, %7, %8) {_call_kind = "direct_known_segmentation", remaining_arity = 3, ...} : (!eco.value, i64, i64) -> !eco.value
%12 = "eco.papExtend"(%fn, %7, %acc) {_call_kind = "singleton_fast", _fast_evaluator = @Stage_lambda_12$cap, remaining_arity = 2, ...} : (!eco.value, i64, !eco.value) -> !eco.value
```

The order of the tests is the policy. A known segmentation needs every test to pass: the callee must come from something the phase can see (a top-level function, a closure bound by `let` or captured, or a tail-recursive definition); it must not be a function-typed parameter of an enclosing loop; and it must not trace back to a partial application whose return type was polymorphic. An arity read only from the type never claims a known segmentation. A `case` or `if` that produces closures yields known stages only when every branch agrees; eco does not re-stage branches to make them agree, and leaves such joins to the runtime.

## Two rules every pass shares

Every pass that needs to know what a C++ kernel does reads the same table: whether it allocates, whether it can fail, which arguments are functions, whether two calls can be merged. The table is a whitelist. A kernel with no row licenses nothing.

`Debug` output is observable on the native path, because optimised native builds keep `Debug` calls. Therefore no pass may delete, merge or reorder an expression that can reach a `Debug` kernel, directly or through the functions it calls. A whole-program analysis works out which specializations can.

> **Designs we didn't use.** A staging solver could group closures into classes, vote on one staging per class and wrap the closures that disagree. We built one, and on every program we measured it inserted no wrappers and the output without it was byte for byte the same, so eco does without it.

## Further reading

- [Lambda-set specialization](/docs/lambda-set-specialization) — how the sets that license direct and fast calls are computed.
- [Monomorphization](/docs/monomorphization) — the step that hands this phase a fully specialized program.
- [MLIR generation](/docs/mlir-generation) — the consumer of the call records written here.
- [Closures and calls](/docs/closures-and-calls) — the generic apply that every declined proof falls back on.
- [Optimisations](/docs/optimisations) — every optimisation in one place.
- The full design document: [Global optimization theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/global-optimization.md)
- Source: [`compiler/src/Compiler/GlobalOpt`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Compiler/GlobalOpt)
