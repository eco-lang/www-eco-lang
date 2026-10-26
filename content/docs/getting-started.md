---
title: "Getting started"
description: "How to install the Eco 0.2.0 nightly release on Linux, macOS or Windows, build the hello world example, and write a first eco/system program."
section: "Introduction"
sectionOrder: 1
order: 2
---

Eco is distributed as one self-contained bundle per platform. The current release is 0.2.0, published as nightly builds. Expect bugs, and expect the IO libraries to change. This page installs it, builds hello world and introduces `eco/system`, the package for programs that run outside the browser.

## Download

Release bundles are on the [GitHub releases page](https://github.com/eco-lang/eco-compiler/releases), under the tag `v0.2.0-nightly`, one per platform:

| Platform | Bundle |
|---|---|
| Linux x86_64 | `.deb` package, or `.zip` / `.tar.gz` (`x86_64-linux-musl`) |
| macOS on Apple Silicon (macOS 15 or later) | `.tar.gz` (`arm64-darwin`) |
| Windows x86_64 | `.zip` (`x86_64-windows`) |

Nightly builds carry a build number in their file names, for example `eco_0.2.0.b<N>.g<hash>_amd64.deb`. Use the name of the file you downloaded in the commands below.

## Install

**Linux, Debian-based.** The `.deb` installs `eco` into `/usr/local`:

```text
sudo dpkg --install eco_0.2.0_amd64.deb
```

**Linux, any distribution.** Unpack the `.zip` or `.tar.gz` into `/usr/local`, or anywhere else and add its `bin` directory to your `PATH`. The Linux bundle is statically linked and carries its own linker, so it needs nothing from the host system.

**macOS.** `eco make` links programs with Apple's linker, so install the Xcode Command Line Tools once if you do not already have them:

```text
xcode-select --install
```

Then download and unpack the bundle with `curl`:

```text
curl -L https://github.com/eco-lang/eco-compiler/releases/download/v0.2.0-nightly/eco-0.2.0-arm64-darwin.tar.gz \
    | sudo tar -xz -C /usr/local
```

Use `curl` rather than a web browser. A browser marks the download as quarantined, and macOS then refuses to run `eco`, because it is not signed by a registered Apple developer. If that happens, clear the mark with `xattr -dr com.apple.quarantine` on the unpacked files.

**Windows.** Unpack the `.zip` and add its `bin` directory to your `PATH`. On Windows, `eco make` links native programs through `clang-cl`, so it needs the Visual Studio 2022 Build Tools and the Windows SDK, with `clang-cl` on the `PATH` (a Developer Command Prompt sets this up).

The rest of this page assumes the bundle is in `/usr/local`; adjust the paths if you put it elsewhere.

## Build and run hello world

The bundle includes an examples project in `share/eco/examples`. Copy it somewhere you can write to, then build and run the hello world program:

```text
cp -R /usr/local/share/eco/examples ~/
cd ~/examples
eco make src/Hello.elm --output=hello
./hello
```

## What `--output` produces

The extension of the output name chooses what Eco builds:

| Output name | Result |
|---|---|
| no extension (e.g. `hello`) | a native executable |
| `.o` | a native object file |
| `.so` | a shared library (Linux) |
| `.node` | a Node addon (Linux) |
| `.js` | JavaScript, as `elm make` produces |
| `.html` | a web page, as `elm make` produces |
| `.mlir` | the compiler's intermediate code, before the back end |

MLIR is written as compact binary bytecode by default. Add `--text-mlir` to get readable text instead. We find this the easiest way to see what the compiler did with a program:

```text
eco make src/Hello.elm --text-mlir --output=hello.mlir
```

## Writing programs with eco/system

`eco/system` is the package for command-line and server programs: files and directories, child processes, standard input, output and error as streams, the terminal, TCP, UDP, TLS and Unix sockets, an HTTP server (with HTTPS, HTTP/2 and WebSockets), and streaming HTTP bodies on top of `elm/http`. It is resolved from the bundle automatically, and `eco install eco/system` adds it to a project's `elm.json`.

A program's `main` is a `Platform.Program` whose flags are a `System.Environment`, which Eco builds when the program starts. `System.simpleProgram` makes a one-shot program that runs a task:

```elm
module Hello exposing (main)

import Stream
import System


main : Platform.Program System.Environment () ()
main =
    System.simpleProgram
        (\env -> Stream.logLine "Hello World!" env.stdout)
```

The environment gives the program its arguments (`env.args`, with the program name first), its standard streams (`Stream.readLine env.stdin` reads a line), the time it started, the platform and CPU architecture, and the path of its executable. A long-running program with a model, `update` and subscriptions is an ordinary `Platform.worker` whose `init` receives the environment.

The examples project has small complete programs to start from:

```text
eco make src/Cat.elm --output=cat && ./cat elm.json
eco make src/Ls.elm --output=ls && ./ls src
eco make src/HttpEcho.elm --output=http-echo && ./http-echo 8080 &
curl -d hello http://127.0.0.1:8080/some/path
```

There are also TCP, UDP, TLS and WebSocket examples (`TcpEcho.elm`, `UdpEcho.elm`, `TlsGet.elm`, `WsEchoServer.elm`, `WsClient.elm`, `WsChat.elm`). For HTTP requests, use `elm/http` as usual. The API of `eco/system` is a port of [gren-lang/node](https://github.com/gren-lang/node) and Gren's `Stream`. Because it is a port, Gren's documentation and examples largely carry over, with lists in place of arrays and `()` in place of `{}`. The package documentation is in the bundle at `share/eco/system/system-kernel-cpp/docs.json`.

## Benchmarks

`examples/benchmarks` is a separate project of compute benchmarks. Build and run it with:

```text
cd ~/examples/benchmarks
eco make src/Bench.elm --output=bench
./bench            # all workloads; ./bench --list shows them
```

With the official `elm` compiler and `node` also installed, `node run.mjs` in the same folder builds every workload with both compilers and prints a table comparing official Elm, Eco's JavaScript output and Eco native. See [Performance](/docs/performance) for our own results.

## Further reading

- [Why Eco](/docs/why-eco) — what Eco is for and why Elm suits native compilation.
- [A tour through the compiler](/docs/tour) — what happens to a program between `eco make` and the executable.
- [System libraries](/docs/system-libraries) — what `eco/system` provides and how it is built.
- The full design document: [System libraries theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/kernels/system-libraries.md)
- Source: [`examples`](https://github.com/eco-lang/eco-compiler/tree/master/examples)
