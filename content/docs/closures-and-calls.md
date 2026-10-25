---
title: "Closures and calls"
description: "How Eco represents every Elm function value as a heap closure whose header says how to apply it, so that one generic runtime routine is always correct and the compiler adds faster paths only where it can prove they are safe."
section: "The runtime"
sectionOrder: 4
order: 3
---

Every Elm function value in Eco is a closure on the heap, and its header says everything needed to call it: how many arguments it takes, how many it already holds, and how each one is stored. One runtime routine can therefore apply *any* closure to *any* number of arguments, with no help from the call site. Because that generic path is always correct, every faster path the compiler adds is optional, and the compiler takes one only where it can prove, or cheaply check, that it is safe.

> **Background**
>
> - A [closure](/docs/glossary#closure) is a function value together with the values it captured from its surroundings.
> - A [partial application](/docs/glossary#partial-application) (PAP) is a closure that has received some of its arguments but not all.
> - [Staging and arity](/docs/glossary#staging-and-arity): a stage is the group of parameters a closure takes in one application, and its arity is how many there are.

## One small example

The shapes program from [A tour through the compiler](/docs/tour) contains `twice (add 1) 10`, where `add a b = a + b` and `twice f x = f (f x)`. Eco's compiler emits this for it (trimmed: operand types removed):

```mlir
%4 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @Main_add_$_1, num_captured = 0} : () -> !eco.value
%5 = "arith.constant"() {value = 1 : i64} : () -> i64
%2 = "eco.papExtend"(%4, %5) {_call_kind = "direct_known_segmentation", remaining_arity = 2, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> !eco.value
%3 = "arith.constant"() {value = 10 : i64} : () -> i64
%8 = "eco.papExtend"(%2, %3) {_call_kind = "singleton_fast", _capture_abi = [i64], _fast_evaluator = @Main_add_$_1, remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> i64
%9 = "eco.papExtend"(%2, %8) {_call_kind = "singleton_fast", _capture_abi = [i64], _fast_evaluator = @Main_add_$_1, remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> i64
```

`%4` is the closure for `add`: no captures, a stage of two parameters, an `Int` result (`_result_kind = 1`). `%2` applies it to one argument and gets back a partial application holding the raw `Int` 1. The two calls inside `twice` then apply `%2` to one more argument each. The compiler has proved that `%2` can only ever be this one closure, so it marks those calls `singleton_fast` and names `Main_add_$_1` as the function to call directly, with the captured `1` loaded at type `i64`. No header is read on that path. How the compiler proves it is the subject of [Lambda-set specialization](/docs/lambda-set-specialization).

## The closure object

![Closure layout: an 8-byte header, a packed word of applied arity, stage arity, result kind and slot kinds, a pointer to a static evaluator descriptor, then one 8-byte slot per captured value](/images/docs/closure-layout.svg)

After the usual 8-byte heap header comes one packed word, then a pointer to a static descriptor, then the captured values, one 8-byte slot each (from the runtime's heap definitions, trimmed, with comments shortened):

```cpp
struct EvaluatorDesc {
    EvalFunction   generic;      // +0   generic entry taking an argument array
    ...
    unsigned char  result_kind;  // +17  kind of the compiled return value
    unsigned short stage_arity;  // +18
    ...
    void*          sat[];        // +24  fast entries indexed by argument count
};

typedef struct {
    Header header;
    u64 n_values   : 11;     // arguments already applied to this stage
    u64 max_values : 11;     // stage arity
    u64 result_kind: 2;      // boxed, Int, Float or Char
    u64 unboxed    : 40;     // 2-bit kinds for parameters 0..19
    const EvaluatorDesc* evaluator;   // static data, not a heap pointer
    Unboxable values[];
} Closure;
```

The remaining arity is `max_values - n_values`, read from the header alone. The descriptor is static data emitted next to the compiled code, so the collector never traces it. The slot kinds cover every parameter of the stage, captured or still to come, so the runtime can convert each incoming argument to the form the body expects. A C++ kernel passing boxed values and compiled code passing a raw `Int` both end up producing exactly the encoding the body was compiled for. Parameters past the twentieth keep their kinds in extra words at the end of the object, so a stage can take up to 2047 parameters while the common case reads only the packed word.

The result kind lives on the closure rather than at the call site because a call site often cannot know it. For a staged closure, the static type at the call site describes an inner function, not the real return; a kernel calling a closure has no static type at all. Only `Int`, `Float` and `Char` are ever stored raw; `Bool` is boxed in every slot (see [Value representation](/docs/value-representation)).

## Generic apply is always correct

The runtime's generic apply looks at the closure header and splits into three cases: too few arguments, exactly enough, or too many. This is the eval/apply model GHC also uses, where the callee's arity is read from the function value at run time rather than assumed by the caller. In outline:

```text
apply(closure, args[0..n)):
    remaining = closure.max_values - closure.n_values
    if n <  remaining: return a new, bigger partial application
    if n == remaining: call the evaluator with captures ++ args
    if n >  remaining: next = call with the first `remaining` args
                       return apply(next, the rest of args)
```

Here is the real routine, trimmed to its skeleton (from the runtime's closure-apply routine; rooting, validation and statistics removed):

```cpp
Closure* closure = static_cast<Closure*>(closure_ptr);
uint32_t remaining = closure->max_values - closure->n_values;
uint8_t K = closure->result_kind;

if (num_args < remaining) {
    HPtr extended = eco_pap_extend_l(HPtr::fromBits(closure_bits),
                                     reinterpret_cast<uint64_t*>(typed_args),
                                     num_args, args_layout);
    *static_cast<HPtr*>(result_slot) = extended;
    return;
}
if (num_args == remaining) {
    invokeSaturatedTyped(closure_bits, typed_args, num_args, args_layout,
                         K, desired_kind, result_slot);
    return;
}
// Over-saturated: saturate this stage, then apply the rest to its result.
HPtr intermediate = eco_closure_call_saturated(
    HPtr::fromBits(closure_bits),
    reinterpret_cast<uint64_t*>(typed_args), remaining, args_layout);
uint32_t trailing = num_args - remaining;
// ... build a layout for the trailing arguments ...
eco_apply_closure_eval(intermediate, typed_args + remaining,
                       trailing, sub, result_slot, desired_kind);
```

The over-saturated case asks nothing of the caller about how the callee is staged: it saturates this stage, takes the closure that stage returns, and applies it to whatever is left. That is why a call site can always fall back to this routine, whatever it does or does not know.

Extending a partial application never changes the closure in place. It allocates a new closure, copies the captures, converts each new argument to its slot's kind, and shares the descriptor. Because closures are never written after they are built, a closure with no captures can be a single shared object, and every closure obeys the rule the collector rests on (see [The garbage collector](/docs/garbage-collector)).

## Faster paths, proven or guarded

The compiler records on every call through a function value what it could establish about the callee. The faster paths come in two sorts, and the difference decides what a bug in the compiler's analysis would cost:

- A **proven** path trusts a fact the compiler recorded and checks nothing at run time. The `singleton_fast` calls above are proven: the compiler names the one function the closure can be.
- A **guarded** path reads the closure header, compares it with what the call site knows, and falls back to generic apply on any mismatch. It cannot miscompile.

| What the compiler knows | What the call becomes | Checked at run time |
|---|---|---|
| The callee is one specific closure | a direct call to its body, captures loaded at known types | nothing |
| The remaining arity, and the call saturates | a saturated-call entry, behind a fast edge | the fast edge's guards |
| The remaining arity, and the call is partial | the runtime's extend routine | only that the stage does not overflow |
| Nothing, or only parameter types | generic apply, behind a fast edge | everything, from the header |

The fast edge is the guarded path for calls the compiler could not pin to one closure. A generic call site knows how many arguments it passes and their kinds, but not how many captures the callee holds. Each descriptor therefore carries a small table, `sat[N]`, of entries that each take exactly N new arguments in registers and load the captures themselves. The fast edge reads the packed word and checks that the closure needs exactly N more arguments, that all its kinds fit in the packed word, that its result kind and remaining slot kinds match the call site's, and that `sat[N]` exists. If every check passes, the call goes straight to the entry and skips the argument array, its root registration and the runtime's argument splicing. Any failure takes the unchanged generic path, so a missing entry costs speed, never correctness.

## How much it matters

On the compiler compiling itself, the whole generic path (generic apply, the saturated dispatch and the extend routine) is a couple of percent of CPU cycles in self time. Lambda-set specialization is what keeps it that low. In one measurement, the same self-compile was run by a compiler built without lambda-set specialization and by one built with it: generic applications fell by roughly three quarters, and the share of calls with a statically known target rose from about 84% to about 94%.

> **Designs we didn't use.** We rejected a uniform boxed calling convention with a generated partial-application wrapper per closure, because it would box every captured number on the way in and unbox it on the way out. Lambdas are typed end to end instead, so captured `Int`s, `Float`s and `Char`s flow raw, and the only wrapper left is the one behind the descriptor's array-taking entry.

## Further reading

- [Lambda-set specialization](/docs/lambda-set-specialization) — how the compiler learns which closures can reach a call.
- [Global optimization](/docs/global-optimization) — where stages are chosen and call kinds recorded.
- [Value representation](/docs/value-representation) — the slot kinds and the boxed word.
- [Lowering passes](/docs/lowering-passes) — how `eco.papExtend` becomes LLVM calls.
- The full design document: [Closures and calls theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/closures-and-calls.md)
- Source: [`runtime/src/allocator`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/allocator)
