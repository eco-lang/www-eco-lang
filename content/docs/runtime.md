---
title: "The runtime"
description: "Eco's C++ runtime, linked into every executable, gives each program one thread that owns the heap, a garbage collector and an event loop that runs Elm's tasks."
section: "The runtime"
sectionOrder: 4
order: 1
---

A compiled Eco program carries a runtime written in C++, linked into every executable. Its central rule is simple: one thread, the eco thread, runs all Elm code and is the only thread that touches the heap. Every other thread (timers, network waits, the collector's helpers) works on plain data or under a strict protocol, and hands results back to the eco thread to turn into Elm values.

> **Background**
>
> - An [eco thread](/docs/glossary#eco-thread) is the one thread per process that runs Elm code and allocates Elm values.
> - The [mutator](/docs/glossary#mutator) is collector jargon for the code that allocates and changes pointers; in Eco it is the eco thread.
> - A [write barrier](/docs/glossary#write-barrier) is extra work a collector adds to every pointer store. Eco has none.

The runtime has two halves. The garbage collector decides how values are stored and when they are reclaimed. The scheduler decides when Elm code runs. Both are built around the eco thread.

![Threads in a running Eco program and what passes between them](/images/docs/runtime-threads.svg)

## The eco thread owns the heap

Each process has exactly one mutator. With one mutator, the collector has the heap to itself whenever it runs: nothing else is allocating, reading, or holding a pointer the collector has not been told about. The scheduler follows from the same rule. It cannot hand Elm work to another thread, so it is an event loop on the eco thread: it steps one task at a time, and when nothing is ready it waits for an outside event.

The missing write barrier has a different source: Elm's immutability. An old object can never point to a younger one, because the younger one did not exist when the old one was built, and nothing writes into an object afterwards. One mutator and immutability are separate facts, and the runtime needs both.

We considered three threading designs:

| Design | Status |
|---|---|
| One heap, one mutator per process | What Eco does today. |
| One shared heap with many mutators | Rejected: it needs pointers between threads' young objects, or stop-the-world collections with safepoint polls in every loop, and much larger formal models. |
| A heap per thread, threads exchanging only messages | The chosen future direction, not built. Memory accounting is process-wide today and would have to be split per heap. |

Besides the eco thread there are two other kinds of thread. The collector's helpers mark the old generation and promote survivors in the background, under protocols that are also written as formal models (see [Model-checking the collector](/docs/concurrency-models)). Service threads wait on timers, HTTP and child processes, and they hold only plain data: deadlines, request structures, resume tokens.

## How work leaves and re-enters

Service threads never allocate, never follow a heap reference and never run Elm code. They post results to queues, and the scheduler drains those queues on the eco thread and builds the Elm values there. A timer thread that called back into Elm and allocated would corrupt the collector's state, so every service is built this way.

A kernel function that returns a `Task` does no input or output when it is called. It returns a value that *describes* the work, and the work happens when the scheduler steps that task. If the work would block, it parks a resume token and a service thread makes the system call, so the eco thread keeps running other tasks. Doing the work at call time would break what a `Task` means in Elm: two tasks could never overlap, and a task that was stored and run twice would see the state of its first run.

A program stays alive exactly while it waits for something it asked for. Each wait takes a counted claim called a hold, and the event loop exits when the run queue is empty and no holds remain. A program embedded in a host (as a shared library or a Node addon) works the same way: the host's thread never becomes the mutator, and port messages cross as JSON through a queue that the eco thread drains.

## How the collector finds live values

Because the collector moves young objects, it must find every live pointer and rewrite it when its object moves. Compiled code reports its pointers through stack maps that LLVM writes into the executable, one per call site that may collect; the runtime walks the stack and looks up each frame. C++ code in the runtime and the kernels has no stack maps, so any C++ that holds a heap value across an allocation registers it as a root. An unregistered value is silently left pointing at the old copy.

## What is in this section

- [Value representation](/docs/value-representation): how every Elm value becomes one 64-bit word, and why a heap pointer is its own address.
- [Closures and calls](/docs/closures-and-calls): the closure object, and how the runtime applies any closure to any number of arguments.
- [Runtime data structures](/docs/data-structures): the several heap forms of strings, lists and bytes.
- [The garbage collector](/docs/garbage-collector): a generational, concurrent collector with no write barrier.
- [Scheduler and services](/docs/scheduler-and-services): Elm's scheduler, timers, HTTP and ports on one thread.
- [Kernels](/docs/kernels) and [System libraries](/docs/system-libraries): Elm's built-in functions, rewritten in C++.

## Further reading

- [Eco at a glance](/docs/theory) — where the runtime sits among the compiler and backend.
- [The garbage collector](/docs/garbage-collector) — the immutability argument in full.
- [Scheduler and services](/docs/scheduler-and-services) — the event loop and service threads in detail.
- The full design document: [Runtime theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/runtime/runtime.md)
- Source: [`runtime/src`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src)
