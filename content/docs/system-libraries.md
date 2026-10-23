---
title: "Eco's System Libraries"
description: "Eco has two IO libraries of its own, both Elm packages whose functions end in kernels: C++ for native programs and JavaScript for Node."
section: "Theory"
sectionOrder: 2
order: 23
---

Eco has two IO libraries of its own, both Elm packages whose functions end in kernels: C++ for native programs and JavaScript for Node. `eco/kernel` is the compiler's private IO layer, a small set of modules that lets the compiler, written in Elm, read files, run processes and download packages so that it can build itself. `eco/system` is the public system library for Eco programs, derived from the Node library of Gren, a language close to Elm, and covers files, child processes, streams, sockets, TLS, WebSockets, an HTTP server and the terminal. Elm's own kernels reproduce a contract someone else wrote, the published `elm/*` packages. These two libraries invent their APIs, so they also carry rules of their own. Only the eco thread touches the heap, and slow work runs on service threads that see plain data. A task-returning kernel does no IO when it is called, and in `eco/system` its body hands the work to a service and parks the task until the eco thread delivers the result. Errors cross as tuples and are typed in Elm, and a program stays alive exactly while it waits for something it asked for.

## Two packages for two kinds of caller

The two packages differ in who calls them, and that sets how freely each can change. `eco/kernel` has one caller, the compiler, and its API follows the compiler's needs. `eco/system` has every Eco program as a caller, so its API is designed for programs and kept stable for them. `eco/system` does not depend on `eco/kernel`, so a change the compiler needs never reaches a public module.

Both packages give each module the same three files: an Elm wrapper with the public API, a JavaScript kernel for Node, and a C++ kernel for native code. Both kernels implement the same signatures and return the same value shapes, so one Elm wrapper serves both targets.

The library code lives in five top-level directories, and only the first three take part in the build:

- `eco-kernel-cpp/` is the package `eco/kernel`.
- `system-kernel-cpp/` is the package `eco/system`.
- `examples/` is an application on top of `eco/system`: small programs such as a `cat`, an `ls`, TCP and UDP echo servers, a TLS client, an HTTP echo server and a WebSocket chat. Beside them sit compute benchmarks that build under both Eco and the official Elm compiler.
- `elm-io-lib/` is a port-based IO library, published as `guida/elm-io`.
- `elm-io-ports-example/` is a sample program for that library.

The last two have package manifests of their own and look live, but nothing in the build refers to them. They do IO through Elm ports, which cannot carry `Bytes`, and the compiler needs `Bytes` for file contents. A reader can treat them as history kept in the tree.

## The compiler's IO layer

`eco/kernel` exists because the compiler needs IO that no Elm package offers. Its modules fall into three groups: plain IO (files, the console and HTTP), the process and its environment (environment variables, child processes, runtime information, crash reporting), and services the compiler uses internally (shared variables, hashing, collector controls and the call into the native back end).

Its API is fixed by a second implementation of the same `Eco.*` modules that runs under stock Elm by sending browser-style HTTP requests to a local handler. The same compiler sources therefore build through the stock Elm compiler early in bootstrap and through Eco once Eco can compile itself; the JavaScript kernels of `eco/kernel` serve those early stages. This is also why `eco/kernel` cannot become the public API. Every change to it must be matched in the stock-Elm implementation and must suit the compiler, and a public API that moved with the compiler would break programs.

Every task-returning function in `eco/kernel` follows the deferral rule from [kernels.md](/docs/kernels): calling it builds a task binding and nothing else, and the body does the IO on the eco thread when the scheduler runs it. Fallible functions return a tuple of an error tag, a path and a message, which the Elm wrapper turns into a typed error.

Its shared variables are boxes that hold one value or none, and a task that reads an empty box waits until another task fills it. The box stores the Elm value itself rather than an encoded copy, because encoding and decoding large compiler structures through `Bytes` dominates the cost. A task that waits on an empty box parks its fiber, the scheduler's unit of running Elm code, instead of blocking the thread. All Elm code runs on one thread, so blocking it would also stop the task that is meant to fill the box.

## What a program sees in eco/system

An `eco/system` program is an ordinary Elm worker program whose flags are the environment: arguments, environment variables, the platform and handles for the standard streams. Decoding the environment as flags means the runtime needs no special entry point for system programs.

Streams are the interface that joins the library together. A file, a child process's pipes, a socket connection and a WebSocket all appear as readable and writable streams, so piping, text codecs and closing one direction of a connection work the same way on every one of them. A connection is a pair of streams. A datagram is one message rather than a flow, so it is a plain value instead.

Every error and every enumeration is an Elm custom type. For example, a stream error is closed, locked, canceled or failed with a cause, and each module has its own kind of failure. The kernels report a failure as a tuple of an origin, a code and a message, and each Elm module decodes the codes it owns. Strings would invite typos and force string comparison in user code. Decoding per module also keeps `Stream` independent of the modules built on it, such as sockets and files, since `Stream` never needs to know their codes.

The library has no HTTP client. Elm's own HTTP package already runs natively through Elm's kernels, so `eco/system` adds only streaming request and response bodies on top of it, in `Http.Stream`. That module cannot extend the HTTP package's body and response types directly, because those types are opaque.

Several modules are effect modules: Elm modules whose commands and subscriptions a runtime manager services. `System`, the file system, child processes, the terminal, sockets, WebSockets and the HTTP server are among them. On the native target each has a C++ manager, keyed by the bare module name. The compiler records which of these managers a program uses and emits a call to register each one before the program starts, so a program carries only the managers it needs. The Elm bodies of these managers run only on the JavaScript target.

## How eco/system defers its work

`eco/system` keeps the call-time half of the deferral rule unchanged: calling a task-returning kernel builds a task binding and does no IO. It adds a rule for the binding's body, because most of its work, such as reading a file, waiting on a socket or running a TLS handshake, is too slow to run on the eco thread, which runs every Elm task. A body that is quick and never blocks runs its work inline and returns the result task directly, as `eco/kernel` bodies do. Every other body splits the work in two: the body starts it, and the eco thread finishes it later.

Two kinds of integer cross between the eco thread and the services, and they must not be confused. A handle id names a resource such as an open file or socket, indexes a table on the C++ side, and lives as long as the resource. A token names one wait: the scheduler issues it when it parks a task, the request carries it to a service, and the result carries it back so the eco thread can find the task to resume.

An asynchronous body takes these steps, in this order:

1. Copy every argument it needs out of the heap into plain C++ data. This comes first because the later steps can allocate, any allocation can move heap objects, and a pointer read afterward could be stale.
2. Park the waiting task with the scheduler. Parking returns the token and takes a liveness hold, which keeps the program running for the length of the wait.
3. Hand the plain data and the token to a service. The service's thread never receives a heap pointer.
4. Return a kill handle, the value the task holds while it waits.

The second half runs on the eco thread. Each service registers itself with the scheduler as a source of asynchronous events, and the scheduler drains the source's queue of finished results. For each one the drain builds the heap result or the error tuple, roots it, resumes the parked task with it, and releases the hold. It does each of these exactly once per token.

The file system's pool submission shows the first half in one function. It comes from `system-kernel-cpp/src/eco-system/FileSystem/FileSystem.cpp`, trimmed where marked:

```cpp
HPointer fsPoolSubmit(FsOp op, FsKind kind, HPointer captured, HPointer resume) {
    uint64_t token = 0;
    bool counted = false;
    ECO_SYSTEM_ASYNC_GUARD(FErr, resume, token, counted,
        bool bytes = kind == FsKind::PathBytes || kind == FsKind::HandleBytes;
        FsArgs args = unpack(captured, bytes);   // G3: read first
        ...
        auto& s = Scheduler::instance();
        token = s.parkResume(resume, HoldKind::Task, "FileSystem.op");   // G10
        counted = true;
        CompleteFn complete = kind == FsKind::Open ? &fsCompleteOpen : &fsComplete;
        SysWorkPool::instance().submit(
            token,
            [op, a = std::move(args)]() -> PoolResult { return PoolResult::of(op(a)); },   // worker: POD only
            complete, ErrShape::FErr);
        return alloc::unit();   // kill handle: unit (pool jobs are short)
    )
}
```

Notice the order. `unpack` reads the captured heap arguments into `FsArgs` before anything else, and `parkResume` takes the hold and returns the token in one call. The worker's lambda captures only the operation and the plain arguments. The completion function runs later in the pool's drain on the eco thread, where it builds the result or the file system's error tuple and resumes the task. The guard is told the error shape, the token and whether the hold has been taken, which it needs to fail the task cleanly if the body throws part way: it drops any registration the token made, resumes the task with the error for that shape, and only then releases the hold, if one was taken. The kill handle is unit because a pool job is short and is left to finish. The `G` comments cite numbered rules in the library's design notes, and every C++ file under `eco-system/` names the rooting templates from those notes that it uses.

## The services behind the drain

The services are long-lived objects, each running on its own detached threads, created on first use and never torn down. Never destroying them means the process can exit while their threads still run, without destructors racing those threads. They share one contract: plain data and a token in, plain data and the same token out through a queue. Five kinds exist:

- A worker pool runs short blocking system calls, such as opening or reading a file, so the eco thread never waits on the disk.
- A stream poller gives each descriptor-backed stream (standard input and output, child process pipes, file streams) one thread that waits on that descriptor.
- One reactor thread, built on the operating system's readiness interface (epoll on Linux, kqueue on macOS), serves every socket, TLS session, HTTP server connection and WebSocket.
- A signal service and a file-watch service each run a thread that waits for those operating system events.
- Each streaming `Http.Stream` transfer runs on its own thread driving libcurl. Ordinary Elm HTTP requests use the runtime's HTTP service instead, which runs them one at a time on a single worker thread.

Sockets go through one reactor rather than a thread per socket or per accepted connection. One readiness thread scales to many connections, and it gives TLS, HTTP/1.1, HTTP/2 and WebSocket one shared connection abstraction, with each protocol plugged in as a layer on top. The operating system reports readiness under a key made of the handler's slot and a generation number, never under the descriptor. Removing a handler bumps its slot's generation, and an event whose generation no longer matches is dropped, so an event meant for a removed handler, for example after its descriptor number is reused or duplicated into a child process, never reaches the slot's next occupant. The reactor asks the operating system about a descriptor only while someone is waiting on it, so an idle descriptor that has been reset cannot make the thread spin.

Work that nobody has asked for yet is held in a queue, never dropped. A listener accepts connections into a first-in-first-out queue even before Elm code asks for the next one. Accepting only on demand would leave a window between the accept and the Elm code that consumes it, in which a connection could be lost.

The HTTP server, the WebSocket codec and the HTTP/2 support are Eco's own, built on the vendored parsers llhttp and nghttp2, and all of them run on the reactor. The WebSocket framing rules exist twice, in C++ and in JavaScript, and the two must agree, since one test suite checks both targets against the same expectations.

Child processes are started with `posix_spawn`, never with `fork`. A fork would run the collector's fork handler and copy the whole heap into a child that only wants to run another program. One spawn primitive in the runtime serves both `eco/kernel` and `eco/system`.

## When a program exits

A program runs exactly while it waits for something it asked for. Each wait is one hold: a sleep, a pending read, a listener whose next connection someone has requested. When the last hold is released and no Elm work is left, the program exits. In native code a hold is a small object that releases itself once. In JavaScript it is one count on a shared counter.

Counting by resource gives answers that depend on the resource and the target. A listener would keep the program alive for its whole life while an idle connection keeps nothing alive. A killed sleep or a dropped `Time.every` subscription would still hold the program open. Re-arming the empty-event-loop notice on some implicit event would differ between targets in the same way, which is why re-arming is explicit, as described below. With one hold per wait, a reader can check each kernel by asking what it waits for and where it releases. Debug builds check that each hold is released exactly once.

Underneath the holds sits the runtime's pending-work counter, the number the scheduler reads to decide whether anything is still outstanding. Kernels never change it directly. Only the hold type does, so every change to it has a matching release.

A program can ask to be told when nothing is left to wait for. The notice fires once each time it is armed, and only an explicit `System.rearmEmptyEventLoop` from Elm arms it again, so the program decides each time whether it wants the next one.

## Two targets, one Elm layer

The JavaScript target of `eco/system` exists so that one end-to-end test suite checks both targets, and that suite is the library's specification. Its stream implementation is a port of the C++ stream state machine rather than a wrapper over the standard JavaScript streams, because only one state machine in two languages gives the same answers to the same tests. Where the targets really differ, a test carries a directive that skips it on JavaScript or runs it only on Linux. The differences are marked in the tests and never hidden inside an Elm wrapper.

Platform fixes keep documented behavior the same everywhere. Connecting to a Unix socket path that is not a socket reports connection refused on both targets, although some systems report that the path is not a socket.

The library's documentation says its macOS code paths are untested and Windows is unsupported. Continuous integration builds those platforms, so a successful build there shows only that the code compiles.

Third-party documentation tools run only the stock Elm compiler, which rejects kernel imports and effect modules. The library's documentation is therefore built from a generated copy of its sources with those parts rewritten, rather than through a wrapper that stands in for the stock compiler, which breaks builds.

## References

Parent: [kernels.md](/docs/kernels). Sibling: [elm-kernel.md](/docs/elm-kernel). Related: [scheduler-and-services.md](/docs/scheduler-and-services) for the scheduler, async sources and the runtime's HTTP service.

Code and documents:

- `system-kernel-cpp/README.md`, `system-kernel-cpp/elm.json`, `system-kernel-cpp/src/System.elm`, `system-kernel-cpp/src/Stream.elm`: the public shape of `eco/system`.
- `system-kernel-cpp/src/eco-system/Core/`: `Core.hpp` (guards such as `ECO_SYSTEM_ASYNC_GUARD` and `ECO_SYSTEM_BODY_GUARD`, rooting templates), `SysWorkPool.hpp`, `FdChannel.hpp` (stream pollers), `IoReactor.hpp`; also `SignalService` and `WatchService`.
- `system-kernel-cpp/src/eco-system/FileSystem/FileSystem.cpp` (`fsPoolSubmit`, `fsComplete`): the asynchronous body pattern.
- `system-kernel-cpp/src/eco-system/Socket/`, `HttpServer/` (`Http1.hpp`, `Http2.hpp`), `HttpStream/`, `WebSocket/`, `Tls/`, `Stream/`: protocol layers.
- `system-kernel-cpp/src/Eco/Kernel/`: JavaScript kernels, including `Liveness.js`.
- `system-kernel-cpp/CMakeLists.txt`: vendored llhttp, nghttp2, OpenSSL 3, libcurl, zlib and libzip.
- `scripts/make-docs-package.js`: the documentation copy.
- `test/scripts/check-kernel-homes.sh`: rejects `eco/system` kernel homes that collide with other kernel homes.
- `eco-kernel-cpp/src/Eco/`, `eco-kernel-cpp/src/eco-kernel/File.cpp`, `TaskBinding.hpp`, `KernelHelpers.hpp`, `ExportHelpers.hpp`: the `eco/kernel` pattern (`makeBinding`, `makeAsyncBinding`).
- `compiler/src-xhr/Eco/`: the stock-Elm implementation of the `Eco.*` modules.
- `runtime/src/platform/Liveness.hpp` (`LivenessHold`), `TaskBinding.hpp`, `Spawn.hpp`: runtime pieces these libraries use. Setting `ECO_LIVENESS_REPORT=1` prints the holds still open.
- `compiler/src/Compiler/Generate/MLIR/Functions.elm` (`ecoSystemManagers`, manager registration), `compiler/src/Compiler/Elm/EcoEnvironment.elm` (environment flags), `compiler/src/Compiler/Elm/Package.elm` (`isKernel`: which packages may hold kernels).
- `examples/src/`, `examples/benchmarks/`: example programs and benchmarks.
- `elm-io-lib/`, `elm-io-ports-example/`, `design_docs/guida-io-ops.csv`: the dormant port-based library and the IO operation inventory.
- `plans/eco-system-library.md` sections 2 and 3.2 to 3.4: the library's threading and rooting rules. `plans/native-http-client.md`: a proposed replacement for libcurl, not built.
- Tests: `test/eco-kernel/`, `test/eco-system/` (the specification; `-- SKIP-JS:` and `-- LINUX-ONLY:` directives), `test/eco-system-core/`, `test/conformance/`.

Invariants (`design_docs/invariants.csv`):

- SYS_001 to SYS_008 cover the system library; the ones the text relies on most:
- SYS_001: the values that may cross the `eco/system` boundary, and its deferral.
- SYS_003, PORT_006: only the eco thread touches the heap; services see plain data.
- SYS_004: the reactor and its demand-driven interest.
- SYS_005, SYS_006: the WebSocket codecs agree; the HTTP server protocols.
- SYS_007: spawn, never fork.
- LIVE_001 to LIVE_006: one hold per wait; no direct changes to the pending-work counter.
- IO_ERR_002, FORBID_IO_001: neutral error tuples.
- KERNEL_TASK_IO_001, KERNEL_TASK_IO_002: task kernels defer their IO and root what they hold.
- HEAP_007, HEAP_011: one thread changes the heap; any allocation may move objects.
- KERN_006: the compiler alone decides kernel calling conventions.
