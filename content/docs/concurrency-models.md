---
title: "Model-checking the collector"
description: "How Eco checks its concurrent garbage collector with small TLA+ models that a model checker explores exhaustively, deliberately broken mutants that prove each model can fail, and a hash canary that says when the code a model describes has changed."
section: "Getting it right"
sectionOrder: 5
order: 2
---

Eco's collector marks, copies and tenures objects on background threads while the program runs. Its worst bugs do not crash where the mistake is made: a lost mark bit frees a live object, and the damage shows up much later as a wrong result somewhere else. Ordinary tests rarely hit the schedule behind such a bug, so each concurrent protocol is also written as a small TLA+ model, a model checker tries every interleaving of it on a small heap, and a build step watches the code each model describes and says when the two may have drifted apart.

> **Background**
>
> - [TLA+](/docs/glossary#tla): a language that describes a system as states and the atomic steps between them.
> - [Model checking](/docs/glossary#model-checking): exploring every reachable state of a model and checking named properties in each.
> - [Mutator](/docs/glossary#mutator): the thread that runs the Elm program and allocates; Eco has one per process.
> - [Nursery and eden](/docs/glossary#nursery-and-eden), [tenuring](/docs/glossary#tenuring): where young objects live, and how long-lived ones move to the old generation.

## A bug in four lines

The simplest model in the repository shows the whole method. It is the same lightweight use of TLA+ that engineers at Amazon Web Services have described for finding subtle bugs in distributed protocols. Two threads each set a different bit in one byte, the way two marker threads can mark two objects whose mark bits share a byte. The model is written in PlusCal, an algorithm-like language that translates into TLA+. A constant chooses between a plain read-modify-write, which takes two steps, and an atomic `fetch_or`, which takes one:

```tla
(* --algorithm LostBit
variables byte = {};                  \* the set of bits that are 1
process T \in {1, 2}
variables tmp = {};
begin
  Load:
    if Plain then
        tmp := byte;                  \* uint8_t v = b;
      Store:
        byte := tmp \cup {self};      \* b = v | mask;
    else
        byte := byte \cup {self};     \* fetch_or(mask): one atomic step
    end if;
end process;
end algorithm; *)
```

From the toy model that the model-checking setup is tested with. The property is one line: once both threads are done, both bits are set.

```tla
BothBitsSet == (\A t \in {1, 2} : pc[t] = "Done") => byte = {1, 2}
```

With `fetch_or` the checker TLC visits every state and reports success. With the plain version it finds the schedule at once: both threads load the empty byte, thread 1 stores its bit, thread 2 stores *its* bit over the top, and bit 1 is gone. In a collector that is a live object left unmarked, which the sweep then frees.

The real marker does exactly what the model says it must. From the old generation's mark routine (trimmed):

```cpp
        std::atomic_ref<uint8_t> b(mark_.slot(id)[byte_index]);
        // Test before set: an already-marked object costs a plain load, not
        // a locked RMW on a line other markers may be writing.
        if (b.load(std::memory_order_relaxed) & mask) return true;
        return (b.fetch_or(mask, std::memory_order_relaxed) & mask) != 0;
```

The toy also shows the second half of the method. The plain variant is kept as a *mutant*, a deliberately broken configuration, and the registry records the exact failure it must produce: a violation of `BothBitsSet`. If a later change to the model made the mutant pass, the model would have lost the ability to see the bug, and the run fails.

## Eight models, one per protocol

A single model of the whole heap and every collector thread would have far too many states to explore. The collector is instead described by eight small models. They fit together through contracts: named guarantees that one model checks and another assumes, such as "a young object is copied at most once". When a model grows too slow to explore in a few minutes, it is split along a contract rather than given looser bounds.

| Model | Protocol |
|---|---|
| M1 | The snapshot mark cycle of the old generation |
| M2 | The marker loop: taking work, stealing it, agreeing that marking has finished |
| M3 | Forwarding in a minor collection: claim a young object, copy it, publish the copy's address |
| M4 | Promotion in chunks, and the mark bitmap at byte and word granularity |
| M5 | Concurrent tenuring of long-lived young objects, and ageing |
| M6 | The helper-thread pool: starting, grouping and stopping threads, across fork and exit |
| M7 | Returning memory to the operating system in the background, and lock order |
| M8 | The old generation's block lifecycle, for the hazard of an address being reused |

The mutator is a single process in every model, because the runtime allows one mutator per process.

Snapshot marking is the clearest example of what a model claims. The collector marks the old generation while the program runs, with no write barrier. That is safe because Elm values never change once built: everything live during a cycle was either reachable when the cycle started or allocated since. The M1 model states this as a property over sets that exist only in the model, recorded at the start of each cycle, and TLC checks it in every reachable state. A second, symbolic checker, Apalache, goes further and proves it inductive (if it holds before any step, it holds after), but only for heaps of up to five objects. For larger heaps the claim rests on the argument in the collector's design.

Accuracy rules keep a model from passing while the code fails. One model step is one atomic step of the code, so a load and the store that depends on it are two steps, exactly as in `LostBit`. Shared memory is modelled at the unit the hardware shares: mark bits live in bytes that cover eight objects, so a model with one independent bit per object could never see a lost update. And every property has a mutant that must break it.

## Holding a model to the code

A model is only worth what its link to the code is worth. Each model has a mapping that names, for every shared memory location and every atomic step in the C++, the model variable or step that stands for it. Three further ties check that the mapping holds.

**Weak memory.** TLC assumes every thread sees all writes in one global order, but the code uses relaxed and acquire-release atomics, which allow more behaviours. GenMC, a model checker for C and C++, runs small drivers built from the real allocator headers under the C11 memory model, each with mutants that weaken one memory order ([How we know it works](/docs/verification) has more on it).

**Traces from real runs.** A model can pass while describing a different program, for instance if a loop in the model cannot stop where the code's loop can. Special builds of the allocator log events from every thread, and TLC is asked whether some behaviour of the model matches the whole log. A rejected log is a finding: real logs once showed that a loop in the snapshot model could not stop where the code's could.

**The canary.** A model that passes says nothing once the code it describes has changed, so a hash check, taking about a second, runs in every build. A manifest pins the code each model covers, and each pin names the models that must be reread if its hash changes:

```text
#   <kind>  <sha256>  <path or ->  <id or ->  <models, comma-separated>
#
# kinds: file (a whole file), region (the code between // TLA-REGION(<id>) begin and end,
# comments stripped, whitespace collapsed), census (a file's concurrency lines), grep (a
# footprint row of footprint-greps.txt), nocode (a model with no code to pin).
```

From the head of the canary manifest. The mark routine above is one such region, pinned for M1, M4 and a GenMC driver. Pins are narrow on purpose. Hashing a whole allocator file of several thousand lines would fire on every edit and teach people to accept changes without looking, while a census pin still catches a new atomic or lock added anywhere in a covered file. The checker also checks coverage: every region marker in the source must be pinned, and every allocator file with a concurrency line must have a census pin.

Accepting a changed hash is a separate, audited step. The update command refuses until the audit log of every model the pin names quotes the new hash's first twelve hex digits. The verdict, even "no model change needed", is written down before the code is accepted. By default a firing canary prints a warning banner and the build continues; a build setting turns it into a build failure.

## What the models found

Every defect found by any tool, from code reading to a TLC counterexample or a ThreadSanitizer report, goes into one defect register, with a guard that replays it. At the time of writing the register holds 39 entries. Ten were classed as unsound, meaning a live object freed, lost or corrupted; three of those turned out to be ordinary serial bugs found while doing the concurrency work. Every entry is now fixed except one won't-fix: races that need a second mutator in the same process, which the runtime now refuses to start outside test harnesses. Three stories give the flavour.

- **Address reuse after a full collection.** A full collection freed a large young object, and a new object was later allocated at the same address. The next minor collection checked membership by address alone, took the new object for the old one, and left its pointers unhealed, so a live object ended up pointing into a recycled part of the nursery. The fix stamps each entry with the collection that recorded it. The tenuring model reproduces the bug three ways, and the pre-fix behaviour is kept as mutants.
- **A sweep that finished in the wrong place.** The lazy sweep could complete on a second code path that skipped the check for "a parallel minor collection is running", and so shrink the old generation while other threads were still promoting into it. We found it by reading the code while writing the promotion model; TLC then produced a 25-state counterexample.
- **A snapshot that reached freed memory.** An adversarial review of the snapshot model's plan suspected that the start-of-cycle walk over young objects could follow a dead object into a cell a full collection had already freed. TLC confirmed it with a 17-state counterexample.

## The numbers

At the time of writing: 8 collector models with 374 registered checks, of which 180 must fail by violating a named property (mostly mutants), 79 are in the slow "deep" tier and 18 are run by Apalache; and a canary manifest of 237 pins. The quick tier of a model is meant to finish in about two minutes so developers run it while working. None of the model checks run in continuous integration: the deep runs take hours, and we run them by hand when a model or its code changes, with the canary in every build saying when that is.

The models are evidence about the design and its mapping to the code, not a proof of the C++. They check small heaps, the one inductive proof stops at five objects, and anything a mapping abstracts is argued in the mapping rather than checked. Collector policy (when to collect, how fast to mark) is measured, not modelled.

> **Designs we didn't use.** We considered one large model of the whole collector, but it has far too many states to explore. Small models, each of one protocol and checked against the code it describes, are what TLC can finish.

## Further reading

- [The garbage collector](/docs/garbage-collector) — the collector these models describe, and why immutability lets it run without a write barrier.
- [How we know it works](/docs/verification) — the other test layers, including ThreadSanitizer and GenMC on the real allocator.
- [The runtime](/docs/runtime) — the threads that share the heap.
- The full design document: [Concurrency models theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/verification/concurrency-models.md)
- Source: [`test/tla`](https://github.com/eco-lang/eco-compiler/tree/master/test/tla) and [`runtime/src/allocator`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/allocator)
