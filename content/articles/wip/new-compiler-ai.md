---
title: "Building a New Compiler with AI"
description: "How invariant-driven development enables real engineering leverage from AI coding agents."
section: "AI & Engineering"
sectionOrder: 1
order: 4
---

Anthropic's autonomous C compiler project is genuinely impressive: a swarm of Claude agents, running unattended, grinding out a 100k-line compiler that can build the Linux kernel. But as striking as that is, it leaves open a hard question: are we seeing true new engineering, or a very sophisticated remix of GCC's design, which their models have almost certainly seen during training?

In contrast, the eco project I have been working on is a *genuinely new* native compiler for Elm, with a heap model, garbage collector, MLIR dialect, and optimization pipeline that did not exist before. I built eco almost entirely with AI coding agents (Claude Code and others), and I had to invent new techniques (most notably **invariant-driven development via machine-readable CSV specs**) to keep those agents on track. The result is not just a working compiler; it is a demonstration of how to get *real* engineering leverage out of AI agents on problems that have no existing implementation to copy.

The point of this article is not to give a full tour of eco, but to make a narrower argument:
> On genuinely new designs, autonomous agents only work if you give them a human architecture, plus explicit, universal invariants that shrink the search space to “structurally correct” implementations. Tests alone are not enough.

Anthropic’s compiler shows how far a strong model plus a light harness can go on a well-trodden problem. eco is about what you have to add when there’s nothing to imitate.

---

## Why eco is a stricter test than “yet another C compiler”

The Anthropic experiment asks: “What happens if we set 16 agents loose on a hard but well-trodden problem and mostly walk away?” Their C compiler targets an existing language with decades of prior art, standard test suites, and widely known implementation patterns.

eco is different by design:

- It is a **native compiler for Elm**, targeting MLIR and LLVM rather than JavaScript.
- It introduces **new optimization passes and representations** tailored to Elm’s semantics: a type-preserving optimization pipeline, monomorphization over a global typed IR, and a custom ECO MLIR dialect with its own operations and lowering pipeline.
- It is backed by a **new runtime and garbage collector** tuned for Elm's immutable, message-passing style, including a thread-local generational heap and precise object layout rules.

None of these ideas are novel in the abstract: monomorphization, tracing GC, MLIR, SSA IR, and aggressive unboxing are all well-known techniques. What *is* novel is applying them coherently to Elm, integrating them into a single design, and making the whole thing testable and debuggable enough that AI agents can work effectively inside it.

That matters, because it is a much harsher benchmark for AI: there is no GCC-for-Elm to imitate.

## Human guidance, AI leverage

Across the eco project, AI has been a **genuine 10x multiplier** on my throughput:

- It drafted large Elm passes (monomorphization, MLIR codegen scaffolding) that I then steered and constrained.
- It handled repetitive but error-prone refactors (propagating type information, wiring new MLIR ops across passes).
- It acted as a tireless debugger and documentation writer.

But, and this is important, it did **not** replace human understanding. eco is precisely the kind of project where leaving a swarm of agents to run unattended would have failed:

- There was no existing Elm-to-native compiler for them to imitate.
- Subtle ABI and GC invariants had to be designed *before* implementation.
- The shape of the heap, IRs, and passes needed a coherent, end-to-end vision.

My contribution was to supply that vision, encode it as invariants and program theories, and then build a harness where AI agents could operate safely and productively inside those boundaries.

## Where naive agents failed

My first experiments with Claude Code (and other models) were very similar to what Anthropic describes: put the model in a tight loop, point it at failing tests, and let it iterate.

On eco, that approach hit its limits quickly:

- The codebase is multi-language (Elm + C++ + MLIR/LLVM), multi-phase, and highly constrained.
- The agents frequently **“hacked” the code to placate tests**-dropping invariants, weakening types, or introducing subtle ABI mismatches between phases.
- They struggled to reconnect all the cross-phase guarantees, like type preservation from Elm's canonical types through typed optimization, monomorphization, and down into MLIR types and LLVM IR.

In other words, tests alone were not enough. The search space of "code that passes the current tests but is structurally wrong" was just too large.

That is what pushed me toward a more structured idea: **invariants as first-class artefacts for AI.**

## Invariants as the missing interface between humans, tests, and AI

The turning point on eco was treating invariants as *data*, not prose.

I ended up thinking about invariants along two axes:

- **Scope**: from very local (“this IR op is always terminated correctly”) up to **universal** invariants that are intended to hold for *every* program, *throughout* the pipeline. Those universal ones are the real gems: they encode what it means for the whole system to be “well‑formed.”
- **Time / phase**: some invariants are enforced and consumed entirely within one phase; the most useful ones are **cross‑phase**-established by one phase, and then quietly assumed by all the later ones.

For example, after type checking, there simply is no such thing as a mistyped program. That’s not just a local guarantee; it’s a promise to every subsequent pass that they never need to handle ill‑typed inputs. The same pattern shows up all over eco: one phase proves a property once, and all the others lean on it.

To make those properties usable by both humans and AI agents, I built a CSV‑based invariant catalogue. Each row is a *predicate* we want to be true, with fields like:

- `id` / `description`: human label for the invariant (corresponding tests labelled with id).
- `phase`: where it’s established or primarily enforced.
- `category`: which subsystem it constrains (types, heap, bytes fusion, etc.).
- `logic` (implicitly): a binary condition, either the invariant holds, or it doesn’t.
- `checks`: how we approximate it in practice (IR scanners, tests, runtime asserts).

Some of the most valuable entries in that catalogue are explicitly **universal and cross‑phase**. For example:

- **REP_001: Four representation models stay distinct**  
  The compiler works with four different “views” of a value: Elm’s *logical* type, the *ABI* representation at call boundaries, the *SSA* type in MLIR, and the *heap* layout at runtime. REP_001 says that each of these is its own model, and *rules in one do not imply rules in another unless we’ve written down an explicit bridge*. That sounds abstract, but it’s what keeps an AI agent from “optimizing” by assuming that an `i64` in SSA must be unboxed in the heap, or that ABI details leak into Elm semantics.

- **NITPICK_001: All `case` expressions are exhaustive after Nitpick**  
  Nitpick’s job is to prove that every `case` covers all possible values of its scrutinee type, or report a compile‑time error. NITPICK_001 says: *after this phase, there is no runtime notion of “no matching branch.”* Subsequent phases never generate default arms “just in case”; they assume exhaustiveness as a global truth. That’s a textbook cross‑phase invariant: one phase invests the effort to prove it, and every later phase gets to rely on it for free.

- **XPHASE_002: Every `!eco.value` is a valid heap object or constant**  
  Codegen produces an SSA type `!eco.value` for Elm values. XPHASE_002 states that every such operand corresponds to a well‑formed `HPointer`: either a legitimate heap object that satisfies all alignment/header invariants, or one of a small set of embedded constants. This connects the *type system* and codegen to the *GC and heap model*. It’s universal in intent (it should hold for all programs, at all safe points) and very much binary: if a single `!eco.value` is malformed, GC correctness goes out the window.

- **BFOPS_005: The Bytes cursor never outruns the buffer**  
  In the fused Bytes IR, encoding and decoding are expressed as operations over a `cursor` with two pointers: `ptr` and `end`. BFOPS_005 is the simple but powerful predicate `ptr ≤ end` at all times. Combined with the surrounding fusion invariants, it means that every read/write in a fused kernel is structurally dominated by a bounds check. It’s a local invariant (only about the Bytes fusion subsystem), but it has global semantic bite: *fused encoders/decoders cannot walk past the end of their buffers.*

These invariants are represented in CSV, but they’re really **theory‑level statements** about the system. The catalogue turns them into something AI agents can consume, extend, and check mechanically, while still being readable to humans.

### What makes a good invariant?

Through trial and error on eco, especially with AI agents in the loop, a pattern emerged for “good” invariants:

- **Universal when you can afford it**  
  The best invariants are global in scope: they aim to hold for the whole program, over the whole compiler/runtime pipeline (REP_001, XPHASE_002). They’re harder to discover and formulate, but once you have them, they simplify *everything* downstream.

- **Cross‑phase by design**  
  Even when an invariant is established in a specific phase (Nitpick, monomorphization, Bytes fusion), the really valuable ones carry their truth forward into later phases (NITPICK_001, BFOPS_005). One pass proves it; everybody else can assume it.

- **Binary predicates**  
  Good invariants are predicates, not fuzzy heuristics. “Either every `case` is exhaustive, or there exists a counterexample.” “Either `ptr ≤ end` along every path, or there’s a bug.” This makes them trivial to wire into automated checks and easy for agents to reason about: they’re simply *true or violated*.

- **Future‑proof**  
  A good invariant talks about behaviours you want to protect, not incidental details. eco’s representation invariant (REP_001) doesn’t care *which* unboxing scheme we use; it cares that ABI, SSA, heap, and Elm semantics don’t silently collapse into each other. We can swap out layout strategies without invalidating the invariant.

- **Higher‑level, but grounded**  
  They’re phrased at the level of types, semantics, and abstract machine properties, but still close enough to the implementation that we can test them. “Every `!eco.value` is a valid `HPointer`” (XPHASE_002) is a semantic claim about well‑formedness, but it’s checked by concrete scans of IR and heap snapshots. “`ptr ≤ end`” (BFOPS_005) is a simple inequality, but enforced by IR structure and control‑flow dominance.

Once you write invariants down this way-as explicit, machine‑readable, mostly universal predicates-they become the shared contract between:

- the human designer,
- the test harness,
- and the AI agents proposing changes.

Tests say “*this program still runs*”; invariants say “*this program still has the shape and semantics we designed*.”

## Designing the core heap model by hand

All of this only works if the underlying “physics” of the system is sound. For eco, that meant designing the **heap model and runtime layout entirely by hand** *before* turning agents loose.

The heap model ties together:

- Compiler IR and calling conventions
- Runtime representation of values (`eco.value`, tagged pointers, unboxed primitives)
- Garbage collector behavior (nursery, old gen, compaction)
- Kernel implementations and FFI boundary
- The high-level language semantics (immutability, message passing)

I made explicit choices like:

- Per-thread heaps with a nursery plus old generation.
- “No old-to-young pointers” (leveraging Elm’s immutability).
- 8-byte alignment and a uniform header-first layout for all objects.
- A tagged-pointer `eco.value` encoding where certain well-known constants (Unit, True, False, Nil, etc.) are never heap-allocated.

Those decisions are what sit behind invariants like XPHASE_002: when the CSV says “every `!eco.value` is a valid heap object or constant,” that’s grounded in a concrete value encoding and heap layout that I shaped up front.

If you try to let agents “discover” a heap model by trial and error, you end up with brittle, hard-to-optimize layouts that are extremely expensive to change later. By designing the core model first and then encoding its properties as invariants, I gave the agents a stable “physics engine” to live in.

## Tests + invariants as ratchets

With a rich invariant set in place, tests and invariants together became **ratchets** on the search space of possible implementations.

The development loop looked roughly like:

1. Start with broad tests (end-to-end JIT pipeline, simple Elm programs) and a small invariant set.
2. Let the agent propose implementations or refactors.
3. Watch how and where it fails-especially in subtle cross-phase ways (type preservation, ABI consistency, heap invariants).
4. For each new failure mode, introduce:
   - One or more *targeted* invariants (often universal or cross-phase).
   - Corresponding tests (small synthetic Elm programs or IR snippets).
5. Re-run the agent under this tightened harness.

Each iteration **shrinks** the space of admissible code. Eventually, the only implementations that satisfy all invariants and tests are *genuinely correct in structure*, not just coincidentally green on a narrow test set.

This is a very different philosophy from “let the agents run for 2,000 sessions and hope they converge.” Instead, I continually raised the floor of what “acceptable” code even means. Agents became less like autonomous explorers and more like very fast junior engineers working inside an increasingly strict specification.

In practice, that meant they were excellent at:

- Propagating new invariants through the codebase (updating all uses of `eco.value` to respect a representation rule).
- Acting as **evidence-driven debuggers**: tracing a failing case across phases, matching it to a specific invariant violation, and proposing concrete, localized fixes.

But the shape of the search space (and, ultimately, the architecture of eco) remained under human control.

## What this says about autonomous software development

Anthropic's compiler experiment shows that large, well-trained models supervised by a light harness can now take on very ambitious engineering tasks by themselves-*when there’s a lot of prior art to imitate*.

eco shows a complementary picture:

- If you are tackling **truly new designs**, you still need human architecture, but you can push a huge amount of the *labor*-implementation, refactoring, tracing, documentation-onto AI.
- **Invariants and tests as explicit, machine-readable artefacts** are the key to scaling that collaboration. They give humans, tests, and agents a shared set of rules to converge on.
- Once you treat invariants as first-class data, you can progressively ratchet up the constraints until “anything that passes all of this is not just working today; it’s structurally correct by design.”

For teams looking to get serious value out of AI coding agents, my experience with eco suggests the right question is no longer “Can an agent build a compiler?” but:

> “Can we design our systems, invariants, and documentation so that agents and humans can *reliably* work together on problems where no reference implementation exists?”

That is the space eco lives in, and it is where I think the most interesting software engineering with AI will happen next.
