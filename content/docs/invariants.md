---
title: "The numbered invariants"
description: "Why eco keeps a catalogue of 417 numbered rules linking its Elm-written compiler to its C++ back end and runtime, and how one rule, that integer division is total, is traced from its catalogue row to the lowering, the kernel and the tests that enforce it."
section: "Getting it right"
sectionOrder: 5
order: 3
---

eco is two programs that must agree on everything: a compiler written in Elm that emits MLIR, and a back end, runtime and kernels written in C++ that consume it. No type system spans that boundary. If the compiler and the runtime disagree about how a closure stores a `Bool`, both sides still compile and the program fails at run time. We therefore write the agreements down as numbered rules, 417 of them at the time of writing, and every check that enforces a rule quotes its number.

> **Background**
>
> - [Lowering](/docs/glossary#lowering): rewriting high-level operations into lower-level ones, here from eco's own MLIR dialect towards LLVM.
> - [Kernel](/docs/glossary#kernel): a function with no Elm body, implemented in C++ by the runtime.

## One line per rule

The catalogue is a single flat file with one rule per line: its number, the phase it belongs to, a category, a status, the rule itself, and the sources that implement or check it. A number is a family prefix and three digits. `CGEN_` rules constrain code generation, `HEAP_` rules the heap layout and collector, `MONO_` and `LSS_` rules the specialization passes, and so on. Code generation and the heap are the largest families, with about ninety rules each.

The status says what stands behind a rule. At the time of writing 294 are *enforced* by a check that runs, 42 are *tested*, 57 are *documented* but not yet checked, and the remaining 24 are implemented, implied, structural or retired. Numbers are never reused, because they are quoted in commit messages, code comments, test names and crash messages, and a reader holding an old number must land on the rule it meant. A retired rule keeps its row and says why it was retired.

A rule's check lives wherever it is cheapest to write: an Elm checker over the compiler's intermediate forms, a verifier on an MLIR operation, an MLIR fixture, a runtime unit test, an end-to-end program or a TLA+ model. The quoted number is the only link between rule and check.

## One rule, traced

Here is how one rule runs through the system. Elm says integer division never crashes: `7 // 0` is `0`. In LLVM, signed division by zero, or of the smallest integer by −1, is undefined behaviour, and on x86 it traps. Rule `CGEN_084` closes that gap. Its row begins (trimmed):

```text
CGEN_084;MLIR_Codegen;IntegerDivision;tested;Integer division and remainder are total
on all of Int, with wrapping two's-complement results: x // 0 = 0,
x // -1 = 0 - x wrapping (MIN_INT // -1 = MIN_INT), remainderBy 0 x = remainderBy -1 x = 0,
modBy -1 x = 0 and modBy 0 x = 0 in the inline lowering. ...
```

The source column then names the lowering, the kernel and four MLIR fixtures. The **lowering** of the division operation quotes the rule and explains how it keeps both bad divisors away from the hardware instruction:

```cpp
        // CGEN_084: x // 0 = 0 and x // -1 = 0 - x, wrapping (MIN_INT // -1 =
        // MIN_INT). `sdiv` by 0 and MIN_INT by -1 are LLVM UB (SIGFPE on
        // x86), so neither divisor reaches it: rhs in {-1, 0} (one unsigned
        // compare: rhs + 1 <=u 1) divides by 1 and takes rhs * lhs instead,
        // which is 0 or the wrapping negation.
```

From the integer-arithmetic lowering pass. One unsigned comparison catches both divisors, and a select then picks `rhs * lhs`: `0` for a zero divisor, the wrapping negation for −1.

Division does not always go through the inline lowering. Where the compiler emits a call to the kernel function instead of the inline operation, the C++ **kernel** must give the same answers:

```cpp
long long idiv(long long a, long long b) {  // CGEN_084: x // 0 = 0, x // -1 = wrapping -x
    return b == 0 ? 0 : b == -1 ? static_cast<long long>(0ULL - static_cast<unsigned long long>(a)) : a / b;
}
```

From the core kernel's `Basics` module. The one deliberate difference is recorded in the rule: the kernel's `modBy 0` still throws, as elm/core's JavaScript does.

Two tests pin the two paths. An **MLIR fixture** runs the three operations on `MIN_INT` and −1 in the JIT and checks each printed result on its own line; [How we know it works](/docs/verification) shows it and the test gap it closed. A **kernel unit test**, registered under the name "K14 kernel integer division is total (CGEN_084)", calls the exported kernel functions with operands the C++ compiler cannot fold away:

```cpp
    volatile int64_t minInt = INT64_MIN, neg1 = -1, zero = 0, seven = 7;
    TEST_ASSERT(Elm_Kernel_Basics_idiv(minInt, neg1) == INT64_MIN);
    TEST_ASSERT(Elm_Kernel_Basics_idiv(seven, neg1) == -7);
    TEST_ASSERT(Elm_Kernel_Basics_idiv(seven, zero) == 0);
```

From the kernel export tests (trimmed). A failure in either test names the rule, and the rule names every place that must change together.

## What the catalogue does not do

No tool reads the file. It is a discipline, not a mechanism, and it stays accurate because a rule normally lands in one commit with the code it governs and the check that tests it. A status is the author's claim at the last edit; the checks are the authority on what is checked. A checker that turns out to inspect nothing is rewritten, and its row amended to say what it does check, rather than left to promise coverage it does not give.

## Further reading

- [How we know it works](/docs/verification) — the test layers that carry these checks.
- [The eco dialect](/docs/eco-dialect) — the operations many of the rules constrain, and their verifiers.
- [Kernels](/docs/kernels) — why every kernel must agree with the inline lowering of the same function.
- The full design document: [Invariants theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/invariants/invariants.md)
- Source: [`design_docs`](https://github.com/eco-lang/eco-compiler/tree/master/design_docs), where the catalogue lives
