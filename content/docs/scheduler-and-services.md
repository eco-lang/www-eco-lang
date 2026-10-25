---
title: "Scheduler and services"
description: "How Eco runs Elm's tasks, processes, effect managers and ports natively: an event loop on one thread that owns the heap, with timers, HTTP and child processes waiting on worker threads that only ever see plain data."
section: "The runtime"
sectionOrder: 4
order: 6
---

When an Elm program calls `Process.sleep 500`, something has to wait half a second without stopping every other task. In Eco that wait happens on a timer thread, but the timer thread never sees an Elm value: it holds a deadline and a 64-bit token, and nothing else. Only the eco thread touches the heap. This article follows that one sleep through the scheduler, then shows that HTTP, child processes, sockets and ports all work the same way.

> **Background**
>
> - [Eco thread](/docs/glossary#eco-thread): the one thread that runs Elm code and owns the heap.
> - [Mutator](/docs/glossary#mutator): the code that allocates and builds objects, as opposed to the collector. Eco has one per heap.
> - [Kernel](/docs/glossary#kernel): a built-in function implemented in C++ rather than in Elm, such as `Process.sleep`.
> - A *task* is a description of work; a *process* is a task that is running.

## Why only one thread touches the heap

Eco's [garbage collector](/docs/garbage-collector) allows one mutator per heap, and it needs no write barrier because no object changes once the program can see it. A second thread that ran Elm code, or a worker that allocated its own result, would break both assumptions: an allocation on the worker could trigger a collection that moves an object the eco thread is reading.

The scheduler is therefore an event loop on the eco thread, and every service that blocks has the same shape. A plain request goes in, a token comes out, and all heap work happens later, back on the eco thread. Timers show what goes wrong otherwise. A thread per sleep that resumed the Elm task from its own thread would allocate off the eco thread and corrupt the collector's state.

## Tasks and processes are heap values

A task is an ordinary heap object with the six constructors of elm/core's scheduler. `Succeed` and `Fail` carry a result. `AndThen` and `OnError` carry a callback and the inner task to run first. `Binding` carries the callback that does real work, such as starting a timer. `Receive` waits for a message. A process is a running task: an id, a root task, a stack of pending callbacks and a mailbox.

We keep both as Elm heap values because that follows elm/core closely. In our view a scheduler built from reference-counted C++ objects would fight the collector and drift from elm/core's behaviour.

A process is never changed in place. Each step that changes its root, stack or mailbox allocates a fresh process with the same id, and the scheduler keeps a table from id to the latest version. The reason is the collector again. A long-lived process sits in the old generation, and the task written into it is usually brand new. Writing a young pointer into an old object is exactly what the barrier-free collector cannot see. Replacing the process costs one allocation per step, and it means that anything that must find a process later (a kill, a message an effect manager sends itself) holds its id, not a pointer to it. Ids are full 64-bit words from a counter that never wraps, and a process's entry leaves the table when it finishes.

## Following one sleep

Take this program fragment:

```elm
Process.sleep 500
    |> Task.andThen (\_ -> Task.succeed "done")
```

![Process.sleep round trip between the eco thread and the timer thread](/images/docs/sleep-sequence.svg)

**Step 1: the kernel builds a Binding and nothing else.** Calling `Process.sleep` does not start a timer. The C++ kernel boxes the number of milliseconds and wraps a body function as an asynchronous binding (comments trimmed):

```cpp
HPtr Elm_Kernel_Process_sleep(double time) {
    HPointer floatHP = Elm::alloc::allocFloat(time);
    return HPtr::fromBits(encode(
        Elm::Platform::makeAsyncBinding<sleepBindingBody>(floatHP)));
}
```

`makeAsyncBinding` allocates a closure that captures the boxed float and returns a `Binding` task holding it. This is the rule for every kernel that returns a task: building it does no input or output. A task is a value; it may be built and never run, or run many times. The [Kernels](/docs/kernels) article gives the reasons in full.

**Step 2: the scheduler steps the process and reaches the Binding.** The `AndThen` is pushed onto the process's stack first. When the scheduler then finds the `Binding` at the root, it allocates a *resume closure* that captures the current snapshot of the process, and calls the binding's callback with it. The process stops there, waiting.

**Step 3: the body parks the resume closure and hands the timer a token.** This is the sleep's body, run on the eco thread (comments trimmed):

```cpp
static HPointer sleepBindingBody(HPointer captured, HPointer resume) {
    void* ptr = Allocator::instance().resolve(captured);
    double millis = static_cast<ElmFloat*>(ptr)->value;

    uint64_t resumeToken = Elm::Platform::Scheduler::instance().parkResume(
        resume, Elm::Platform::HoldKind::Task, "Process.sleep");
    Elm::Platform::TimerService::instance().schedule(millis, resumeToken);

    HPointer kill = Elm::alloc::allocClosureK(&sleepKillEval, /*max_values=*/2, Elm::PK_Boxed);
    void* p = Allocator::instance().resolve(kill);
    Elm::alloc::closureCapture(p, Elm::alloc::unboxedInt(static_cast<int64_t>(resumeToken)),
                               Elm::PK_Int);
    return kill;
}
```

`parkResume` does two things in one call. It stores the resume closure in the scheduler's table of pending resumes, which the collector scans as a root, and returns a fresh token for it. And it takes a *hold*, which keeps the program alive while the sleep is outstanding (more on holds below). The timer receives only `millis` and the token. The body returns a kill handle, a small closure that captures the token, so that `Process.kill` can cancel the sleep.

**Step 4: the timer thread fires the token.** The timer service keeps deadlines in order. Its thread waits until the earliest one passes, removes it, pushes the token onto a queue of fired tokens and wakes the event loop:

```cpp
{
    std::lock_guard<std::mutex> rlk(readyMutex_);
    readyTokens_.push(token);
}
Scheduler::instance().notifyWorkAvailableFromAsync();
```

That is the only thing the timer thread ever does to the scheduler. It never sees a pointer.

**Step 5: the eco thread turns the token back into Elm.** Each turn of the event loop collects finished outside work. For timers (trimmed):

```cpp
while (TimerService::instance().tryPopReadyToken(token)) {
    HPointer resumeClosure = takePendingResume(token);
    if (alloc::isNil(resumeClosure)) {
        releaseHold(token);
        continue;
    }
    HPointer succeedTask = listNil();
    {
        StackRootGuard guard(&resumeClosure, &succeedTask);
        succeedTask = taskSucceed(unit());
        callClosure1(resumeClosure, succeedTask);
    }
    releaseHold(token);   // after the resume is published
}
```

The token finds the resume closure, which may have moved since step 3; the table always holds its current address. The loop builds `Succeed ()` and calls the closure. The resume closure builds a new process from the snapshot it captured, with `Succeed ()` as its root, and puts it on the run queue. Only then is the hold released, so there is no moment at which the program looks idle while the result is still in flight.

**Step 6: the process runs on.** The next drain of the run queue steps the new process. It finds `Succeed ()`, pops the `AndThen` frame, and calls `\_ -> Task.succeed "done"`.

If the sleep is killed instead, the kill handle withdraws the pending resume and cancels the timer. It releases the hold only if the timer had not yet fired; if it had, step 5 finds no resume closure and does the release. Either way the hold is released exactly once.

## The event loop

The loop has the familiar shape of libuv or Node's event loop. Putting a process on the run queue never runs it: enqueuing takes a lock, pushes and wakes the loop. The loop repeats three steps:

1. Drain the run queue, stepping processes until it is empty.
2. Collect finished outside work: fired timers as above, then every other registered source.
3. Wait or exit. If nothing is queued and no holds remain, the program is finished. Otherwise sleep until a process is queued, a token fires, a source has results, or the last hold is released.

The run queue, the latest-process table and the pending resumes live in C++ containers the collector cannot otherwise see, so the scheduler registers one scanner that visits them all.

## Holds: why a program is still running

An Elm worker has no obvious end. Eco's rule is that a program runs exactly while it is waiting for something it asked for. Each such wait takes one hold, and the scheduler's count of holds changes only through one small interface. A listener nobody is waiting on holds nothing.

We prefer this to deciding liveness resource by resource, with counters spread through the code. Such counts disagree about lifetimes and cancellation, and a program that never exits has no way to say why. With one interface, debug builds abort on a release of an unknown hold or a second release of the same one, and a diagnostic report lists the holds still open by the code that took them.

## Workers and other sources

Three services in the runtime own worker threads, and each follows the sleep's shape: plain data in, a token out, a mutex-guarded queue back.

- The **timer service** described above.
- The **HTTP service** runs one worker thread that performs requests in turn through libcurl. It keeps separate result queues for elm/http and for the compiler's own IO library, because both use it and neither may take the other's results.
- The **wait service** blocks on child processes exiting, again with one queue per consumer.

Anything else joins the loop by registering a pair of functions: a drain that does the heap work on the eco thread, and a readiness test the loop's wait reads. The [System libraries](/docs/system-libraries)' sockets, signals and file watches, and the queue of port messages from a host program, all join this way, so the loop knows nothing about any of them.

## Effect managers and ports

An effect manager turns commands and subscriptions into work: Time, Http and Task from elm/*, the system library's managers, and one pseudo-manager per port. After each `update`, Eco gathers the commands and subscriptions, hands each leaf to its manager, and runs every manager's handler, even one with nothing to do, so that a manager whose subscription list became empty can drop its timers. This dispatch finishes inside the same drain that ran the update. That matters for holds: every hold a new subscription takes exists before the run queue can empty, so the loop never sees a false moment with nothing to do.

A port is a manager keyed by its name, as in elm/core's JavaScript. Outgoing values reach the host as JSON strings. A host may send an incoming value from any thread: the bytes are copied into a queue, take a hold and wake the loop, and the eco thread decodes them.

## Start-up and child processes

The program's entry point does no Elm work. It starts one thread with a 64 MB stack and waits for it. That thread becomes the eco thread: it sets up the heap, registers the elm/* managers and calls the compiled program, which ends in the event loop. The stack is large because compiled Elm recurses deeply, most of all when the compiler compiles itself; the size matches what the JavaScript build gets under Node.

Child processes are started with a spawn call, never a fork. A fork would copy the whole Eco heap and the collector's helper threads' state, only to throw it away when the child starts its program.

> **Designs we didn't use.** We rejected parallel Elm by locking the stepper, so that several threads share one heap, because the collector and every service assume one mutator per heap. A heap per thread is the direction we would take instead. It is not built.

## Further reading

- [The runtime](/docs/runtime) — the threads in a running program and how work leaves and re-enters the eco thread.
- [The garbage collector](/docs/garbage-collector) — why one mutator and frozen objects mean no write barrier.
- [Kernels](/docs/kernels) — why a kernel that returns a task does nothing until the scheduler steps it.
- [System libraries](/docs/system-libraries) — the reactor and worker pool that join this event loop.
- The full design document: [Scheduler and services theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/runtime/scheduler-and-services.md)
- Source: [`runtime/src/platform`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/platform)
