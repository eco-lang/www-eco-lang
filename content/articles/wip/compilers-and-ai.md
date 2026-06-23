---
title: "AI Will Not Kill Code"
description: "Why I believe it is worth writing a new compiler in the age of AI."
section: "Compilers"
sectionOrder: 1
order: 2
image: /images/kill-code.png
---

**The claim that programming will vanish**

A current narrative says that large language models will soon replace code, and with it the need for 
programmers, programming languages, and compilers. Give the machine a prompt in plain English, and it will 
conjure working software. In this telling, the entire edifice of traditional tooling becomes an historical 
curiosity. This story may be compelling, but it is wrong.

The strong claim that circulates in many discussions is that programming will be obsolete. This statement 
often conflates several different ideas. One idea is that many people who currently write code by hand will 
instead instruct systems in natural language. Another is that the demand for traditional software engineering 
effort will decrease. A third is that code itself, as a medium for describing computation, will vanish.

The first claim is plausible. The second is possible, although history suggests that increased productivity 
in software usually leads to more ambitious software, not less work. The third claim, however, is far less 
credible.

To ask whether it is worth writing a new compiler in 2026 is really to ask whether there will still be value 
in defining precise languages, making programs efficient, and enforcing correctness properties, even if much 
of the source text is suggested or written by artificial intelligence systems. Once the question is framed in 
those terms, the answer becomes clearer.

**The physics of intelligence and computation**

There is a more fundamental problem with the idea that artificial intelligence will make code obsolete. 
Modern language models are extraordinarily inefficient computers. Rough estimates suggest that a silicon 
based system with computational capacity similar to a human brain would require on the order of ten megawatts 
of power, while a human brain runs on roughly ten watts. Today’s models already demand substantial energy 
and memory bandwidth to perform relatively simple tasks, and they still struggle with consistency, 
predictability, and guarantees.

By contrast, a smartphone, drawing only a few watts at full utilisation, executes billions of arithmetic and 
logical operations per second with deterministic precision. Those low level operations are the building 
blocks from which all conventional software is constructed. They are what compilers target and optimise.

A carefully optimised algorithm implemented in machine code can perform extremely large numbers of arithmetic 
and logical operations per unit of energy. It is already clear that even if artificial intelligence systems 
design many aspects of software, they will not replace the underlying need for efficient execution. Rather, 
they will sit at a higher level, developing designs and implementations that still need to be compiled into 
effective machine level programs. That higher level still rests on a substrate of explicit code.

**Code as the bridge between intent and hardware**

When a programmer writes and compiles a piece of code, a chain of tools preserves structure and meaning. 
Parsers turn text into syntax trees. Type checkers enforce constraints. Optimisers apply transformations that 
are known to preserve behaviour. Code generators emit instructions that are intended to have exactly the 
effects described by the source program.

When an artificial intelligence model emits code, it has no such built in guarantees. It can produce 
fragments that are locally plausible but globally inconsistent, that appear to follow an interface but 
violate subtle invariants, or that fail under rare boundary conditions that were absent from the training 
data. For tasks such as exploration, prototyping, and learning, this may be acceptable. For systems that must 
be safe, reliable, and efficient, it is not.

Code is the medium that bridges abstract intent and physical hardware. There may be less hand written code in 
the future, and more generated code, but the structural role of code remains. Compilers are the mechanisms 
that turn that code into efficient executables, and their importance only grows as hardware and software 
stacks become more complex.

**Correctness, safety, and guarantees**

Large language models are, at their core, probabilistic text generators. They do not know what a program 
means in a formal sense. They extrapolate from patterns in their training data. That is useful for sketching 
solutions, exploring interfaces, and filling in repetitive structures, but it is a poor foundation for 
guarantees. If a system must not crash, corrupt data, or lose money, plausibility is not enough.

Future artificial intelligence systems may be far more efficient than today’s models. They may run on 
neuromorphic hardware, energy based devices, or quantum substrates, bringing the energy cost of large 
probabilistic models down to or below that of a human brain. None of this alters their basic nature. However 
they are implemented, such systems remain probabilistic processes: they generate outputs that are likely 
given their inputs and training, not outputs that are guaranteed to satisfy a precise specification.

Even if all human written code were replaced by artificial intelligence generated code, a deterministic, 
semantics preserving compilation pipeline would still be necessary. Compilers would remain the trusted 
machinery that turns high level descriptions, whoever has written them, into behaviour that can safely 
underpin businesses, infrastructure, and safety critical devices.

**How programming might change**

The day to day activity of many programmers are changing in the present. Instead of hand writing every 
loop and data structure, they may spend more time stating goals, constraints, and examples in a mixture 
of natural language and high level code. Large language models and other synthesis tools will propose 
designs and implementations, adapt existing systems to new requirements, and perform much of the routine
editing that humans do today.

Beneath that more conversational surface, very little changes about what the machine must ultimately do. High 
level intentions still have to be grounded in precise semantics. Optimisations still have to respect 
invariants. Hardware still has to be driven with the correct instructions in the correct order, taking into 
account caches, pipelines, parallelism, and failures. That remains the world of intermediate representations, 
type systems, optimisation passes, and code generators.

In such a future, programming shifts emphasis rather than disappearing. More effort goes into specifying 
properties, choosing architectures, and validating behaviour, and less into hand crafting every instruction. 
But the infrastructure that checks, transforms, and lowers those specifications into efficient executables 
remains central. The compiler becomes the main point of contact between messy human and artificial intent on 
one side and the unforgiving physics of hardware on the other.

**Elm as an example of strong semantics and guarantees**

Elm offers a concrete example of what it looks like when a language and compiler are explicitly designed 
around semantic guarantees. One of the stated goals of the Elm package ecosystem is that it be written 
entirely in Elm, so that installing a package does not introduce runtime exceptions or hidden JavaScript 
dependencies. The compiler and the package rules exist to make that true, including restrictions such as 
forbidding ports in community packages to avoid surprising runtime behaviour and fragile foreign code paths.

The Elm compiler also devotes substantial effort to rich diagnostics. Different stages of compilation have 
dedicated error types and reporting modules, which take internal failures and turn them into user friendly 
reports for syntax errors, type mismatches, documentation issues, and more. Errors are represented with 
detailed context about where the mismatch occurred, what was expected, and what was found, and the reporting 
code renders this as a structured, human readable message with suggested fixes.

This is exactly the world that large language models lack internally. They do not have a notion of a type 
environment, or of an entry point contract. They generate code that must then be checked against such 
contracts by an external system. In the Elm world, that external system is the compiler, which turns mistakes 
into a stream of structured feedback.

Human programmers already use that feedback conversationally. They write some code, run the compiler, read 
the error, adjust, and repeat. Artificial intelligence systems can do the same: call the compiler, receive a 
rich diagnostic, and refine the generated code. In that sense, strong typing and good error reporting do not 
compete with artificial intelligence. They make it more capable. They provide a dense, informative signal 
that guides search through the space of possible programs.

**Why eco in the age of AI**

The limitation is that Elm, as it exists today, is mostly confined to the browser. It is an excellent 
language for building web applications, but its guarantees and ergonomics do not extend to high performance 
server side code, long running services, or data intensive backends.

eco is an Elm compiler and runtime intended to bring Elm’s qualities to a wider domain of application: 
native executables, high performance server processes, and cloud backends. The goal is to make it possible to 
write business systems in a high level, purely functional language with strong static guarantees. eco is a 
bet that you can have Elm’s safety and clarity with zero compromise on performance, across the whole stack.

As more application code is sketched or generated by AI models, eco gives those models a better target. It 
extends Elm’s world of strong static guarantees, semantic clarity, and rich compiler feedback from the 
browser into servers and backends.

**Compilers are leverage**

If computation remains important, if energy and latency continue to matter, and if some systems must not 
fail, then code will not vanish. Artificial intelligence may dramatically change how that code is produced 
and who produces it, but it does not remove the need for a trusted, semantics aware toolchain that turns 
intent into executable behaviour.

In that world, compilers are not relics of an earlier era. They are leverage points. They are where we encode 
our understanding of languages, architectures, and correctness. They are where we recover efficiency from 
increasingly complex hardware and increasingly messy software.

Artificial intelligence does not make that work obsolete. It makes it more urgent, because the more we rely 
on generated software, the more we will need compilers that can understand, constrain, and perfect it. That 
is why, even in the age of AI, it is still worth writing a new compiler.
