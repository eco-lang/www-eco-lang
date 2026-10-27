---
title: "The runtime"
description: "eco's C++ runtime, linked into every executable, gives each program one thread that owns the heap, a garbage collector and an event loop that runs Elm's tasks."
section: "The runtime"
sectionOrder: 4
order: 1
---

Every compiled eco program links in a runtime written in C++. Its central rule is that one thread, the eco thread, runs all Elm code and is the only thread that touches the heap. Every other thread (timers, network waits, the collector's helpers) works on plain data or under a strict protocol, and hands results back to the eco thread to turn into Elm values.

> **Background**
>
> - An [eco thread](/docs/glossary#eco-thread) is the one thread per process that runs Elm code and allocates Elm values.
> - The [mutator](/docs/glossary#mutator) is collector jargon for the code that allocates and changes pointers; in eco it is the eco thread.
> - A [write barrier](/docs/glossary#write-barrier) is extra work a collector adds to every pointer store. eco has none.

The runtime has two halves. The garbage collector decides how values are stored and when they are reclaimed. The scheduler decides when Elm code runs. Both are built around the eco thread.

![Threads in a running eco program and what passes between them](/images/docs/runtime-threads.svg)

## The eco thread owns the heap

Each process has exactly one mutator. The collector therefore has the heap to itself whenever it runs: nothing else is allocating, reading, or holding a pointer the collector has not been told about. The scheduler follows from the same rule. It cannot hand Elm work to another thread, so it is an event loop on the eco thread that steps one task at a time and, when nothing is ready, waits for an outside event.

The missing write barrier comes from somewhere else, Elm's immutability. An old object can never point to a younger one, because the younger one did not exist when the old one was built, and nothing writes into an object afterwards. One mutator and immutability are separate facts, and the runtime needs both.

Two other kinds of thread run beside the eco thread. The collector's helpers mark the old generation and promote survivors in the background, under protocols that are also written as formal models (see [Model-checking the collector](/docs/concurrency-models)). Service threads wait on timers, HTTP and child processes, and they hold only plain data: deadlines, request structures, resume tokens.

## How work leaves and re-enters

Service threads never allocate, never follow a heap reference and never run Elm code. They post results to queues, and the scheduler drains those queues on the eco thread and builds the Elm values there. Every service is built this way because a timer thread that called back into Elm and allocated would corrupt the collector's state.

A kernel function that returns a `Task` does no input or output when it is called. It returns a value that *describes* the work, and the work happens when the scheduler steps that task. If the work would block, it parks a resume token and a service thread makes the system call, so the eco thread keeps running other tasks. Doing the work at call time would break what a `Task` means in Elm: two tasks could never overlap, and a task that was stored and run twice would see the state of its first run.

A program stays alive exactly while it waits for something it asked for. Each wait takes a counted claim called a hold, and the event loop exits when the run queue is empty and no holds remain. A program embedded in a host (as a shared library or a Node addon) works the same way: the host's thread never becomes the mutator, and port messages cross as JSON through a queue that the eco thread drains.

## How the collector finds live values

The collector moves young objects, so it must find every live pointer and rewrite it when its object moves. Compiled code reports its pointers through stack maps that LLVM writes into the executable, one per call site that may collect; the runtime walks the stack and looks up each frame. C++ code in the runtime and the kernels has no stack maps, so any C++ that holds a heap value across an allocation registers it as a root. An unregistered value is silently left pointing at the old copy.

## What is in this section

- [Value representation](/docs/value-representation): how every Elm value becomes one 64-bit word, and why a heap pointer is its own address.
- [Closures and calls](/docs/closures-and-calls): the closure object, and how the runtime applies any closure to any number of arguments.
- [Runtime data structures](/docs/data-structures): the several heap forms of strings, lists and bytes.
- [The garbage collector](/docs/garbage-collector): a generational, concurrent collector with no write barrier.
- [Scheduler and services](/docs/scheduler-and-services): Elm's scheduler, timers, HTTP and ports on one thread.
- [Kernels](/docs/kernels) and [System libraries](/docs/system-libraries): Elm's built-in functions, rewritten in C++.

## Where threads could go

Two ideas are easy to confuse here. *Concurrency* is a program doing several things that wait on the world, such as timers, sockets and child processes. *Parallelism* is Elm code running on several cores at once. eco has the first today, through the scheduler and its service threads. It does not yet have the second.

One heap shared by several mutators is the route we rejected. Young objects on one thread would become reachable from another, and the collector's central simplification, that no object ever points at a younger one, would no longer hold. Avoiding that with stop-the-world collections would need safepoint polls in every loop, and either way the formal models of the collector would grow much larger. In our view the right shape is a heap per thread, with immutable messages as the only thing that crosses between them. That is close to the actor model, and to how Elm programs are already structured:

```elm
spawn : Actor flags model msg -> flags -> Task x (Process msg)
send : Channel OneToOne a -> a -> Task x ()
```

This is a sketch, not an API we are building, and memory accounting, which is process-wide today, would have to be split per heap. The open question is what a message costs. Copying it into the receiving heap keeps every heap independent. Sharing it avoids the copy, but needs either reference counts on messages or a shared old generation, and both reach deep into the collector. The [discussion on the Elm forum](https://discourse.elm-lang.org/t/if-elm-had-threads/10602) explores the programming model in more depth.

## Further reading

- [eco at a glance](/docs/theory) — where the runtime sits among the compiler and backend.
- [The garbage collector](/docs/garbage-collector) — the immutability argument in full.
- [Scheduler and services](/docs/scheduler-and-services) — the event loop and service threads in detail.
- The full design document: [Runtime theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/runtime/runtime.md)
- Source: [`runtime/src`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src)
