---
title: "MLIR generation"
description: "How Eco writes the fully specialized program out as eco-dialect MLIR, one function per specialization, reading every decision from the program graph and converting values between their boxed and unboxed forms only where two forms meet."
section: "The compiler"
sectionOrder: 2
order: 7
---

By the time MLIR generation runs, every decision that changes what the program means has been made: which function each call reaches, how its arguments are grouped, what each closure captures. Generation reads those decisions and spells them out, one MLIR function per specialization. Its own job is representation: where a value lives as a raw machine number, where it is a pointer to a heap object, and where two such forms meet and one must be converted to the other.

> **Background**
>
> - [MLIR](/docs/glossary#mlir) is a compiler framework built from [dialects](/docs/glossary#dialect), families of operations. Eco's own dialect is described in [The eco dialect](/docs/eco-dialect).
> - [SSA](/docs/glossary#ssa) (static single assignment) is the style of MLIR code: each value is defined exactly once.
> - [Boxed and unboxed](/docs/glossary#boxed-and-unboxed): an unboxed value is a raw number in a register; a boxed value is a pointer to a heap object.

[A tour through the compiler](/docs/tour) shows the output for a small `case` over shapes. This article starts from something the tour does not cover: a tuple that never touches the heap.

## A tuple that stays in registers

```elm
divMod : Int -> Int -> ( Int, Int )
divMod a b =
    ( a // b, modBy b a )

magnitude : ( Int, Int ) -> Int
magnitude ( x, y ) =
    x * x + y * y

main =
    let
        ( q, r ) = divMod 17 5
        point = ( q, r )
    in
    text (String.fromInt (magnitude point))
```

Read naively, this program allocates two tuples: the one returned by `divMod`, and `point`. At default settings Eco allocates neither. This is the output (trimmed: operand types and most function attributes removed):

```mlir
  "func.func"() ({
        %1 = "arith.constant"() {value = 17 : i64} : () -> i64
        %2 = "arith.constant"() {value = 5 : i64} : () -> i64
        %3, %4 = "eco.call"(%1, %2) <{callee = @Agg2_divMod_$_1$sret}> : (i64, i64) -> (i64, i64)
        %5 = "eco.make.tuple2"(%3, %4) : (i64, i64) -> !eco.tuple2<i64, i64>
        %7 = "eco.project.tuple2"(%5) {field = 0} : (!eco.tuple2<i64, i64>) -> i64
        %8 = "eco.project.tuple2"(%5) {field = 1} : (!eco.tuple2<i64, i64>) -> i64
        %9 = "eco.call"(%7, %8) <{callee = @Agg2_magnitude_$_2$psplit}> : (i64, i64) -> i64
        ...
  }) {sym_name = "Agg2_main_$_0"}
  "func.func"() ({
      ^bb0(%a: i64, %b: i64):
        %2 = "eco.int.div"(%a, %b) : (i64, i64) -> i64
        %3 = "eco.int.modby"(%b, %a) : (i64, i64) -> i64
        ...
        "eco.return"(%5, %6) : (i64, i64) -> ()
  }) {function_type = (i64, i64) -> (i64, i64), sym_name = "Agg2_divMod_$_1$sret"}
  "func.func"() ({
      ^bb0(%_v0_s0: i64, %_v0_s1: i64):
        %2 = "eco.int.mul"(%_v0_s0, %_v0_s0) : (i64, i64) -> i64
        %3 = "eco.int.mul"(%_v0_s1, %_v0_s1) : (i64, i64) -> i64
        %4 = "eco.int.add"(%2, %3) : (i64, i64) -> i64
        "eco.return"(%4) : (i64) -> ()
  }) {function_type = (i64, i64) -> (i64), sym_name = "Agg2_magnitude_$_2$psplit"}
```

Three things carry the idea.

- `divMod` has a worker, `$sret`, that returns the tuple's two fields as two results rather than as a pointer to a heap tuple. The lowering passes the worker a pointer to a slot in the caller's stack frame, the worker stores the fields there, and the caller reads them back. No aggregate crosses the call, and nothing reaches the heap.
- `magnitude` has a worker, `$psplit`, that takes the tuple's fields as separate parameters. It qualifies because its body only ever takes the tuple apart.
- `point` is an `eco.make.tuple2`, whose result type `!eco.tuple2<i64, i64>` is an SSA value, not a heap pointer. Its two projections read the fields straight back.

The original `divMod` and `magnitude` are still emitted as small shims that build or unpack a real heap tuple and call the worker, for any route that needs the boxed form, such as passing `divMod` as a function value. A worker is created only where at least one direct call site gains from it, because without one the worker and its shim are pure overhead. Results are promoted for 2- and 3-tuples; parameters for 2- and 3-tuples and for single-constructor custom types of 2 to 6 fields.

A tuple carried round a loop is different. In

```elm
minMax xs =
    List.foldl (\x ( lo, hi ) -> ( min lo x, max hi x )) ( 999, -999 ) xs
```

the accumulator crosses the loop as a boxed value, so every step builds a new heap tuple (trimmed):

```mlir
%39 = "eco.construct.tuple2"(%34, %38) {unboxed_bitmap = 5} : (i64, i64) -> !eco.value
```

`eco.construct.tuple2` allocates; `unboxed_bitmap = 5` records that both fields are stored as raw integers inside it. In the same program, `pair = ( 3, 4 )`, which is only taken apart, stays an `eco.make.tuple2`.

## Reading decisions, not making them

Every fact that could change behaviour arrives on the program graph. A call carries its call kind and the grouping of its callee's parameters, decided by [global optimisation](/docs/global-optimization). A closure carries its captures. A constructor carries its shape. Generation never works these out again. We hold to this because two places deriving the same fact will sooner or later disagree, and the symptom then surfaces in the verifier or in LLVM, far from the cause.

That split makes a wrong output easy to place: it is either an upstream decision or a conversion at a boundary. Generation crashes on a mismatch it cannot convert rather than patching it. Its conversion function knows exactly two kinds of conversion: between a primitive and a boxed value, and between a boxed tuple and its SSA form. A 64-bit integer meeting a 64-bit float is not converted, because two primitive types that disagree mean an earlier phase produced a wrong type, and converting here would hide it.

![How MLIR generation walks the specialized graph](/images/docs/mlir-generation-flow.svg)

Generation builds one context holding every whole-program table the functions need, such as the signature of every specialization. Then each specialization becomes one self-contained function, and all per-function state is cleared before the next. Closure bodies, the entry function `main`, one declaration per kernel the program calls, and a type table for debugging are written after the loop, because they depend on everything seen.

## Three forms of a value

A value has three forms, and they differ on purpose.

- The **ABI form** is how a value crosses a function boundary or sits in a closure. Int is a 64-bit integer, Float a 64-bit float and Char a 16-bit integer (one UTF-16 code unit, the unit the runtime stores strings in). Everything else, Bool included, is a pointer-sized boxed value.
- The **SSA form** is whatever an operation actually produced. Generation carries that type with every value.
- The **heap form** is how a value is stored in an object's field. Int, Float and Char may sit unboxed there, and each field has a two-bit kind saying which.

Conversions happen only where two forms meet: at a call, a capture, a field store or read, and a return. Tracking the real SSA type, rather than recomputing one from the Elm type at each use, is what keeps those conversions right.

Bool shows the policy most clearly. Inside a function a Bool is a single bit, because a bit can drive a branch directly. Heap fields can only tell a pointer from an Int, a Float or a Char, and True and False exist in the runtime as constants embedded in the pointer word. As a result, a Bool is boxed to one of those constants when it is passed, captured or stored, and unboxed back to a bit when it is read. [Value representation](/docs/value-representation) has the full rules.

## What each kind of Elm code becomes

- **Constructors** become small functions that build a heap object with its tag, size and field kinds. A constructor with no fields becomes a shared constant, and a reference to it emits the constant in place of a call.
- **Closures** that capture variables get a function, named with a `$cap` suffix, that takes the captures and then the parameters with their real types. The 0.2.0 release also emits a second `$clo` wrapper that takes the closure pointer; later versions do not. Closures in one `let` block that refer to each other are allocated together by one operation, so every sibling's pointer exists before any capture is written.
- **Calls** take the form their call kind dictates: a direct `eco.call`, or an `eco.papExtend` that applies a closure, carrying the kind so that the lowering can pick the fast path or the generic one.
- **Pattern matches** become nested `eco.case` operations that yield values, each branch a single block, so that a later pass can turn each into structured control flow.
- **Tail-recursive functions** become an `scf.while` loop whose body is a case. A branch that makes a tail call yields the next arguments; a branch that returns yields its result and a flag that ends the loop.
- **Kernel calls** register the kernel's types from the specialized Elm types at that call. The first registration fixes them, and a later call that disagrees crashes the compiler, because the lowering must never guess a kernel's types from how it is used.

## Top-level constants: folded or remembered

A top-level value with no arguments compiles to a function of no arguments. Generation shortens the route to some of them in one of two ways.

A small closed body, such as a numeric literal, `pi`, or a little arithmetic on literals, is folded: each reference emits the body itself in place of the call, and LLVM does the arithmetic. The compiler does not evaluate the body itself, because it may be running as JavaScript, whose bitwise operations, maths library and float printing differ from native code, so a value it computed could differ from the one the program computes.

A value computed at run time whose ABI form is boxed gets a memo slot: a global that holds the value once the first use has computed it. Elm's `Bytes.Decode.unsignedInt8` is one: a program that uses it gets a slot declared as `"eco.global"() {sym_name = "__eco_caf$Bytes_Decode_unsignedInt8_$_5"}`. Only boxed values qualify, because once filled the collector reads the slot as a heap pointer, and an empty slot is zero, which no boxed value is.

## The debug type table

A heap object records its tag, its size and its field kinds, but no names. On the native path `Debug.log` and `Debug.toString` must still print constructor and field names, so the compiler describes each printable type once, in a table emitted with the program, instead of storing type information in every object. The table also tells apart values the heap cannot: unit, `[]`, `Nothing`, `""` and `{}` are all the same embedded word, so the printer names them from the type. A program pays only for the types its debugging and construction sites reach.

## Writing the bytecode

The compiler is a garbage-collected Elm program, and holding the whole module in memory, and then its text, would make memory peak at code generation. It writes MLIR bytecode incrementally instead. Bytecode refers to its shared tables of strings, types and operation names only by index, and when those tables only grow, an index written early stays valid, so each function can be encoded and dropped. The bytecode reaches the C++ back end through a temporary file inside the one `eco` process.

A text form exists for reading, and it is what every listing in these docs is. You can get it for your own program with `eco make src/Main.elm --text-mlir --output=main.mlir`. It is a view, not an equal of the bytecode: it drops source locations and prints some floats inexactly, so numeric problems are investigated on the bytecode.

Neither writer checks anything. Correctness rests on the dialect's verifiers in the C++ back end, which check each operation's local facts when the module is loaded, and on the numbered rules that tie the two halves together ([The numbered invariants](/docs/invariants)).

> **Designs we didn't use.** An escape analysis, to find constructed values that never leave their function and keep them in registers, found almost nothing to keep on the compiler's own source. The `$sret` and `$psplit` workers aim instead at the case that matters, tuples, about a third of whose construction sites do not escape.

## Further reading

- [A tour through the compiler](/docs/tour) — the shapes program, including `Main_area_$_5`, followed through every stage.
- [Global optimization](/docs/global-optimization) — where the call kinds and closure types read here are decided.
- [The eco dialect](/docs/eco-dialect) — the operations this phase emits and what their verifiers check.
- [Value representation](/docs/value-representation) — the ABI, SSA and heap forms in full.
- [Lowering passes](/docs/lowering-passes) — what happens to this output next.
- The full design document: [MLIR generation theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/mlir-generation.md)
- Source: [`compiler/src/Compiler/Generate/MLIR`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Compiler/Generate/MLIR)
