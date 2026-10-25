---
title: "Lowering passes"
description: "Eco lowers its eco dialect to LLVM through about twenty small MLIR passes, each placed at the first point where the fact it needs can be decided and nothing later can make it false."
section: "The backend"
sectionOrder: 3
order: 3
---

Between the eco dialect and LLVM sit about twenty small passes, in a fixed order. The order is the design. Each fact the backend needs becomes decidable at a different moment, so each pass sits at the first point where its inputs are complete and where nothing later can make its answer false. Every pass then writes its answer down, as an attribute or a flag, so no later stage has to work it out again.

> **Background**
>
> - [Lowering](/docs/glossary#lowering) — rewriting operations into simpler ones closer to the machine; a *pass* is one such rewrite over the whole module.
> - [Dialect](/docs/glossary#dialect) — a family of MLIR operations; Eco lowers from its own [eco dialect](/docs/eco-dialect) to MLIR's standard ones and then to LLVM's.
> - [Safepoint](/docs/glossary#safepoint) — a call at which the collector may run; LLVM later turns each into a [statepoint](/docs/glossary#statepoint-and-stack-map).

## A first lowering

The smallest example is a constant. In the eco dialect, `True` is an operation that produces a boxed value. One of the lowering's test fixtures checks what it becomes:

```mlir
func.func @get_true() -> !eco.value {
  // True constant should lower to word 5
  %true = eco.constant True : !eco.value
  // CHECK: llvm.mlir.constant(5 : i64)
  return %true : !eco.value
}
```

After lowering, `True` is the 64-bit word 5, and `[]` in the same fixture is the word 6. The boxed type `!eco.value` has become a plain `i64`. Both numbers come from the runtime's value encoding, described in [Value representation](/docs/value-representation): low bits that mark the word as a constant rather than a heap pointer.

Arithmetic shows why the lowering must carry Elm's meaning, not the machine's. In Elm, integer division is total: `x // 0` is 0. In LLVM, dividing by zero is undefined behaviour, and on x86 it crashes the process. Dividing the smallest integer by −1 is undefined too, because the true result does not fit. The lowering of `eco.int.div` keeps both divisors away from the machine instruction (trimmed: the comment is shortened):

```cpp
Value lhs = adaptor.getLhs();
Value rhs = adaptor.getRhs();

// rhs in {-1, 0} (one unsigned compare: rhs + 1 <=u 1) divides by 1
// and takes rhs * lhs instead, which is 0 or the wrapping negation.
auto one = rewriter.create<arith::ConstantIntOp>(loc, 1, /*width=*/64);
auto rhsPlus1 = rewriter.create<arith::AddIOp>(loc, rhs, one);
auto isSpecial = rewriter.create<arith::CmpIOp>(loc, arith::CmpIPredicate::ule,
                                                 rhsPlus1, one);
auto safeRhs = rewriter.create<arith::SelectOp>(loc, isSpecial, one, rhs);

auto divResult = rewriter.create<arith::DivSIOp>(loc, lhs, safeRhs);
auto specialResult = rewriter.create<arith::MulIOp>(loc, rhs, lhs);
auto result = rewriter.create<arith::SelectOp>(loc, isSpecial, specialResult,
                                               divResult);
```

One unsigned comparison catches both special divisors: adding 1 maps −1 to 0 and 0 to 1, and every other value lands above 1. For those two cases the code divides by 1 and selects `rhs * lhs` instead, which is 0 for a zero divisor and the wrapping negation for −1. There is no branch, and the hardware never sees a bad divisor.

## The order, in three layers

One function builds the pass list, and every tool that compiles Eco code calls it. The list has three nested layers, and a developer tool can stop after any of them and print the module. In outline, with validation-only checks in brackets:

```text
eco to eco:          reference-counting guard; [closure-capture check]
                     closure simplification; comparison-to-case rewrite
                     declaration check
structured control:  join points to loops; case to scf.if / scf.switch
                     chunked-list builder (when enabled)
                     fold slot: projection folder (on), CSE (off)
to LLVM:             copy "cannot collect" onto kernel calls
                     GC preparation               <- fence: no merging or motion after this
                     [purity audit]
                     byte-sequence lowering; eco to LLVM; list cursors
                     [stale-pointer check]; scf to branches to LLVM
                     reachability; capacity-hoist plan
                     gc-free propagation          <- fence: last body rewrite
```

Two fences shape everything else. Garbage-collection preparation ends the window in which eco operations may be merged or moved. Gc-free propagation ends the window in which function bodies may be rewritten. Every other pass is placed relative to those two points.

## Simplify while the pattern is still visible

The first layer works on eco operations only. Its passes either check something the compiler promised or simplify something that is still one or two operations.

Closure simplification is the clearest case. When a closure holding some of a function's arguments is created and immediately given the rest, the pair becomes a direct call. It belongs here because a saturated closure is a two-operation pattern in the eco dialect. After conversion to LLVM the same thing is spread across runtime calls and memory layouts, and is hard to recognise.

A comparison whose only use is a case on its `LT`, `EQ` or `GT` result becomes nested Boolean tests, which removes both the call and the `Order` value. It runs after closure simplification, so comparisons made through closures are already direct, and before the declaration check, because it may add a declaration for the comparison kernel.

The layer ends with a check that every called function is declared. It never invents a missing declaration from a call site: that would hide a code generation bug behind a guessed signature.

## Structured control flow, then the fold slot

The second layer turns Elm's control flow into MLIR's structured control flow, whose if, switch and while operations hold their branches as nested regions that yield values. That form fits Elm, where a case is an expression: each eco case alternative ends by yielding a value and maps directly onto a value-producing if or switch. Tail-recursive join points map onto while loops.

The fold slot follows. A field projection or tag read from an object built earlier in the same function folds to the stored operand or the constant tag. MLIR's common subexpression elimination has its place in this slot too, and is off, because it is unsound for Elm: turning it on makes three Float equality tests fail. Two constructions that each hold a NaN are separate objects, and the equality kernel answers True when both sides are the same object, as Elm's own JavaScript does; merging them turned a False comparison into True. Object identity is observable in Elm through NaN, so deduplicating an allocation does not preserve meaning.

The slot must sit before garbage-collection preparation, because preparation strips the purity marker that merging relies on.

## Preparing for the collector

The third layer begins by copying the "cannot collect" fact from each kernel declaration onto every direct call to that kernel. It runs here because by now every pass that can add a kernel call has run. The fact goes on the call itself because later per-function passes cannot see sibling declarations.

Garbage-collection preparation does not decide what the collector sees, although its name suggests it does. LLVM works out the roots later, from which heap pointers are live at each call, as [The backend](/docs/backend) explains. Preparation has two jobs:

1. It groups adjacent allocations, so one request to the nursery can serve several objects. A run where every member could use the inline bump fast path is split back into single allocations, because a single inline allocation costs no call at all; in practice only mixed runs, such as those containing a string, stay grouped.
2. It strips the purity marker from calls. From then on MLIR treats every call as having unknown effects, which ends all merging and motion.

## One conversion pass, built for threads

The conversion from eco to LLVM's dialect does the bulk of the work. It is one pass with internal stages, so it can convert function bodies in parallel without locks:

1. Allocation groups become their fast, slow and merge blocks.
2. Every function signature and module-level global is lowered.
3. Everything a body might need at module level is created in advance: runtime declarations, string globals, closure wrappers and layouts. Then the symbol cache is frozen.
4. Function bodies are converted in parallel chunks that only read shared state.
5. A closing step attaches the collector strategy to each function, builds the global initializer and strips unused declarations.

Step 3 is what makes step 4 safe: a body that needed to create a declaration would be writing to the module from many threads at once.

Structured control flow is lowered to plain branches only after this, so the values a loop carries are already LLVM types when branches create block arguments for them. One pass does that work, per function, in parallel chunks, in place of MLIR's three upstream conversions. Those rebuild a converter for every function and lower branches serially.

## Whole-program facts, last

Three planning passes run on the final LLVM-dialect module, so they see every call the pipeline has created:

1. **Reachability** removes every function nothing can call and makes the rest internal. On the compiler's own source that is roughly a quarter of the functions, which translation then never sees. It is safe because an executable exposes only its entry point.
2. **The capacity plan** decides where a callee's nursery capacity check can move into its caller, and stamps the decision on each function.
3. **Gc-free propagation** stamps every function that provably cannot reach a collection, so LLVM puts no statepoints on calls to it.

Reachability goes first so the planners see only live code. Gc-free propagation reads the capacity plan, so it follows it, and it must be the last pass to change a function body: a later rewrite could add a collecting call to a function already stamped as safe, and no check on a single partition would notice.

These passes run in MLIR rather than LLVM because an MLIR context can be shared between threads and an LLVM context cannot. Every whole-program decision made here lets the backend split the module into partitions before translating it. The stamps travel with each partition, and the backend checks them again before relying on them: a missing or stale stamp stops the build instead of producing a wrong stack map.

## Same output, in parallel

The lowered program is tens of thousands of tiny functions, and where a pass boundary is not set by a fact, it is usually set by keeping that work parallel. Stages hand out functions in chunks, not one at a time, because MLIR's per-element parallel loop takes a lock for every element. The folder is a module pass for the same reason: run nested per function, its tens of thousands of instances would serialize on a lock in MLIR's pass instrumentation.

Every parallel stage must produce output byte-identical to the serial path. The native bootstrap reaches its [fixed point](/docs/glossary#fixed-point) by comparing the bytes of successive compilers, so a stage whose output depends on thread scheduling breaks the bootstrap even when its code is correct.

## Checks that never repair

Several passes check and never fix: the reference-counting guard, the declaration check, the closure-capture check, the purity audit after preparation and the stale-pointer check before boxed stores. Each failure points to a bug in the compiler, and a pass that repaired its input would hide that bug. Most of the checks are compiled only into validation builds, and release builds also skip the verifier between passes, so keeping validation in passes of its own makes removing it free.

> **Designs we didn't use.** The obvious alternative is a tail-call conversion that fuses all three lowerings into one rewrite. We rejected it because our fused version corrupted memory even on a single thread, and a separate lowering to branches is simpler to get right.

## Further reading

- [The eco dialect](/docs/eco-dialect) — the operations these passes consume, and what the verifier has already checked.
- [The backend](/docs/backend) — what LLVM does with the result: statepoints, partitions, the link.
- [Closures and calls](/docs/closures-and-calls) — how closure operations lower and the wrappers created in advance.
- [The garbage collector](/docs/garbage-collector) — the nursery that allocation groups and capacity checks serve.
- The full design document: [Lowering passes theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/backend/lowering-passes.md)
- Source: [`runtime/src/codegen/Passes`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/codegen/Passes)
