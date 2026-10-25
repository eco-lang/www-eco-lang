# Eco docs voice

The house style for `content/docs/`. An engineer explaining their own design to a capable peer, edited for
publication. It carries some of the author's forum habits (open with the problem, define the terms, give an
opinion and its reason, be candid about gaps, show the API) with the discipline of published documentation.

## Stance

- **Collective "we".** Speak for the project. Never "I". Never step outside the article to address the reader
  about the author (no "a note from the author", no sign-offs).
- **Opinions, with reasons.** Take positions openly ("we think…", "in our view…"). Every judgement is followed by
  its reason in the same or the next sentence. A judgement without a reason is not stated.
- **Candid about limits.** Say plainly what is not built, not known, or what a choice costs. Once, then move on.
- **Outcomes, not chronicles.** Describe how things are, why, and what constraint remains. The past appears only
  as a lesson ("more than once an optimisation has pushed this stage to that edge"), never as a dated sequence of
  events. No exact dates. Counts are "at the time of writing".

## Structure

- **Lead with substance.** A paragraph opens with the claim or the problem. No warm-up ("In this article…",
  "It is worth noting…").
- **At most one question per section**, used as a way in: the question opens the section and the next sentences
  answer it. Never rhetorical decoration.
- **Paired definitions** to separate two ideas readers merge: "*Concurrency* is…; *parallelism* is…".
- **Paragraphs move fact → consequence → what we do about it.**
- **Future-work sections may close on an open question** naming the real unresolved trade-off. Only there.

## Evidence and grounding

- **Code as argument.** A short Elm signature, MLIR excerpt or type, introduced plainly, followed by what it means.
- **Grounding in engineering practice.** Place a design against how others solve the problem (actor model,
  low-latency trading systems, copying collectors, LLVM, GHC, OCaml…) where that clarifies the choice.
- **Numbers.** Figures from the shipped benchmark suite (`examples/benchmarks/`) are exact. Figures from the
  compiler compiling itself are rounded ("roughly half", "under 100 ms", "about fifty times smaller").

## Sentences

- Plain, complete, medium length, one idea each. No comma splices, no "So… So…" chains, no filler, no
  intensifiers ("very", "really", "extremely", "incredibly"), no marketing ("powerful", "seamless", "blazing").
- Technical terms precise, defined once (in the Background box or at first use). Italics for a term being defined
  or the one word that carries the point.
- Dry understatement at most once per page. Never a joke, never self-deprecating.
- British spelling (optimisation, behaviour, recognise; but keep code identifiers and quoted names as they are).
  Standard punctuation, no emoji, no `===` dividers, no space before `?`.

## Article furniture (keep)

- Frontmatter unchanged except `description` may be reworded.
- Opening paragraph ≤ 100 words, then the `> **Background**` box of glossary links.
- "Designs we didn't use" callout: at most one alternative, two or three sentences, with its reason.
- `## Further reading` with the theory doc and source links at the end.
- All examples, diagrams, tables, `/docs/` links and glossary anchors stay; facts are not invented.

## Reference passages

### Opening a section with a question, ending on a firm outcome

> ## Stage 5: staying inside Node's heap
>
> Where does the first MLIR come from? Every part of Eco that emits it is Elm source, so the first MLIR the
> compiler ever produces has to come from the compiler running as JavaScript under Node. That self-compile is the
> heaviest step of the Node half of the chain, and it runs close to the largest heap V8 allows, 16 GB.
>
> Running out of heap does not crash the compile. As it nears the limit, V8 spends more and more of its time
> collecting garbage, and the compile slows until it never finishes. A build that looks hung is harder to
> diagnose than one that fails, and more than once an optimisation that improved the native compiler has pushed
> this stage to that edge.
>
> We keep it inside the limit in two ways. Stage 5 uses the lighter of the two specialization engines, because
> its only job is to produce a *correct* first native compiler, and nothing that ships is built from its output.
> And any new optimisation has to leave this stage under 16 GB, even if that means switching the optimisation off
> here. It is a real constraint, but we think bootstrapping from stock Elm is worth keeping: it means anyone can
> rebuild Eco from source with nothing but Elm and Node.

### Paired definitions, an honest view of the future

> ## Where threads could go
>
> Two ideas are easy to confuse here. *Concurrency* is a program doing several things that wait on the world,
> such as timers, sockets and child processes. *Parallelism* is Elm code running on several cores at once. Eco
> has the first today, through the scheduler and its service threads. It does not yet have the second.
>
> One heap shared by several mutators is the route we rejected. … In our view the right shape is a heap per
> thread, with immutable messages as the only thing that crosses between them.
>
> This is a sketch, not an API we are building. The open question is what a message costs.

### An opinion with its reason, one understated line

> An optimisation can only use what is known at the point it runs. … Each of Eco's optimisations therefore runs
> at the earliest stage that has the fact it needs, and this page lists them in that order.
>
> One principle runs through all of them: we judge an optimisation by the work it removes, not by how clever it
> is. A copying collector makes short-lived objects almost free, so an optimisation that saves allocations can
> still change nothing in run time. That lesson took a few experiments to learn.
