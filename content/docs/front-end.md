---
title: "The front end"
description: "Eco's front end is Elm's own parser, name resolution, type checker and pattern checks, with one addition: it keeps the type of every expression for the native compiler."
section: "The compiler"
sectionOrder: 2
order: 2
---

Eco does not have a front end of its own. It uses Elm's: the parser, name resolution, type checker and pattern checks come from Guida, a port of the stock Elm compiler from Haskell to Elm, so Eco accepts the same programs and reports the same errors in the same words. The one thing Eco adds is that the type checker keeps its answers. Stock Elm asks only whether a program is well typed and then throws the working away; Eco records the type of every expression, because the native compiler needs it.

> **Background**
> - Canonical program: the program after name resolution, where every name points at the module that defines it.
> - Unification: how a type checker solves type equations, by merging placeholder variables until they agree.
> - [Monomorphization](/docs/glossary#monomorphization): the later phase that reads the recorded types to copy each polymorphic function per concrete type.

## Faithful to Elm

Starting from Guida gives Eco Elm's grammar, scoping rules, type system and error messages without writing them again, and those are what let Eco compile existing Elm packages unchanged. Here is a small mistake:

```elm
area : Float -> Float
area r =
    3.14 * r * r


main =
    text (String.fromInt (area 2))
```

Eco 0.2.0 reports it exactly as Elm 0.19.1 does:

```text
-- TYPE MISMATCH --------------------------------------------------- src/Err.elm

The 1st argument to `fromInt` is not what I expect:

12|     text (String.fromInt (area 2))
                              ^^^^^^
This `area` call produces:

    Float

But `fromInt` needs the 1st argument to be:

    Int
```

Guida accepts some syntax of its own, such as underscores in number literals and tuples of more than three elements. Eco does not. It keeps one grammar, the standard one, because the point is to compile the Elm that already exists. Projects may declare any Elm 0.19 release, since the language is the same across the 0.19 patch releases.

The errors follow Elm's model too. Each phase collects every problem it finds rather than stopping at the first, and each is rendered as a report that quotes the source. Anything Eco adds to the front end that can fail reports through the same channel, so a user cannot tell Eco's errors from Elm's.

## The five phases

A module passes through five phases:

1. The **parser** turns text into a syntax tree. It keeps Elm's design of small hand-written combinators, each of which records whether it consumed input; an alternative is tried only if the previous one failed without consuming anything.
2. **Name resolution** ties every name to its home module, reports duplicate definitions and sorts definitions into groups that refer to one another. In Eco it also gives every expression and pattern a number.
3. **Constraint generation** walks the module and emits the type equations the solver must satisfy. In Eco it also notes which solver variable stands for each numbered node.
4. The **solver** runs Hindley-Milner inference over a union-find store, in which variables proved equal are merged into one set with a single representative, its root.
5. A **repair step**, new in Eco, completes and normalizes the recorded types.

Elm's pattern checks run beside these, using Maranget's algorithm to reject `case` expressions that miss a possible value or have a branch that can never match. Later phases rely on this: every decision tree they build is complete.

## Keeping the type checker's answers

The solver knows only variables, placeholders that unification merges and fills in. The rest of the compiler wants types attached to expressions. The front end joins the two with numbers. Take a familiar polymorphic function:

```elm
twice : (a -> a) -> a -> a
twice f x =
    f (f x)
```

Name resolution numbers each node: the whole body, the outer call, the inner call `f x`, each use of `f` and `x`. Constraint generation records the solver variable for each number. After solving, each number's type is read back into a table, so the compiler can ask for the type of any numbered node and get an answer such as `a` for the inner call `f x`, or `a -> a` for the `f` being called. The table is an ordinary array indexed by node number. Joining types back onto the program is a lookup, and a number with no type is a compiler bug that stops the build, not an error shown to the user.

Expressions and patterns draw their numbers from one counter per module. With a separate counter each, an expression and a pattern would get the same number and the table would mix them up. The counter is per module because each module is compiled on its own.

This is the whole of what the typed path needs from type checking. [Monomorphization](/docs/monomorphization) later specializes `twice` at, say, `Int`, and the recorded types tell it that the inner call then produces an `Int`, which native code stores unboxed.

## Repair after solving

The solver leaves two kinds of gap, and the repair step fills them without changing any type the solver did work out.

Literal strings, characters, floats and the unit value get no useful constraint, because their type is fixed by their shape, so the repair step writes those types in directly. Number literals are the exception left open on purpose. A literal such as `1` keeps the type `number`, because until the whole program is specialized it is not known which uses of `number` become `Int` and which become `Float`. Monomorphization decides that at the end.

Kernel functions are the second gap. A kernel is a built-in implemented in the host language, JavaScript for stock Elm and C++ for Eco's native build ([Kernels](/docs/kernels)). It has no Elm declaration, so it produces no constraint of its own. The repair step gives each kernel reference the type implied by how the code uses it. Where that is not enough, a table of intrinsic annotations gives a kernel a declared type that the solver enforces. Each row states the contract of the C++ kernel, which can be narrower than the type the JavaScript package declares. Rows are added one at a time, because a wrong row turns correct package code into a type error.

## Identity comes from the solver

Monomorphization needs to know when two occurrences of a type variable are the same variable, and names cannot tell it. The solver may prove `a` in one place equal to `b` in another, and two modules may both use `a` for unrelated things. So the repair step replaces every solver variable by its union-find root, giving variables proved equal one identity, and stamps every function type with the root it came from. Membership of Elm's built-in classes such as `number` and `comparable` is likewise read from the solver's record, not from the variable's name, because names do not survive unification.

These identities are integers, each wrapped in its own Elm type so that one kind cannot be passed where another is expected. Lambda ids and arrow ids are what monomorphization and [lambda-set specialization](/docs/lambda-set-specialization) use to track which functions flow to which calls.

## Plain data in compact files

Later builds reload typed modules from the cache rather than checking them again, so everything the front end produces is plain data with an encoder and a decoder. Writing whole types and names out every time they appear makes those files enormous. Each file therefore stores every distinct string and every distinct type once, in tables, and refers to them by index. On the compiler's own source this made the cached typed files about fifty times smaller, and roughly halved the time spent parsing, checking and building. A format version at the start of each file makes a file from an older compiler fail to decode instead of being misread.

## Shaped by running as Elm

The compiler is Elm code. During [bootstrap](/docs/bootstrap) it runs under Node, and afterwards natively, and both have a bounded stack. Long chains of `let` bindings, operator applications or list patterns would overflow a traversal that recurses once per link. The constraint generator therefore walks each such chain in a self-tail-recursive loop, which Elm compiles to a plain loop that runs in constant stack, and recurses directly only where depth is bounded by what a person writes by hand, such as nested `case` expressions. The solver's main loop is written the same way.

The union-find store is an immutable array passed from step to step. A mutable store would be faster, but it depends on a usage contract the compiler cannot check, and Elm code must never observe mutation.

## Numbers shared with the runtime

A few numbers must agree with the C++ runtime: how many arguments a closure can take, how many fields a record or custom type can hold, and the tag that identifies each constructor in memory. Name resolution checks the limits and reports a breach as an ordinary error at the offending source location. A breach that got through would otherwise crash the backend, far from any position it could report.

## Further reading

- [Local optimization](/docs/local-optimization) — the first phase that uses the recorded types.
- [Monomorphization](/docs/monomorphization) — what the types are for.
- [The compiler](/docs/compiler) — how the typed and erased paths share this front end.
- The full design document: [The front end theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/front-end.md)
- Source: [`compiler/src/Compiler`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Compiler)
