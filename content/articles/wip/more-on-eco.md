---
title: "More on eco"
description: "How I make AI do the work in eco, so I don’t have to."
section: "AI & Engineering"
sectionOrder: 1
order: 3
---
## Making AI work for me

In *The Master and His Emissary*, Iain McGilchrist argues that we get into trouble when the “emissary” (the narrow, efficient, instrumental side of the mind) forgets it serves a “master” that holds the wider, contextual picture.
He builds this on brain asymmetry:
- The **left hemisphere** is more tool-oriented and analytic. It’s tightly linked to **speech and symbolic manipulation**. It narrows in on details and turns the world into things you can grab, name, and operate on.
- The **right hemisphere** is more holistic and contextual. It’s better at **long-range attention**, relational understanding, and staying broadly alert to the world rather than to a single tool.

Roughly speaking, the left is driven by **dopamine**-style reward loops: get a hit from solving a little problem, chase the next one. Humans burn out when they sit in that narrow, tool-using mode for too long; each hit “works” less. The right hemisphere leans more on **adrenaline-like vigilance**: it can stay watchful and oriented to the big picture for longer without the same kind of depletion, but it’s not optimized for grinding through repetitive, mechanical tasks.

LLMs are very much **left-hemisphere-like tools**:

- They live in language.
- They manipulate symbols and local patterns.
- They are relentless at narrow, procedural work.

They are the emissary, not the master.

So my basic strategy for eco is:
> Treat LLMs as an **outsourced left hemisphere**.  
> Give them the narrow, dopamine-heavy work that would otherwise tire me out,  
> and keep my own “right-hemisphere” resources free for long-range thinking and judgment.

The rest of this essay is simply how that plays out in practice, with two different emissaries:
- **ChatGPT + RAG (OpenAI Responses API)**: my research and design department.
- **Claude Code (with serena)**: my implementation and debugging team.

I stay in the “master” role: holding the theory of the compiler, deciding which invariants matter, and choosing between designs. The AIs do the work I no longer want to spend my finite energy on.

## Outsourcing left-hemisphere work

Once you look at AI through the hemispheres metaphor, there’s an obvious question:
> What parts of compiler work feel like **left-hemisphere toil** that I can hand to a machine?

For eco, that includes:
- **Symbolic search and cross-referencing**
  - “Where else is this invariant referenced?”
  - “Which passes rely on `eco.value` being laid out this way?”
  - “What did I decide about GC safepoints and stack maps in that old design note?”

- **Mechanical synchronization between artefacts**
  - Keeping pass implementations, theory docs, and tests in sync.
  - Propagating a renamed concept across code, docs, and invariants.
  - Aligning comments and invariants with what the code actually does.

- **Forensic debugging**
  - Tracing a failing Elm program through the entire pipeline.
  - Checking ABI consistency, heap layouts, and IR transformations step by step.
  - Assembling all that into a coherent, evidence-backed bug report.

These are all narrow, tool-heavy tasks that:

- are **perfect for a language-based emissary** (an LLM);
- but are **energetically expensive** if I try to do them myself all day.

Conversely, I keep for myself the work that looks more like right-hemisphere “master” activity:

- Deciding which invariants are non-negotiable.
- Choosing between alternative pipeline designs.
- Weighing simplicity vs performance vs future evolution.
- Seeing when a pattern of failures hints at a deeper design mistake.

With that split in mind, I’ve shaped two AI roles:

- ChatGPT + RAG: handles the **high-context text and theory work**.
- Claude Code: handles the **concrete code and debugging work**.

## ChatGPT + RAG: my research and design department

Only **ChatGPT** talks to the RAG system I’ve built on top of the OpenAI Responses API. That system indexes:
- the current eco codebase;
- theory and design docs;
- external material: papers, books, and notes on compiler theory, MLIR, GC, invariants.

I use it for **understanding and design**, not for churning out code.
### Work that RAG + ChatGPT takes off my plate

Here’s the kind of left-brain-style work I’ve largely offloaded:
1. **Re-reading and stitching together context**

   Instead of manually:

   - grepping,
   - opening five files,
   - reconstructing the relationship between a pass, its invariants, and its tests,

   I ask questions like:

   - “How does monomorphization represent record layouts, and how does that connect to `eco.construct`/`eco.project` in the eco dialect?”
   - “Where is invariant CGEN_xxx enforced, and what are the consequences if we break it?”

   ChatGPT, via RAG, pulls the relevant code, theories, and notes together and gives me a synthesized answer.

2. **Remembering why I made a decision**

   Instead of personally re-deriving the rationale for an old choice:

   - “Why did we choose this closure ABI rather than that one?”
   - “Why does EcoToLLVM pass order look like this?”

   I let ChatGPT read the original design docs plus the current code and reconstruct the argument, flagging any drift between them.

3. **Exploring the design space against the literature**

   Because RAG includes both my own docs and external texts, I can ask:

   - “Compare eco’s staging to the treatment in these chapters/papers; what failure modes should I expect?”
   - “Given these invariants and this research, what alternative pass structures would be more robust?”

Again: this is all text- and pattern-heavy “emissary” work. My job is to:

- decide which of the proposed designs fits eco’s goals;
- update the invariants and theory accordingly.

The chosen designs then become input for Claude Code to implement.

## Claude Code: my implementation and debugging team

**Claude Code** doesn’t talk to the RAG system. It works locally through its own tools (I use serena) on:
- the codebase,
- the tests,
- local call graphs and IR dumps.

Its job is narrower but deeper in the concrete: **turn designs into code and tests, and then debug them**.
### Work that Claude Code does so I don’t have to

1. **From design to implementation**

   Given a clear spec (written by me, or co-developed with ChatGPT), Claude:

   - implements passes and helpers;
   - wires them into existing pipelines;
   - respects existing invariants and naming conventions.

   I review and adjust, but the initial coding and plumbing is usually AI-authored.
2. **Tests and harness maintenance**

   Once the invariant and test framework is in place, Claude:

   - writes new tests for newly introduced invariants or passes;
   - extends coverage when we add features;
   - updates tests to track refactors in the compiler.

   All the duplicative “copy this pattern across N tests and tweak the constants” work moves off my desk.

3. **Evidence-driven debugging**

   This is where Claude really saves my energy.

   For a failing case, I ask it to:

   - walk a specific Elm program through:
     - typed IR,
     - monomorphized graph,
     - eco MLIR,
     - MLIR → LLVM,
     - final LLVM / runtime behavior;
   - collect **concrete evidence**:
     - IR before/after key passes;
     - function signatures and ABIs;
     - heap layouts and tags;
   - and then write a structured bug report, for example:
     > “In `KernelAbiConsistencyTest`, calls to `Foo.bar` use `(i64, !eco.value)` here and `(!eco.value, !eco.value)` there; this violates invariant CGEN_038.”

   I no longer pay the mental (and dopaminergic) cost of stepping through IR dumps by hand. I read the report, validate the reasoning, and decide what it *means* for the design.
4. **Proposing concrete fixes**

   Once the evidence is in place, I let Claude propose fixes:

   - local code changes to restore an invariant;
   - adjusted pass ordering if the pipeline makes guarantees too late;
   - extra tests to lock in the discovered edge case.

   I still choose whether to accept a fix, and whether the bug hints at a larger design issue. If it does, I take the evidence back to ChatGPT + RAG for a theory/design conversation.

## Debugging as an emissary pipeline

Seen as a full loop, this is how the “emissaries” handle debugging:
1. **Failure happens.**
   - A test fails or an invariant fires.

2. **Claude Code does the forensic work.**
   - Traces the concrete program through each compiler phase.
   - Writes an evidence-rich report: IR snippets, ABI details, layout diagrams.

3. **I decide the level of response.**
   - If it’s obviously an implementation bug, Claude’s suggested patch (reviewed by me) is usually enough.
   - If the pattern matches deeper design smells, I escalate.

4. **ChatGPT + RAG re-examines theory and architecture.**
   - Using the bug report, theory docs, and references, we ask:
     - Is the invariant wrong or incomplete?
     - Is this pass in the wrong place?
     - Do we need a new intermediate representation or invariant?

5. **New decisions flow back to code.**
   - We update the theory docs and design notes.
   - Claude updates passes and tests to match.

Most of the narrow, tool-heavy work is done by AI; my energy goes into picking interpretations and making structural calls.

## Program theories as an automated side-effect

eco has a Naur-style “program theory” layer: for each major pass or subsystem, a document explaining:
- intent and high-level model;
- assumptions and invariants;
- how it interacts with other passes and with the runtime.

Without AI, this is exactly the kind of thing that decays: now you have two changing artefacts (code + docs) and no spare energy to keep them in sync.
### ChatGPT: drafting and evolving the theories

With RAG, I use ChatGPT to:
- read the current implementation of a pass;
- read any existing theory/spec;
- read related design notes and references;
- then either:
  - draft a fresh theory doc; or
  - propose a targeted update.

The toil I avoid:

- manually hunting for every place a concept was renamed;
- re-reading entire passes just to rewrite one section;
- composing long explanations from scratch for new contributors.

Instead, theory maintenance becomes:

- “Generate/update the theory for this pass.”
- “Show me a diff vs the previous version.”
- “Highlight any inconsistencies between doc and code.”

I spend my energy on checking for correctness and coherence, not on mechanical summarization.
### Claude Code: embedding theories in code and tests

Claude doesn’t read those docs, but it enforces them indirectly:
- When a theory says: “After pass X, all `eco.case` ops must satisfy invariants A, B, C,” I ask Claude to:
  - implement or strengthen validation passes;
  - write tests that mirror the theory’s edge cases;
  - refactor the pass so those invariants are structurally evident rather than implicit.

This way:

- ChatGPT + RAG keeps the **articulated theory** in sync with code and literature.
- Claude keeps the **implementation and tests** in sync with the articulated theory.

Again, the left-hemisphere work of repetitive synchronization is offloaded.

## Keeping the master in charge

McGilchrist’s warning is that we get into trouble when the emissary (specialized, language-driven, tool-using) forgets that it serves a master with a wider view.
In eco’s AI setup:
- The **emissaries** are:
  - ChatGPT + RAG, doing high-context reading, synthesis, and design exploration.
  - Claude Code, doing implementation, testing, and forensic debugging.

- The **master** is:
  - my long-range, “right-hemisphere” understanding of eco’s purpose, constraints, and taste;
  - the theory of the compiler as a whole, not any single tool or metric.

LLMs extend my left-brain-like capacities: they’re always ready to chase another local reward: another bug fixed, another test written, another paragraph updated. That’s exactly why I give them that work:

- It saves my own dopamine system from grinding itself down on narrow tasks.
- It frees more of my right-hemisphere energy for:
  - seeing patterns across bugs,
  - rethinking architectures,
  - and deciding which invariants and design values matter in the long run.

The result isn’t “AI building eco on its own.” It’s a framework in which AI does the bulk of the **work** that would otherwise erode my attention and energy, while I stay responsible for the parts that can’t be automated: purpose, judgment, and the shape of the whole.
