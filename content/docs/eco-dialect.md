---
title: "The eco dialect"
description: "The eco dialect is the set of typed MLIR operations in which eco's Elm-written compiler hands a program to its C++ backend, and its verifier is the check made on that hand-over."
section: "The backend"
sectionOrder: 3
order: 2
---

eco is written in two languages: the compiler in Elm, the backend and runtime in C++. No type system spans the gap between them. The eco dialect is the contract that does: a set of typed operations in which the compiler describes the program, and a verifier the backend runs every time it reads one. The compiler describes values; only the backend decides how they sit in memory.

> **Background**
>
> - [MLIR](/docs/glossary#mlir) — a compiler framework in which a program is a list of typed operations, grouped into [dialects](/docs/glossary#dialect).
> - [SSA](/docs/glossary#ssa) — each value is defined once and named, like `%k` or `%shape` below.
> - [Boxed and unboxed](/docs/glossary#boxed-and-unboxed) — a boxed value is one word that points at the heap or holds a small constant; an unboxed value is a plain machine number.
> - [Lowering](/docs/glossary#lowering) — rewriting operations into simpler ones closer to the machine.

## A small function

This Elm function scales a shape:

```elm
type Shape
    = Circle Float
    | Rect Float Float

scale : Float -> Shape -> Shape
scale k shape =
    case shape of
        Circle r ->
            Circle (k * r)

        Rect w h ->
            Rect (k * w) (k * h)
```

Compiled with `eco make --text-mlir`, its body comes out as follows (trimmed: the `_operand_types` attributes and the function wrapper are removed):

```mlir
^bb0(%k: f64, %shape: !eco.value):
  %2 = "eco.get_tag"(%shape) : (!eco.value) -> i32
  %3 = "arith.constant"() {value = 0 : i32} : () -> i32
  %4 = "arith.cmpi"(%2, %3) {predicate = 0 : i64} : (i32, i32) -> i1
  %16 = "eco.case"(%4) ({
        %6 = "eco.project.custom"(%shape) {field_index = 0} : (!eco.value) -> f64
        %7 = "eco.float.mul"(%k, %6) : (f64, f64) -> f64
        %8 = "eco.construct.custom"(%7) {constructor = "Circle", size = 1,
               slot_kinds = array<i8: 2>, tag = 0} : (f64) -> !eco.value
        "eco.yield"(%8) : (!eco.value) -> ()
  }, {
        %10 = "eco.project.custom"(%shape) {field_index = 0} : (!eco.value) -> f64
        %12 = "eco.project.custom"(%shape) {field_index = 1} : (!eco.value) -> f64
        %13 = "eco.float.mul"(%k, %10) : (f64, f64) -> f64
        %14 = "eco.float.mul"(%k, %12) : (f64, f64) -> f64
        %15 = "eco.construct.custom"(%13, %14) {constructor = "Rect", size = 2,
               slot_kinds = array<i8: 2, 2>, tag = 1} : (f64, f64) -> !eco.value
        "eco.yield"(%15) : (!eco.value) -> ()
  }) {case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value
  "eco.return"(%16) : (!eco.value) -> ()
```

Most of the dialect is visible here. The scale factor `k` is a plain `f64`, because monomorphization has fixed it as a Float. The shape is `!eco.value`, one opaque word. With only two constructors, the compiler tests the tag against 0 and switches on the resulting `i1`; a type with more constructors, like the `area` function in [the tour](/docs/tour), gets a constructor case instead. Each branch reads the Float fields straight out of the object with `eco.project.custom`, multiplies them unboxed, and builds a new object with `eco.construct.custom`, whose `slot_kinds` say that every field is a Float (kind 2). Each branch ends in `eco.yield`, which hands its value back as the result of the case.

Nothing in the listing says how big a `Rect` is or how a Float is stored. Those are the backend's decisions.

## The compiler describes values, the backend decides memory

The dialect keeps the program's functional structure until the backend chooses a memory layout. Data types, closures and pattern matches stay as operations instead of becoming loads, stores and branches. We think layout belongs with the collector, which has to read every object, so the backend, the part that knows the collector, decides each layout. Raw allocation operations exist in the dialect, but only the lowering creates them. The compiler never writes one, so it never describes memory, only values.

The verifier follows from the same split. Whatever it proves, the lowering may assume; whatever it does not prove, the lowering takes on trust. Because it runs on every operation each time a module is read, it is kept to checks that look at one operation, or at most at one symbol found through MLIR's cached symbol table. A check that needs the whole module belongs in a pass.

## Types

There are three kinds of type.

- **The boxed value**, `!eco.value`, is one machine word: either the address of a heap object or an embedded constant, told apart by a bit. True, False, the empty list and every constructor with no fields are embedded constants. [Value representation](/docs/value-representation) describes the encoding.
- **Primitives** are plain MLIR types: Int is `i64`, Float `f64`, Char `i16`, and Bool a single bit, `i1`. The single-bit Bool exists only in the intermediate code. In heap fields, in closures and at call boundaries a Bool is always boxed, as one of its two constants.
- **Six aggregate types** hold a small group of values outside the heap: a pair, a triple, a record, a custom-type value, a list cell and a closure environment. They lower to LLVM struct values held in registers, never to heap pointers.

None of these types carries a heap layout. A constructor's tag is an attribute of the operation that builds the value, as `tag = 1` is above, not part of a type. That lets one aggregate type describe a value whether it ends up in registers or in a heap object.

## Operations

There are about 140 operations, and they group by what they describe.

| Group | What it holds | Why it has this shape |
|-------|---------------|------------------------|
| Control | Value-producing case, its yield, join points and jumps to them, return, crash | Elm's case is an expression, and a value-producing case lowers directly to structured if and switch |
| Heap objects | One construction and one projection per runtime layout (list cell, pair, triple, record, custom type), tag reads, embedded constants, boxing and unboxing, globals | Each one commits to a single runtime layout |
| Closures and calls | Partial applications, groups of mutually recursive closures, extending a partial application, direct and indirect calls | A call states whether its target is a named function or a closure, and how many arguments remain, so the lowering works out neither |
| Arithmetic | About 75 operations on Int, Float, Char and Bool | Elm defines results the machine does not, such as integer division by zero giving 0, so each operation names the Elm meaning |
| Typed intrinsics | String operations, list append and map, array operations, structural equality, comparisons returning an `Order` | Each replaces a call to a generic kernel function with one the lowering can specialise by type |
| Aggregates | Building aggregates, moving values between aggregate and heap form, building a closure | The compiler keeps short-lived values out of the heap and says where they must be boxed |

Join points exist because a value-producing case cannot jump out of one of its branches. Tail recursion is written as a jump to a join point, labelled code the function can jump back to with new arguments, and that becomes a loop.

## What the verifier checks

The verifier guarantees a short list of facts, each visible on one operation and cheap to test:

- **Each field's kind matches its operand's type.** Constructions carry one small number per field: 0 for boxed, 1 for Int, 2 for Float, 3 for Char. The verifier works the kind out from each operand's type and requires the attribute to equal it.
- **No single-bit Bool goes into a heap or closure slot.** The collector reads every kind-0 slot as a boxed word, and a bare 0 or 1 is not one.
- **A case is well formed**: one tag per alternative, a scrutinee whose type fits the case kind, and every alternative a single block ending in a yield of the right types.
- **Objects fit the header**: at most 2040 fields for a custom type, 2047 for a record, 2047 parameters for a closure. The verifier reads these limits from the runtime's own heap header definitions, so the two cannot disagree.
- **A constructor with no fields is never built as a heap object.** It is always an embedded constant.
- **Calls and closures agree with themselves**, for example an indirect call's remaining arity equals the number of arguments it passes.
- **Every referenced symbol exists.**

Here is the field-kind check, from the verifier (trimmed):

```cpp
static uint8_t fieldKind(Type t) {
  if (t.isInteger(64)) return 1;
  if (t.isF64()) return 2;
  if (t.isInteger(16)) return 3;
  return 0;
}
...
  for (unsigned i = 0; i < slots.size(); ++i) {
    Type t = slots[i];
    if (t.isInteger(1))
      return op->emitOpError(what) << " " << i
             << " has i1 type: Bool must be boxed to !eco.value before construction";
    const uint8_t k = fieldKind(t);
    ...
    if (uint8_t(want) != k)
      return op->emitOpError("slot_kinds[") << i << "] = " << int(want)
             << " does not match operand type " << t << " (kind " << int(k) << ")";
  }
```

The type decides the kind and the attribute is only compared with it. The lowering never reads `slot_kinds`: it derives every layout from operand types, so the attribute is a cross-check on the compiler, never a second source of truth. It stays because it is the only check in a production build that the compiler's idea of a layout agrees with the values it passes.

Each rule has a reason. The kinds are a list of small integers rather than one packed word because the compiler is written in Elm, whose Int is exact only up to 2^53. Two bits per field are needed, not one: a single "unboxed" bit assumes every unboxed field is an Int, and corrupts Floats and Chars when they are boxed again. Old packed-bitmap attributes are rejected rather than ignored, because MLIR would otherwise carry them along as unknown attributes and a stale cached module would go wrong silently.

The yield rule is strict because a value-producing case lowers to structured control flow, which has no way to leave a branch early. A return inside a branch would have nowhere to go.

The size limits come from the header. A custom-type object records the kinds of 24 fields in its header and a record those of 32; either can add up to 63 extra words of kinds, a bound set by a 6-bit header field and by keeping objects below the large-object threshold. That gives 2040 fields. A record could reach 2048 but is capped at 2047, because a record's constructor is also a function taking one argument per field, and a closure's arity field has 11 bits. With the cap, every constructor can be used as a function value.

A constructor with no fields has one representation because of equality. The equality fast path answers "not equal" as soon as two words differ and either is an embedded constant, so a heap copy of `Nothing` would compare unequal to `Nothing`.

## What the verifier leaves to the compiler

Three facts the lowering relies on have no verifier behind them.

A direct call's arguments are not compared with the callee's signature. That check would need a module-wide symbol lookup per call, and such lookups dominate lowering time. A mismatch surfaces in LLVM instead. One bounded case is checked: when the arguments added to a closure can be traced, through a short chain of operations, back to the closure's creation, the verifier compares them with the function's parameters, and gives up silently otherwise. It exists because LLVM's own message for that mismatch, "Calling a function with a bad signature!", says nothing about where it came from.

The masks that mark which fields of a pair or triple are unboxed, and the kind of a list cell's head, are read by the lowering directly. Only the compiler's own tests check them.

The remaining arity on indirect calls and the case kinds are checked only for consistency with the operation itself. Whether they match what the program means is the compiler's job.

The verifier always runs when a module is read; the production compiler skips it between passes, since compile time shapes the whole backend.

## Effects and folds

Purity in the dialect is narrow on purpose. Two permissions are easy to confuse here. An operation that may be *deleted* when its result is unused need not be one that may be *merged* with an identical operation. Most constructions, projections and arithmetic operations are marked pure, and the fixed-size constructions are pure even though they allocate, so MLIR may delete one whose result is unused. But merging two identical constructions would be wrong. Two objects that each hold a NaN are separate, and the equality fast path compares identity first, so merging them changes the answer of `==`. The pipeline therefore does not run MLIR's common subexpression elimination; that, not the purity mark, keeps allocations apart. Variable-size allocations such as list append carry no traits at all, so MLIR neither merges nor deletes them.

A call declares its memory effects explicitly. A direct call may carry a marker, `eco.cse_safe`, that lets it be merged or deleted, but never moved ahead of the condition that guards it. The pass that prepares for garbage collection strips the marker, so no later pass can act on it.

Folds rely on immutability. A projection from a construction earlier in the same function folds to the operand that was stored, and a tag read folds to the constant tag. eco heap objects are written once, so the field read back is always the one written. Reads such as string length and structural equality are marked pure for the same reason.

There are no root operands. No operation lists the boxed values live across it; LLVM finds the collector's roots from liveness, as [the backend](/docs/backend) explains. Roots could not be computed in the lowering anyway: by then boxed values have become plain integers, and liveness cannot tell pointers from numbers.

## Aggregates and the byte-sequence dialect

The compiler emits pairs, triples and custom-type values as aggregates by default and boxes them where a value escapes; the dialect supplies only the mechanism. LLVM promotes the aggregates to registers before statepoints are placed, because statepoint rewriting cannot handle a struct holding a heap pointer across a call.

Fused encoding and decoding of byte sequences uses a separate dialect, `bf`, described in [Bytes fusion](/docs/bytes-fusion). Keeping it apart lets byte fusion be switched on and off without touching the eco operations.

> **Designs we didn't use.** Checking every call against its callee's full signature in the verifier would catch type mismatches early, but the module-wide lookups it needs dominate lowering time, so only the bounded closure check remains.

## Further reading

- [The backend](/docs/backend) — what happens to the module after it is verified.
- [Lowering passes](/docs/lowering-passes) — how these operations become LLVM code.
- [MLIR generation](/docs/mlir-generation) — how the compiler produces these operations.
- [Value representation](/docs/value-representation) — the encoding behind `!eco.value`.
- The full design document: [The eco dialect theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/backend/eco-dialect.md)
- Source: [`runtime/src/codegen`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/codegen)
