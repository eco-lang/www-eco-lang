---
title: "Local optimization"
description: "Before types are concrete, eco rewrites each module on its own: pattern matches become decision trees, self-recursion becomes loops, operators become plain code, and some nested functions are merged, all while keeping every type."
section: "The compiler"
sectionOrder: 2
order: 3
---

Some optimisations need the whole program and concrete types. Others can be done on one module, with nothing known yet about whether `a` will turn out to be `Int` or `String`. Local optimization is the second kind. It turns pattern matches into decision trees, self-recursive functions into loops and a few operators into the code they stand for, and it does all of it without losing a single type, because the phases after it specialize the program from those types.

> **Background**
> - Decision tree: a compiled `case`, where each test looks at one part of the value and picks the next test.
> - Tail call: a call that is the last thing a function does, so its stack frame can be reused.
> - [Staging and arity](/docs/glossary#staging-and-arity): how a curried function's arguments are grouped into calls.

## Change the shape, keep the types

A rewrite belongs in this phase only if it passes three tests: it looks at one module, its result has the type of what it replaces, and it is correct for every type the code may later be specialized to. A rewrite that depends on whether a `comparable` is an `Int` or a `String` fails the third test and waits until after [monomorphization](/docs/monomorphization).

Every expression in the phase's output carries two pieces of type information: its type in the type checker's terms, which may still contain variables such as `a` or `number`, and the solver variable the [front end](/docs/front-end) recorded for it. Any rewrite that builds a node has to supply both. Each rewrite reuses the type and variable of the node it replaces for the nodes it builds, and that discipline is what keeps the types right.

The erased path, which produces JavaScript, runs Elm's own untyped copy of this phase instead, unchanged, so that eco's JavaScript stays identical to Elm's. The typed copy mirrors the same algorithms. We accept the cost of that, which is that a fix to one copy must be made by hand in the other, because JavaScript output identical to Elm's is worth more to us than one shared implementation.

## Pattern matches become decision trees

Here is a `case` with overlapping patterns over a list of `Maybe Int`:

```elm
describe : List (Maybe Int) -> String
describe xs =
    case xs of
        [] ->
            "empty"

        (Just 0) :: _ ->
            "starts with zero"

        (Just n) :: [] ->
            "one: " ++ String.fromInt n

        Nothing :: rest ->
            "skip " ++ describe rest

        _ ->
            "other"
```

Tried in order, the patterns would test the head of the list several times. The decision tree tests each part of the value at most once: is the list empty; if not, is the head `Just`; if so, is its content `0`; if not, is the tail empty. Each answer leads straight to a branch or to the next test. Informally, the tree has three kinds of node: a leaf that holds the branch to run, a chain of tests that all have to pass, and a fan-out that picks one of several subtrees by the value at one position. A branch reachable by several paths becomes a shared jump target instead of being copied.

This is the top of the code eco produces for `describe` (trimmed: attributes removed and the innermost tests elided):

```mlir
^bb0(%xs: !eco.value):
  %1 = "eco.get_tag"(%xs) : (!eco.value) -> i32
  %2 = "arith.constant"() {value = 65533 : i32} : () -> i32
  %3 = "arith.cmpi"(%1, %2) {predicate = 0 : i64} : (i32, i32) -> i1
  %34 = "eco.case"(%3) ({
        %4 = "eco.string_literal"() {value = "empty"} : () -> !eco.value
        "eco.yield"(%4) : (!eco.value) -> ()
  }, {
        %5 = "eco.project.list_head"(%xs) : (!eco.value) -> !eco.value
        %6 = "eco.get_tag"(%5) : (!eco.value) -> i32
        %7 = "arith.constant"() {value = 0 : i32} : () -> i32
        %8 = "arith.cmpi"(%6, %7) {predicate = 0 : i64} : (i32, i32) -> i1
        %33 = "eco.case"(%8) ({
              // head is Just: test its Int, then the tail ...
        }, {
              %29 = "eco.project.list_tail"(%xs) : (!eco.value) -> !eco.value
              %30 = "eco.string_literal"() {value = "skip "} : () -> !eco.value
              %31 = "eco.call"(%29) <{callee = @Case_describe_$_2}> : (!eco.value) -> !eco.value
              ...
        }) {case_kind = "bool"} : (i1) -> !eco.value
        "eco.yield"(%33) : (!eco.value) -> ()
  }) {case_kind = "bool"} : (i1) -> !eco.value
```

The first test compares the list's tag with the tag of the empty list. The second reads the head and compares its tag with `Just`'s. There is no test for `Nothing`: once the head is known not to be `Just`, it must be `Nothing`, so the `Nothing :: rest` branch is the other side. Inside the `Just` branch the content is read as an unboxed `i64` and compared with `0` directly.

Each step into a value also records what kind of container it is looking inside, a list, a pair, a triple or a custom type, so that code generation can use a typed projection such as `eco.project.list_head` rather than a generic one. The pattern checks have already run, so every tree is complete and needs no fallback branch.

## Self-recursion becomes a loop

A function that calls itself as its final action is marked as a tail-call definition, so later phases compile it as a loop instead of a chain of calls that grows the stack:

```elm
sumTo : Int -> Int -> Int
sumTo acc n =
    if n <= 0 then
        acc

    else
        sumTo (acc + n) (n - 1)
```

The output is an `scf.while` loop (trimmed: attributes and constant definitions removed). The loop carries `acc`, `n`, a "done" flag and the result, and the recursive call has become a `yield` of the new `acc + n` and `n - 1`:

```mlir
^bb0(%acc: i64, %n: i64):
  %4, %5, %6, %7 = "scf.while"(%acc, %n, %2, %3) ({
      ^bb0(%8: i64, %9: i64, %10: i1, %11: i64):
        %12 = "arith.xori"(%10, %13) : (i1, i1) -> i1
        "scf.condition"(%12, %8, %9, %10, %11) : (i1, i64, i64, i1, i64) -> ()
  }, {
      ^bb0(%14: i64, %15: i64, %16: i1, %17: i64):
        %19 = "eco.int.le"(%15, %18) : (i64, i64) -> i1
        %26, %27, %28, %29 = "eco.case"(%19) ({
              "eco.yield"(%14, %15, %20, %14) : (i64, i64, i1, i64) -> ()
        }, {
              %21 = "eco.int.add"(%14, %15) : (i64, i64) -> i64
              %23 = "eco.int.sub"(%15, %22) : (i64, i64) -> i64
              "eco.yield"(%21, %23, %24, %25) : (i64, i64, i1, i64) -> ()
        }) {case_kind = "bool"} : (i1) -> (i64, i64, i1, i64)
        "scf.yield"(%26, %27, %28, %29) : (i64, i64, i1, i64) -> ()
  }) : (i64, i64, i1, i64) -> (i64, i64, i1, i64)
  "eco.return"(%7) : (i64) -> ()
```

Every value in the loop is unboxed, 64-bit integers and a 1-bit flag. Monomorphization fixed those types later; the decision to make a loop was taken here, per module.

## Operators become what they mean

The short-circuit operators become conditionals: `a && b` becomes `if a then b else False`, and `a || b` becomes `if a then True else b`. Treated as an ordinary call, `&&` would reach the strict `Basics.and`, which evaluates both operands and would break programs that rely on the right-hand side not running. Passing `(&&)` as a function value stays strict, as it is in Elm.

The pipes `a |> f` and `f <| a` become the application they denote. They exist only to save brackets, and if they reached monomorphization each use would create another copy of the same tiny function. When `f` is already a partial application, the piped argument is added to that call, giving the same direct call the source would have produced without the pipe. Unary minus becomes a call of `Basics.negate`.

Only the infix forms are rewritten. These rewrites happen here rather than during name resolution because the canonical program keeps each operator as written for error messages and documentation.

Ports, the typed channels between an Elm program and its host, get their JSON encoders and decoders written here as ordinary typed code built from the port's declared type. The program's flags use the same decoder builder.

## Merging function boundaries

A function that takes one argument, binds some local values and then returns another function makes every full call build an intermediate closure and then call it:

```elm
scale : Int -> Int -> Int -> Int
scale k =
    let
        k2 =
            k * k
    in
    \x y -> k2 * x + y
```

Local optimization merges such a boundary. A function whose body, after its local bindings, is another function becomes a single function of both sets of parameters, with the bindings moved inside. A second rule does the same for a `case` whose branches are all functions of the same arity and parameter types: the parameters move outside the `case`, renamed to one fresh shared set. That rule is all or nothing, because merging only some branches would leave the others needing wrappers of their own. Both rules are applied until nothing changes. After the rest of the pipeline, `scale` is one three-argument function (trimmed):

```mlir
^bb0(%k: i64, %x: i64, %y: i64):
  %3 = "eco.int.mul"(%k, %k) : (i64, i64) -> i64
  %5 = "eco.int.mul"(%3, %x) : (i64, i64) -> i64
  %6 = "eco.int.add"(%5, %y) : (i64, i64) -> i64
  "eco.return"(%6) : (i64) -> ()
```

Merging is not free. The `let` now runs on every call, so `k * k` is computed each time `scale` is applied to all three arguments, even when the program applies it to `k` once and reuses the result. For a multiplication that does not matter. For expensive work it does. In this program

```elm
makeLookup : List Int -> Int -> Bool
makeLookup xs =
    let
        s =
            Set.fromList xs
    in
    \x -> Set.member x s

isIn = makeLookup [ 1, 5, 9 ]
```

`makeLookup` becomes one two-argument function whose body calls `Set.fromList` and then `Set.member`, so `List.filter isIn` rebuilds the set for every element it tests. The source suggests the set is built once; the compiled code builds it each time. This is a known issue at default settings in 0.2.0. We treat it as a compiler bug to fix, not a trade-off to keep, because a rewrite should never make a program do more work than its source describes.

Merging and eta-expansion are easy to confuse. *Merging*, done here, joins a function to the function its body returns, moving any local bindings inside. *Eta-expansion*, done later, adds parameters to a function whose body is a bare lambda. Merging runs before monomorphization because monomorphization keeps whatever function structure it is given. The final grouping of each function's parameters is decided later, by [global optimisation](/docs/global-optimization), once the whole program is known; its eta-expansion step is what turns a simple nested lambda with no `let` in between, such as `adder a = \b -> a + b`, into a two-argument function.

## Further reading

- [Monomorphization](/docs/monomorphization) — the next phase, which specializes the rewritten graph.
- [Global optimization](/docs/global-optimization) — where staging and call kinds are finally decided.
- [MLIR generation](/docs/mlir-generation) — how decision trees and loops become eco-dialect operations.
- The full design document: [Local optimization theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/local-optimization.md)
- Source: [`compiler/src/Compiler/LocalOpt`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Compiler/LocalOpt)
