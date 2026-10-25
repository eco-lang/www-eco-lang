---
title: "Why Eco"
description: "What Eco is, what it lets you build with Elm outside the browser, why Elm is a good language to compile to native code, and where the project stands."
section: "Introduction"
sectionOrder: 1
order: 1
---

Elm is a language for web pages, but very little about it ties it to the browser. Its values never change, its functions have no side effects and its programs never load code at run time. Those are the guarantees a native compiler most wants. Eco takes ordinary Elm and compiles it to native executables, shared libraries and Node addons, and it still produces the same JavaScript that stock Elm does.

> **Background**
> - [Kernel](/docs/glossary#kernel): a built-in function with no Elm body, implemented in the host language.
> - [JIT and AOT](/docs/glossary#jit-and-aot): compiling in memory just before running, or ahead of time to a file.
> - [Write barrier](/docs/glossary#write-barrier): extra code a garbage collector adds to every pointer store.

## What Eco is

Eco is a compiler and runtime for Elm. It is one command, `eco`, used the way you use `elm`: `eco make src/Main.elm --output=main` builds a native program. The name you give the output chooses what comes out. A name with no extension gives an executable, `.o` an object file, `.so` a shared library and `.node` a Node addon, while `.js` and `.html` give exactly what `elm make` would.

The language is unchanged, and we think that matters more than any feature we could add: a new compiler is only useful if existing code runs on it. Eco's front end is a fork of Guida, a port of the official Elm compiler into Elm, so existing Elm source, packages and error messages carry over. We removed Guida's own syntax extensions, so the language Eco accepts is exactly Elm 0.19. Elm's built-in functions, which stock Elm implements in JavaScript, are rewritten in C++ so that unmodified packages from the Elm ecosystem run natively.

## What you can build

Without a browser, an Elm program needs some way to talk to the outside world. Eco ships a package, `eco/system`, that gives Elm programs files and directories, child processes, standard input and output as streams, TCP, UDP, TLS and Unix sockets, an HTTP server with HTTPS, HTTP/2 and WebSockets, and streaming HTTP bodies on top of `elm/http`. The whole of hello world is this:

```elm
module Hello exposing (main)

import Stream
import System


main : Platform.Program System.Environment () ()
main =
    System.simpleProgram
        (\env -> Stream.logLine "Hello World!" env.stdout)
```

That makes room for command-line tools, servers and batch jobs written in Elm. Through the shared library and Node addon outputs, Elm code can also sit inside a larger program written in another language. The largest Elm program Eco builds today is Eco itself: the compiler is about 240,000 lines of Elm, and the `eco` you download is that compiler compiled to native code by an earlier copy of itself.

## Why Elm suits native compilation

Three of Elm's guarantees do most of the work. Each one removes a problem that compilers for other languages spend much of their effort on, which is why, in our view, Elm is an easier language to compile well than its browser origins suggest.

**Values never change.** Once a value exists, nothing writes to it again. A generational garbage collector normally needs a write barrier to notice when an old object comes to point at a young one; OCaml, for example, sends every store into a mutable field through one. In Elm that cannot happen, because the young object did not exist when the old one was written. Eco's collector has no write barrier, and the same fact lets it mark the old generation and promote survivors on background threads without any barrier at all. See [The garbage collector](/docs/garbage-collector).

**Effects go through the runtime.** Elm code does not perform IO. It returns commands and tasks, and the runtime carries them out. Eco's runtime can therefore run all Elm code on one thread that owns the heap, and do the waiting (timers, sockets, HTTP) on other threads that never touch it. See [Scheduler and services](/docs/scheduler-and-services).

**The whole program is known.** There is no dynamic code loading, so the compiler sees every use of every function. Eco makes one copy of each polymorphic function for each type it is used at, which lets it keep integers and floats in machine registers instead of boxing them. It also works out which functions can reach each call through a function value, so that many such calls become direct calls. See [Monomorphization](/docs/monomorphization) and [Lambda-set specialization](/docs/lambda-set-specialization).

## How fast it is

On a suite of 62 benchmark workloads, Eco's native code was 1.58 times faster in total than stock Elm's JavaScript, and it was faster on 51 of the 62. The best cases are tight numeric and bit-twiddling loops: a random number generator went from 295 ms to 18 ms, and CRC-32 from 227 ms to 29 ms. The losses are real too. JSON decoding is about twice as slow as in JavaScript today, and repeatedly appending to a long string is slower. The [Performance](/docs/performance) page gives the wins, the losses and how both were measured.

The suite also found a few places where native results differ from Elm's JavaScript, such as `Bitwise` working on 64 bits instead of 32. The same page lists them.

## Where the project stands

The current release is 0.2.0, published as nightly builds for Linux x86_64, macOS on Apple Silicon and Windows x86_64. It is alpha software. Expect bugs, and expect the IO libraries to change.

Eco is built by Rupert Smith. Work began in November 2025, and the repository has about 2,000 commits since. Besides the compiler, it holds a runtime of about 103,000 lines of C++ (the garbage collector and the scheduler), the C++ kernels, and the tests: around 1,400 end-to-end Elm programs, hundreds of fixtures for the code generator, and eight formal models of the collector's concurrency written in TLA+. Every build checks that the compiler can rebuild itself and get byte-for-byte identical output, which we treat as the strongest single test of the whole stack. See [The compiler compiles itself](/docs/bootstrap).

## Further reading

- [Getting started](/docs/getting-started) — install a release and build your first program.
- [Eco at a glance](/docs/theory) — the five ideas behind the design and the parts of the system.
- [A tour through the compiler](/docs/tour) — one small program followed through every stage.
- [Performance](/docs/performance) — the benchmark results, wins and losses, with caveats.
- The full design document: [Eco theory](https://github.com/eco-lang/eco-compiler/blob/master/THEORY.md)
- Source: [`compiler`](https://github.com/eco-lang/eco-compiler/tree/master/compiler)
