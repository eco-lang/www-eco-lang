---
title: "How we know it works"
description: "How eco is tested, from checkers that walk the compiler's intermediate forms to whole programs, hand-written MLIR fixtures, property tests on random heaps and weak-memory model checking, each layer aimed at the bugs the others cannot see."
section: "Getting it right"
sectionOrder: 5
order: 1
---

A compiler bug is cheapest to find with the check closest to where it was made. A phase that breaks its contract can still produce a program that prints the right answer, a wrong lowering of one operation can hide among the hundreds a real program uses, and a race between collector threads may show up once in a million runs. eco therefore has no single test suite. Each class of bug gets the cheapest check that can catch it, and no layer tries to catch everything.

> **Background**
>
> - [MLIR](/docs/glossary#mlir): the compiler framework whose textual form sits between eco's Elm-written front end and its C++ back end.
> - [SSA](/docs/glossary#ssa): the form in which every value is defined exactly once and referred to by name.
> - [JIT and AOT](/docs/glossary#jit-and-aot): running compiled code straight from memory, or producing a native executable first.
> - [Fixed point](/docs/glossary#fixed-point): a compiler that, rebuilt with itself, produces itself again byte for byte.
> - [Model checking](/docs/glossary#model-checking): exploring every interleaving of a small concurrent system to see whether a property can fail.

## What each layer can see

The useful question about a test is what it can see and what it cannot. This table is how we decide where a new test belongs.

| Layer | Catches | Misses |
|---|---|---|
| Checkers over the compiler's intermediate forms | A broken intermediate form, at the phase that broke it | Anything about the running program |
| Whole programs with expected output | Wrong output, crashes, collector bugs under real code | Contract violations that happen to give the right output; rare thread schedules |
| Agreement between back ends and bootstrap stages | Divergence between two compilers or two back ends; nondeterminism | Bugs that every stage shares identically |
| Hand-written MLIR fixtures | A wrong lowering of one operation; inputs no Elm program can produce | Whether the compiler ever emits that MLIR |
| Property tests on random heaps | Values lost, moved or corrupted by a collection | Races between threads |
| ThreadSanitizer, GenMC and the formal models | Data races, wrong memory orders, protocol races at small sizes | Bugs outside the modelled code; code too large for the checker |

Most of these tests are compiled by the compiler they check, so a bug present in every stage of the compiler could pass all of them, which is why agreement between stages counts as a layer of its own.

## Checkers that walk the compiler's output

The compiler is written in Elm, and its tests are too. A shared corpus of small Elm programs, built as syntax trees rather than source text, is compiled through the same list of whole-program steps that `eco make` runs. Then one checker per rule walks the form a phase produced: the canonical syntax tree, the typed graph, the monomorphic graph, the globally optimised graph, or the Elm data structure the compiler builds just before printing MLIR. A checker never runs the program. It asks a question that must hold for every program, such as whether any SSA name is defined twice.

```elm
expectSsaUniqueness : Src.Module -> Expectation
expectSsaUniqueness srcModule =
    case runToMlir srcModule of
        Err err ->
            Expect.fail ("Compilation failed: " ++ err)

        Ok { mlirModule } ->
            violationsToExpectation (checkSsaUniqueness mlirModule)
```

From the compiler's test suite, the check that no generated function redefines a visible name. The check takes one program and knows nothing about the corpus, so registering a new case module extends every checker at once, and a program written to test one rule is checked against all of them. A program that fails to compile fails the check; it does not count as a pass with nothing to inspect.

The rule that makes this suite worth running is that it compiles exactly as production does. A harness that assembled its own pipeline could pick a different specialization engine or skip a pass, and would then vouch for code no user runs. A small script fails the test run if the test harness calls any compiler pass directly instead of going through the shared steps. The suite runs on the JavaScript build of the compiler, so it needs only Elm and Node and can run before any native toolchain exists. Fuzzing varies only the structure of programs: the compiler treats the literal `42` and the literal `7` alike, so random leaf values reach no new code.

## Whole programs that carry their own answer

The representation rules, such as which values a closure stores unboxed, are broken at the boundary between the generated code and the runtime, and that boundary is exercised only when a real program runs. A whole-program test is an ordinary Elm program that logs values with `Debug.log` and lists the lines it must print in comments:

```elm
module CaseTupleTest exposing (main)

{-| Test case expression on tuples.
-}

-- CHECK: pair1: "both zero"
-- CHECK: pair2: "x is zero"
-- CHECK: pair3: "y is zero"
-- CHECK: pair4: "neither zero"

import Html exposing (text)


describePair pair =
    case pair of
        (0, 0) -> "both zero"
        (0, _) -> "x is zero"
        (_, 0) -> "y is zero"
        _ -> "neither zero"


main =
    let
        _ = Debug.log "pair1" (describePair (0, 0))
        _ = Debug.log "pair2" (describePair (0, 5))
        _ = Debug.log "pair3" (describePair (3, 0))
        _ = Debug.log "pair4" (describePair (1, 2))
    in
    text "done"
```

A test from the language corpus. The file is the whole test: no C++ names it, and the runners find it by its directory. Because the expected output lives in the source, no reference implementation is needed and the same file runs unchanged on every back end. Programs that use eco's system library can also state the exit status they must return and text to feed on standard input.

Several runners share this corpus and differ in what a pass proves. The JIT runner checks behaviour. The AOT runner compiles each program to a native executable and must pass what the JIT passes. A JavaScript runner runs the system-library programs under Node, because that library promises the same Elm interface on both back ends. A stress runner scales programs up with start-up flags for size and duration, so the collector runs for a long time under real code. Conformance scripts point the third-party Autobahn WebSocket and h2spec HTTP/2 suites at an example server built for both back ends; for h2spec the bar is a recorded baseline of passing cases that must not fall, because mature servers fail some strict cases on purpose.

Every program runs in its own freshly spawned child process, under a watchdog. A crash, a hang or a corrupted heap then fails one test and not the run. The children are spawned, never forked: a fork would copy the harness's live heap and collector threads, and the test could end up exercising a collector configuration no user runs.

## MLIR fixtures for one operation at a time

A fixture is a small hand-written MLIR file fed straight into the back end, with no Elm compiler involved. It names the stage at which the back end stops and the text the output must or must not contain, in the style of LLVM's FileCheck. Here is the heart of one:

```mlir
    %d = eco.int.div %min_int, %neg1 : i64
    eco.dbg %d : i64

    %r = eco.int.remainderby %neg1, %min_int : i64
    eco.dbg %r : i64

    %m = eco.int.modby %neg1, %min_int : i64
    eco.dbg %m : i64

    %zero = arith.constant 0 : i64
    return %zero : i64
  }
}

// CHECK: [eco.dbg] 4242{{$}}
// CHECK-NEXT: [eco.dbg] -9223372036854775808{{$}}
// CHECK-NEXT: [eco.dbg] 0{{$}}
// CHECK-NEXT: [eco.dbg] 0{{$}}
```

From the fixture that divides the smallest 64-bit integer by −1 (trimmed: the constants and the marker print are omitted). In LLVM, signed division of `MIN_INT` by −1 is undefined behaviour, and on x86 it traps. The fixture exists because the lowering once guarded only against division by zero. The lesson is in why that went unseen: an older fixture already computed `MIN_INT // -1` and printed garbage, yet it passed. Its expected line was satisfied by an *earlier* output line, because plain `CHECK` lines match anywhere in the output. The new fixture chains its lines with `CHECK-NEXT` and anchors each one at the end of the line, so every result is checked where it is printed. The fix makes eco's integer division total, with wrapping results; [The numbered invariants](/docs/invariants) follows that rule through the code.

Fixtures reach what no Elm program can. The front end checks a program before it becomes MLIR, so no source can produce a record one field past the heap's limit, a closure with too many arguments, or a malformed operation the dialect's verifier must reject. Each limit has a fixture at the limit that must compile and a twin one past it that must be rejected. The cost is that a fixture says nothing about whether the compiler ever emits its MLIR, so a new lowering gets both a fixture and an Elm program that reaches it from source.

The directive parser is deliberately strict. An unknown `CHECK-` variant is a hard error, because a parser that skipped it would leave a fixture with a misspelled directive green while it asserted nothing.

## The runtime: random heaps, races and weak memory

Most runtime unit tests are properties, checked with the RapidCheck library: generate a random graph of heap objects, root it, collect, and compare a snapshot of the reachable graph before and after.

```cpp
Testing::TestCase testMinorThenMajorGCSequence("Roots survive minor then major GC sequence", []() {
    rc::check([](const HeapGraphDesc& graph) {
        auto& alloc = initAllocator();
        std::vector<void*> objects = allocateHeapGraph(graph.nodes);
        RC_ASSERT(!objects.empty());
        GraphRoots roots = setupRootsFromGraph(alloc, graph, objects);
        RC_ASSERT(!roots.empty());

        HeapSnapshot snapshot;
        snapshot.capture(objects, roots.ptrs);

        for (u32 i = 0; i <= PROMOTION_AGE; i++) {
            alloc.minorGC();
        }
        alloc.majorGC();

        bool valid = snapshot.verify(roots.ptrs);
        RC_ASSERT(valid);
    });
});
```

From the allocator's property tests (trimmed: comments removed). Heap layout is a combinatorial space of object kinds, unboxed-field bitmaps and shapes, and hand-written cases cover little of it. The snapshot is the oracle, so no separate model of the heap is needed. The tests run on the same nursery that production uses, and a guard in every test child refuses to run on any other.

Property tests almost never produce a rare thread schedule, so three more tools cover concurrency, each filling a gap in the one before:

- **ThreadSanitizer** compiles the real allocator, with only stack unwinding stubbed out, and drives it with a synthetic program while background markers and helpers run. Some harnesses force one known interleaving using only relaxed atomic flags, so the tool sees no ordering except the runtime's own and the race shows on every run.
- **The [formal models](/docs/concurrency-models)** explore every interleaving of each collector protocol at small sizes, but they assume every thread sees writes in one global order.
- **GenMC** closes that gap. It explores every execution of a small program that the C11 memory model allows, which matters on ARM, where a relaxed atomic can be seen out of order. Its drivers compile the real, unmodified allocator headers.

GenMC's results are a useful calibration. Every driver written against the existing code passed: it found no new defect in eco's code, and it confirmed two races that the models and code reading had already found. What it did find were four bugs or gaps in GenMC itself, among them an abort on a `memset` to a constant address and an error report that drops the text of the failed assertion. The drivers work around each one.

Every concurrency defect any tool finds goes into a register and gets a guard that replays it. While the defect is open the guard is an expected failure, and an expected failure that starts passing fails the run, so a defect cannot vanish unnoticed either. Each fix is checked by reverting it and watching the guard fail again.

## Agreement instead of answers

Some checks need no expected output at all. An equivalence check compiles every whole-program test source with two builds of the compiler from different bootstrap stages, one running as JavaScript and one native, and compares the MLIR byte for byte. Any difference is a bug in one of them. The bootstrap adds two fixed points, one for the JavaScript-hosted compiler and one for the native one, described in [The compiler compiles itself](/docs/bootstrap). Two of the test suites run as gates at the earliest points in that chain where they can, so a back-end regression is reported before the slow native self-compiles start.

## Every check must be able to fail

A check that cannot fail is worse than none, because it reports success without evidence. The same rule appears in every layer:

- Each formal model and each GenMC driver comes with mutants, deliberately broken variants that must be rejected with a named failure.
- A replay guard that never reaches its scenario reports "not reached" rather than passing.
- A compiler checker that turned out to inspect nothing, for example by looking for call names that never occur in real output, is rewritten, and making such a check able to fail tends to expose real compiler bugs.
- A test that expects a rejection must match the actual error, not just any failure.

## How much there is

At the time of writing: about 1,345 whole-program tests (about 680 of them in the language corpus, 210 for the system library and 115 stress programs), 449 MLIR fixtures, about 133,000 lines of compiler tests in Elm, eight formal models of the collector and 62 GenMC driver rows. These are counts of files and lines, not of distinct behaviours, and a test program often checks several things at once.

Continuous integration runs the everyday suites and the bootstrap on Linux, macOS and Windows, and the stress and AOT runners on Linux. The model checks, GenMC and the ThreadSanitizer builds take minutes to hours, so we run them by hand when a concurrent protocol changes; a cheap hash check in every build says when that is ([Model-checking the collector](/docs/concurrency-models)).

> **Designs we didn't use.** We did not compare compiler output against golden copies. A correct change to one phase would break every later phase's tests, so the checkers test rules about the output instead.

## Further reading

- [Model-checking the collector](/docs/concurrency-models) — the TLA+ models, their mutants and the canary that ties them to the code.
- [The numbered invariants](/docs/invariants) — the rules these checks enforce, with one traced from rule to test.
- [The compiler compiles itself](/docs/bootstrap) — the bootstrap chain and its two fixed-point checks.
- [The eco dialect](/docs/eco-dialect) — the operations the MLIR fixtures exercise and the verifiers that reject malformed ones.
- The full design document: [Verification theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/verification/verification.md)
- Source: [`test`](https://github.com/eco-lang/eco-compiler/tree/master/test) and [`compiler/tests`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/tests)
