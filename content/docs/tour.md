---
title: "A tour through the compiler"
description: "One small Elm program followed through every stage of Eco, from source and type checking through monomorphization, MLIR and lowering to a running native executable, with the real compiler output at each step."
section: "Introduction"
sectionOrder: 1
order: 4
---

The fastest way to understand a compiler is to watch one program go through it. This page takes a 49-line Elm program and follows it stage by stage, from source text to a native executable, showing what the compiler actually produces at each step. By the end, a `case` over three shapes has become a three-way branch on a tag, an `Int` list has its numbers stored directly in the list cells, and a function passed as an argument is called directly.

> **Background**
> - [MLIR](/docs/glossary#mlir): a framework for writing compiler intermediate languages, each called a [dialect](/docs/glossary#dialect).
> - [Monomorphization](/docs/glossary#monomorphization): making one copy of a generic function for each type it is used at.
> - [Lambda set](/docs/glossary#lambda-set): the set of functions that can reach a particular call through a function value.
> - [Lowering](/docs/glossary#lowering): rewriting operations of a high-level dialect into simpler ones, ending in LLVM's.

![The stages of Eco, from Elm source to native code](/images/docs/overview-pipeline.svg)

## Following along

Every listing of compiler output below comes from Eco 0.2.0. To reproduce it, put the program in `src/Main.elm` of an Elm project and run:

```text
eco make src/Main.elm --text-mlir --output=main.mlir
```

The `.mlir` ending asks for the compiler's output just before the backend, and `--text-mlir` makes it readable text instead of bytecode. Setting `ECO_INLINE_THRESHOLD=0` in the environment stops the inliner absorbing small functions, which helps when you want to see every function survive. The listings drop the `_operand_types` attribute that Eco puts on every operation, and are marked "trimmed" where they do.

## 1. The program

The program has a custom type and a function that matches on it:

```elm
type Shape
    = Circle Float
    | Rect Float Float
    | Square Float


area : Shape -> Float
area shape =
    case shape of
        Circle r ->
            3.14 * r * r

        Rect w h ->
            w * h

        Square s ->
            s * s
```

It also has a tail-recursive loop, a higher-order function, a function over `number`, and a `main` that uses all of them:

```elm
sumTo : Int -> Int -> Int
sumTo acc n =
    if n <= 0 then
        acc

    else
        sumTo (acc + n) (n - 1)


twice : (a -> a) -> a -> a
twice f x =
    f (f x)


add : number -> number -> number
add a b =
    a + b


main =
    text
        (String.fromInt (sumTo 0 (twice (add 1) 10))
            ++ String.fromFloat (area (Rect 2 3))
            ++ String.join "," (List.map String.fromInt (List.map (\x -> x * 2) [ 1, 2, 3 ]))
        )
```

Three things in it are hard for a native compiler. `twice` and `add` do not say what types they work on. `area` receives a value whose shape is only known at run time. And `twice` calls a function it was handed, which in general could be any function at all.

## 2. The front end: keeping the types

Eco's front end is Elm's own, by way of Guida, a port of the Elm compiler to Elm. It parses the module, resolves every name to the module that defines it, and runs Elm's type checker, so a type error in this program would read exactly as it does under `elm make`.

Stock Elm's type checker answers one question, whether the program is well typed, and throws away its working. Eco keeps the answers, because the stages that follow need the type of every expression. It does this with numbers. While resolving names, the front end gives every expression and pattern a number, and after solving it fills a table indexed by that number:

```elm
type alias ExprInfo =
    { id : Int
    , node : Expr_
    }

type alias ExprTypes =
    Array (Maybe (Can.Type Name))
```

So the expression `w * h` inside `area` has a number, and its entry in the table says `Float`. The expression `a + b` inside `add` has the type `number`. That is as far as the front end can go, because `add` is generic, and nothing can be decided about `number` until the whole program has been seen. Literals such as `1` keep the type `number` for the same reason.

More in [The front end](/docs/front-end).

## 3. Local optimization: the case becomes a decision tree

Next, each module is optimized on its own, with rewrites that need neither the rest of the program nor concrete types. The most visible is pattern matching. A `case` becomes a decision tree in which each part of the value is tested at most once. The shape of that tree, from the compiler's typed optimized form, is:

```elm
type Decider a
    = Leaf a
    | Chain (List ( DT.Path, DT.Test )) (Decider a) (Decider a)
    | FanOut DT.Path (List ( DT.Test, Decider a )) (Decider a)
```

A `Leaf` is a branch body. A `Chain` runs a list of tests and goes one way or the other. A `FanOut` looks at one place in the value (the path) and picks among several tests. For `area`, the tree is a single `FanOut` at the root, `shape`, with the tests "is it a `Circle`?" and "is it a `Rect`?", each leading to a `Leaf`. `Square` becomes the fallback rather than a third test: the match is known to be complete, so if the value is neither of the others it must be a `Square`, and nothing needs to check.

The same stage turns `sumTo`, which calls itself in tail position, into a tail-call definition that will become a loop. It also rewrites `&&`, `||` and the pipe operators into conditionals and plain calls. Every rewritten node keeps the type the front end recorded, because the next stage needs it.

More in [Local optimization](/docs/local-optimization).

## 4. Monomorphization: one copy per type

Native code has to know how big a value is and which machine instructions operate on it. An `Int` is 64 bits in a register, a `Float` is a 64-bit floating-point register, and a `String` is a pointer to the heap. A generic function such as `add` cannot be compiled once for all of them, so the compiler links all the modules, starts from `main`, and makes one copy of each function for each combination of types it is actually used at. Each copy is called a specialization.

In this program `add` is only ever used on `Int`, so there is one copy, and its `number` has become `Int`. Each specialization's name is its module, its name, and a number that keeps names unique. These are the program's own specializations, with their machine-level signatures:

```text
Main_main_$_0    () -> !eco.value
Main_add_$_1     (i64, i64) -> i64
Main_sumTo_$_3   (i64, i64) -> i64
Main_Rect_$_4    (f64, f64) -> !eco.value
Main_area_$_5    (!eco.value) -> f64
Main_lambda_0    (i64) -> i64
```

`i64` and `f64` are unboxed machine integers and floats, and `!eco.value` is a pointer to a heap object. `Main_Rect_$_4` is the `Rect` constructor used as a function. `Main_lambda_0` is `\x -> x * 2`, known to take and return `Int`. From elm/core come `String_fromInt_$_6`, `String_join_$_9`, and two copies of the helper behind `List.map`, `List_foldrHelper_$_14` and `List_foldrHelper_$_20`. One builds a list of strings and the other a list of integers. They are the same Elm code compiled twice, because the element types differ and so do the callbacks.

`twice` is missing from the list. The inliner gives functions that call one of their own parameters a larger budget, because inlining them lets the function argument be called directly, so `twice` was copied into `main` and its specialization removed. That happens even with `ECO_INLINE_THRESHOLD=0`. The gaps in the numbering are specializations like this one, created and later inlined away.

More in [Monomorphization](/docs/monomorphization).

## 5. Global optimization: deciding how every call is made

With the whole program specialized, Eco decides, once for each call, how it will be made. Calling a known function with all its arguments is an ordinary call. A call through a function value is harder: the callee might need more arguments than it is given, or fewer, and in general the runtime has to look at the closure to find out. Global optimization records the answer on each call as a call kind, so code generation never has to work it out again.

After inlining, `twice (add 1) 10` has become `f (f 10)` with `f = add 1`. Here is what the compiler made of it (trimmed):

```mlir
%4 = "eco.papCreate"() {arity = 2, function = @Main_add_$_1, num_captured = 0} : () -> !eco.value
%5 = "arith.constant"() {value = 1 : i64} : () -> i64
%2 = "eco.papExtend"(%4, %5) {_call_kind = "direct_known_segmentation", remaining_arity = 2} : (!eco.value, i64) -> !eco.value
%3 = "arith.constant"() {value = 10 : i64} : () -> i64
%8 = "eco.papExtend"(%2, %3) {_call_kind = "singleton_fast", _fast_evaluator = @Main_add_$_1, remaining_arity = 1} : (!eco.value, i64) -> i64
%9 = "eco.papExtend"(%2, %8) {_call_kind = "singleton_fast", _fast_evaluator = @Main_add_$_1, remaining_arity = 1} : (!eco.value, i64) -> i64
%10 = "eco.call"(%1, %9) <{callee = @Main_sumTo_$_3}> : (i64, i64) -> i64
```

`papCreate` and `papExtend` build and apply partial applications. The first `papExtend` gives `add` one of its two arguments, and because the compiler knows `add`'s arity, the result is recorded as a partial application still waiting for one argument. The next two are the calls `f 10` and `f (f 10)`. Lambda-set analysis has proved that the only function that can arrive at them is `add 1`, so they are marked `singleton_fast`, with `Main_add_$_1` as the function to call. They pass `i64` in and get `i64` back, without going through the runtime's generic apply routine, which would have to inspect the closure. The call to `sumTo` is a plain `eco.call`.

More in [Global optimization](/docs/global-optimization) and [Lambda-set specialization](/docs/lambda-set-specialization).

## 6. MLIR generation: writing down the decisions

By now everything is decided, and code generation only writes the decisions down in Eco's own MLIR dialect, the contract between the Elm half of the compiler and the C++ half. The smallest function shows the format (trimmed):

```mlir
^bb0(%a: i64, %b: i64):
  %2 = "eco.int.add"(%a, %b) : (i64, i64) -> i64
  "eco.return"(%2) : (i64) -> ()
}) {function_type = (i64, i64) -> (i64), sym_name = "Main_add_$_1"}
```

Every value is in SSA form: assigned once, with its type written out. `add` is two 64-bit integers in, one out, with no heap anywhere. Here is `area` (trimmed):

```mlir
^bb0(%shape: !eco.value):
  %14 = "eco.case"(%shape) ({
        %2 = "eco.project.custom"(%shape) {field_index = 0} : (!eco.value) -> f64
        %3 = "arith.constant"() {value = 3.14 : f64} : () -> f64
        %4 = "eco.float.mul"(%3, %2) : (f64, f64) -> f64
        %5 = "eco.float.mul"(%4, %2) : (f64, f64) -> f64
        "eco.yield"(%5) : (f64) -> ()
  }, {
        %7 = "eco.project.custom"(%shape) {field_index = 0} : (!eco.value) -> f64
        %9 = "eco.project.custom"(%shape) {field_index = 1} : (!eco.value) -> f64
        %10 = "eco.float.mul"(%7, %9) : (f64, f64) -> f64
        "eco.yield"(%10) : (f64) -> ()
  }, {
        %12 = "eco.project.custom"(%shape) {field_index = 0} : (!eco.value) -> f64
        %13 = "eco.float.mul"(%12, %12) : (f64, f64) -> f64
        "eco.yield"(%13) : (f64) -> ()
  }) {case_kind = "ctor", tags = array<i64: 0, 1, 2>} : (!eco.value) -> f64
  "eco.return"(%14) : (f64) -> ()
```

The decision tree has become one `eco.case` with a region per constructor, chosen by the tag stored in the object's header. The fallback `Square` is simply the region for tag 2. Each region reads the fields it needs with `eco.project.custom`, and the fields come out as `f64`: a `Rect`'s two Floats are stored unboxed inside the object, not as pointers to separate boxes.

`main` builds the list `[ 1, 2, 3 ]` from the tail up, starting from the empty list, `eco.constant` kind 2, which is a constant word rather than a heap object:

```mlir
%30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value
%31 = "arith.constant"() {value = 3 : i64} : () -> i64
%32 = "eco.construct.list"(%31, %30) {head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value
```

`head_unboxed = true` means the 3 is stored directly in the list cell. Under stock Elm's JavaScript, and under any compiler that does not know the element type, it would be a reference to a separately boxed number. `sumTo`, meanwhile, has become an `scf.while` loop that carries `acc` and `n` from one iteration to the next as `i64` values and never calls itself.

More in [MLIR generation](/docs/mlir-generation) and [The eco dialect](/docs/eco-dialect).

## 7. Lowering: from eco operations to memory

The backend, in C++, checks the module against the dialect's rules and then runs about twenty lowering passes, each rewriting eco operations into simpler ones until only LLVM's dialect is left. Take the list cell above. This is a test fixture from the compiler's suite, which builds a cell with an `i64` head and checks that it lowers to the inline allocator:

```mlir
func.func @value_to_heap_cons(%head: i64, %tail: !eco.value) -> !eco.value {
  %c = eco.make.cons %head, %tail : (i64, !eco.value) -> !eco.cons<i64, !eco.value>
  %h = eco.to_heap %c : (!eco.cons<i64, !eco.value>) -> !eco.value
  return %h : !eco.value
}

// CHECK: llvm.func @value_to_heap_cons
// CHECK: llvm.call @__eco_alloc_inline
```

The rewrite that `main`'s `eco.construct.list` goes through does the same thing. From the lowering of `eco.construct.list` (trimmed):

```cpp
uint64_t header = value_enc::composeHeader(
    value_enc::TagCons, headKind, layout::ConsSize);
Value consHPtr = emitInlineAllocWithHeader(
    rewriter, loc, runtime, layout::ConsSize, header);
emitFreshFieldStore(rewriter, loc, consHPtr,
    layout::ConsHeadOffset, headLLVM, op.getHead().getType());
emitFreshFieldStore(rewriter, loc, consHPtr,
    layout::ConsTailOffset, tailVal, op.getTail().getType());
rewriter.replaceOp(op, consHPtr);
```

A cell is 24 bytes: a header word that says "Cons, with an Int head", the head, and a pointer to the tail. The header is a constant worked out at compile time, the head is the raw 64-bit integer, and nothing calls the runtime.

![A Cons cell for 5 :: rest: header word, unboxed head, tail pointer](/images/docs/cons-cell-layout.svg)

More in [Lowering passes](/docs/lowering-passes).

## 8. LLVM, linking and running

`__eco_alloc_inline` is not a real function. It is a marker that stays opaque through the MLIR passes and the translation to LLVM, and is expanded only once the code is in LLVM's form, before statepoint rewriting. From the comment that documents the expansion (trimmed):

```text
%state = call ptr @eco_bump_state()
%top   = load ptr addrspace(1), ptr %state   ; bump.ptr at +0
%end   = load ptr addrspace(1), ptr %state+8 ; bump.end at +8 (clamped)
%new   = gep i8, %top, SIZE
%miss  = icmp ugt %new, %end
br %miss, slow, fast
slow:  %r = call ptr addrspace(1) @eco_alloc_inline_slow(SIZE)
fast:  store %new, %state
cont:  %obj = phi [ %top, fast ], [ %r, slow ]
```

Allocating is a pointer bump and one compare. The end of the allocation area is set in advance to the point where the next minor collection should start, so the same compare means both "the nursery is full" and "time to collect". Only the slow branch can run the garbage collector, and that branch is where LLVM's statepoint machinery records which values on the stack are heap pointers, so the collector can find and move them.

For an optimized build the module is split into partitions, LLVM optimizes and compiles each one on its own thread, and the objects are linked with the prebuilt runtime and kernel libraries:

```text
eco make src/Main.elm --output=main
```

This produces a statically linked x86-64 executable of about 9 MB that needs nothing installed to run. Running it prints nothing, because `main` here is an `Html` value and there is no browser to show it in. Wrapping the string in `Debug.log "main"` before it reaches `text` shows that the native program computed what the JavaScript one would:

```text
main: "7862,4,6"
```

That is 78 from `sumTo 0 12`, 6 from `area (Rect 2 3)`, and the doubled list joined with commas. A program meant for the terminal would use `eco/system`, which gives Elm files, processes, sockets and standard output.

More in [The backend](/docs/backend), [The runtime](/docs/runtime) and [System libraries](/docs/system-libraries).

## Further reading

- [Eco at a glance](/docs/theory) — the ideas behind the stages on this page.
- [Optimisations](/docs/optimisations) — every optimisation at every stage.
- [Value representation](/docs/value-representation) — how values like the list cell above are laid out.
- [Closures and calls](/docs/closures-and-calls) — what happens to the calls that cannot be made direct.
- The full design document: [The compiler theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/compiler.md)
- Source: [`compiler`](https://github.com/eco-lang/eco-compiler/tree/master/compiler)
