---
title: "System libraries"
description: "What Eco's own IO libraries give a program, from files and child processes to sockets and an HTTP server, and how their C++ kernels do slow work off the thread that runs Elm."
section: "The runtime"
sectionOrder: 4
order: 8
---

Elm was built for the browser, so it has no way to read a file, start a process or listen on a socket. Eco adds one: `eco/system`, an Elm package for command-line programs and servers, whose functions end in C++ kernels for native code and JavaScript kernels for Node. Its API is a port of the Node library of Gren, a language close to Elm. A program written with it is still an ordinary Elm program: it describes work as tasks and commands, and the runtime does the work.

> **Background**
>
> - [Kernel](/docs/glossary#kernel): a function with no Elm body, implemented by the platform.
> - [Eco thread](/docs/glossary#eco-thread): the one thread that runs Elm code and owns the heap.
> - A *stream* is a source or sink of bytes that can be read or written a piece at a time.

## A small program

This is the `cat` from Eco's examples, which copies each file named on the command line to standard output, or standard input when none is named (module header and imports trimmed):

```elm
main : Platform.Program System.Environment () ()
main =
    System.simpleProgram run


run : System.Environment -> Task Never ()
run env =
    -- args includes the program name first (the full C argv).
    case List.drop 1 env.args of
        [] ->
            Stream.pipeTo env.stdout env.stdin
                |> Task.onError (\err -> fail env ("cat: stdin: " ++ Stream.errorToString err))

        paths ->
            paths
                |> List.map (catFile env)
                |> Task.sequence
                |> Task.map (\_ -> ())


catFile : System.Environment -> String -> Task Never ()
catFile env path =
    FileSystem.readFile (Path.fromPosixString path)
        |> Task.andThen (\contents -> Stream.log contents env.stdout)
        |> Task.onError (\err -> fail env ("cat: " ++ FileSystem.errorToString err))


fail : System.Environment -> String -> Task Never ()
fail env message =
    Stream.logLine message env.stderr
        |> Task.andThen (\_ -> System.setExitCode 1)
```

It builds and runs like any native program:

```text
eco make src/Cat.elm --output=cat
./cat elm.json
```

Three things in it are typical. The environment arrives as the program's flags: arguments, environment variables, the platform, and the standard streams, so the runtime needs no special entry point for system programs. `System.simpleProgram` makes a one-shot program that runs a task; a long-running program, such as a server, is an ordinary `Platform.worker` with a model, `update` and subscriptions. And every failure is an Elm custom type with its own `errorToString`, never a bare string.

## What the library covers

- **Files and directories**, through `FileSystem` and `Path`.
- **Child processes**, with their pipes as streams.
- **Streams**: standard input, output and error, files, pipes, sockets and WebSockets all appear as readable and writable streams, so piping, text codecs and closing one direction work the same way on each of them.
- **Sockets**: TCP, Unix domain sockets, UDP datagrams and TLS.
- **An HTTP server** with HTTP/1.1, HTTPS and HTTP/2 over TLS, and **WebSockets** as client and server.
- **The terminal**, signals and file watches.

There is no HTTP client. Elm's own `elm/http` already runs natively through [Elm's kernels](/docs/kernels), so `eco/system` adds only streaming request and response bodies on top of it. The examples folder that ships with Eco has an `ls`, TCP and UDP echo servers, a TLS client, an HTTP echo server and a WebSocket chat room. [Getting started](/docs/getting-started) shows how to build them.

## Doing slow work off the eco thread

Reading a file, waiting on a socket or running a TLS handshake is too slow to do on the eco thread, which runs every Elm task. But only the eco thread may touch the heap, because the [garbage collector](/docs/garbage-collector) allows one mutator and any allocation can move objects. So an `eco/system` kernel that returns a task follows the same pattern as `Process.sleep` in [Scheduler and services](/docs/scheduler-and-services). Calling it only builds a task binding. When the scheduler runs the binding, its body:

1. copies every argument it needs out of the heap into plain C++ data, first, because the later steps can allocate and move the heap objects;
2. parks the waiting task with the scheduler, which returns a token and takes a hold that keeps the program alive;
3. hands the plain data and the token to a service thread, which never receives a heap pointer;
4. returns a kill handle.

Later, on the eco thread, the service's drain builds the Elm result or error from the plain result, resumes the parked task, and releases the hold, exactly once per token. A body that is quick and never blocks skips all of this and returns its result directly.

Two kinds of integer cross between the eco thread and the services, and they are kept distinct. A *handle id* names a resource such as an open file or a socket, indexes a table on the C++ side, and lives as long as the resource; no C++ object ever lives inside the heap. A *token* names one wait, and lives only until its result is delivered.

## The services

The services are long-lived objects on their own threads, started on first use and never torn down, so the process can exit without destructors racing those threads.

- A **worker pool** runs short blocking system calls such as opening or reading a file.
- A **stream poller** gives each descriptor-backed stream (standard streams, pipes, file streams) a thread that waits on it.
- One **reactor** thread, built on epoll on Linux and kqueue on macOS, serves every socket, TLS session, HTTP server connection and WebSocket.
- **Signal** and **file-watch** services each wait for their operating system events.

Sockets share one reactor rather than a thread per connection. One readiness thread scales to many connections, and it gives TLS, HTTP/1.1, HTTP/2 and WebSocket a single connection abstraction, with each protocol layered on top. The reactor files each readiness event under a slot and a generation number rather than the file descriptor, so an event meant for a closed handler is dropped even if the operating system reuses the descriptor number. A listener accepts connections into a queue even before Elm asks for the next one; accepting only on demand would leave a window in which a connection could be lost.

## When a program exits

A program runs exactly while it is waiting for something it asked for: a sleep, a pending read, a listener whose next connection someone has requested. Each wait is one hold, and when the last hold is released and no Elm work is left, the program exits. A listener nobody is waiting on keeps nothing alive. A program that wants to know when it has gone idle can ask to be told once; it must ask again explicitly for the next notice, so a handler that does its own IO cannot keep re-arming itself forever.

## The compiler's own IO library

`eco/system` has a smaller sibling, `eco/kernel`, with one user: the compiler, which is written in Elm and needs to read files, run processes and download packages to build itself. Its API follows the compiler's needs, so it is not public, and `eco/system` does not depend on it. A second implementation of the same modules runs under the stock Elm compiler by sending HTTP requests to a local handler, which is how the compiler's sources build through stock Elm early in [the bootstrap](/docs/bootstrap). Every change to `eco/kernel` has to work in both places, which is another reason programs get a separate, stable library.

## Two targets, one Elm layer

Each module of both libraries has an Elm wrapper with the public API, a C++ kernel and a JavaScript kernel, returning the same shapes so one wrapper serves both targets. The JavaScript target of `eco/system` exists so that one end-to-end test suite checks both, and that suite is the library's specification. Its stream implementation is a port of the C++ stream state machine rather than a wrapper over Node's streams, because only the same state machine gives the same answers to the same tests. Where the targets really differ, the test says so with a directive, rather than the difference being hidden in an Elm wrapper. Every module is tested on Linux and macOS, where the end-to-end suite runs in continuous integration. Windows is not supported yet: the package builds there, but most IO functions report that they are not supported.

> **Designs we didn't use.** Starting child processes with `fork` would copy the whole heap into a child that only wants to run another program, so Eco uses `posix_spawn`.

## Further reading

- [Kernels](/docs/kernels) — the kernel mechanism these libraries are built on.
- [Scheduler and services](/docs/scheduler-and-services) — the event loop, tokens and holds the services plug into.
- [Getting started](/docs/getting-started) — installing Eco and building the example programs.
- The full design document: [System libraries theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/kernels/system-libraries.md)
- Source: [`system-kernel-cpp`](https://github.com/eco-lang/eco-compiler/tree/master/system-kernel-cpp)
