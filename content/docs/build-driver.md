---
title: "The build driver"
description: "How Eco's build driver takes a project on disk to a finished compile — caching per module, recompiling only what an interface change forces, and handing the program to the JavaScript or native back end — while running unchanged on stock Elm, JavaScript and native hosts."
section: "The compiler"
sectionOrder: 2
order: 10
---

The build driver is the part of the compiler that decides what has to be rebuilt, and leaves how to compile it to the compiler's phases. It is Elm code that has to run on three hosts: built by stock Elm, as JavaScript, and as native code. And a self-compile is large enough that peak memory decides whether it finishes. Those two facts shape most of its design.

## How a build runs

![How the build driver runs a build](/images/docs/build-driver-pipeline.svg)

A build arrives from the command line or as a JSON request from a tool that embeds the compiler. The driver locks the project, reads its settings, then passes through three stages.

**Project details.** This is the cached record of everything outside the project's own modules: the solved dependency versions, the built packages, and the last known state of each local module. It is rebuilt when the settings change, or when the build asks for a different compiled form: typed graphs for MLIR and native output, untyped graphs for JavaScript. A build writes only the form its output needs, so a cached module counts as reusable only if the artifact for the current form exists.

**Crawl and compile.** The driver follows imports outward from the entry modules and starts a task per module. Each task waits on the results of the modules it imports and starts as soon as they are ready, so independent modules compile in parallel without a separate scheduler. Reuse follows Elm's own scheme, with early cutoff on interfaces:

```text
source changed since last build              -> compile
a dependency's interface changed since then  -> recompile
cached, but this form's artifact is missing  -> recompile
otherwise                                    -> reuse
after a compile, interface unchanged         -> keep the old interface time
```

The last line is what makes editing a function body cheap: if its type does not change, the modules that import it are not rechecked.

**Generation.** For JavaScript the driver hands the untyped graphs to the Elm generator ([JavaScript output](/docs/javascript-output)). For MLIR or native output it loads every package's typed artifacts, runs the whole-program steps, and writes MLIR. For a native executable it then calls the C++ back end inside the same process to lower and link. Only the per-module half is incremental. Monomorphization, global optimization and code generation need the whole program, so they run in full on every build.

## One collection before linking

By the time the front end hands over to the back end, most of its heap is garbage, but the runtime does not return freed memory to the operating system on its own. So just before the native back end starts, the driver asks the runtime for one major collection that hands freed memory back. That only helps if nothing still points at the dead data, so the driver is careful not to hold any: progress messages carry results without their payloads, per-module slots are dropped after their last read, and MLIR is written in batches.

On the native self-compile to an executable, this work cut peak memory by about a third, and moved the peak from the back end to the front end's type checking. Most of that is the one collection: at that point only a few megabytes are still live, and the collection takes resident memory from several gigabytes to under one in a fraction of a second.

## The cache on disk

Every cached file lives under a directory named after the compiler version, so a compiler never reads another version's cache, and writes go to a temporary file that is renamed into place, so a crash never leaves half a file. Typed graphs store each distinct string and type once, because the same types repeat throughout a module ([The front end](/docs/front-end)).

## Three hosts, one source

The compiler is first built by stock Elm, then builds itself as JavaScript, then as native code, and fixed-point checks compare what successive compilers produce ([The compiler compiles itself](/docs/bootstrap)). So all three hosts must behave alike. Stock Elm cannot touch files or start processes. Every host facility (files, processes, the console, HTTP, the garbage collector) is therefore one Elm module that exists twice with the same exports. One version is a kernel module with JavaScript and C++ implementations. The other is plain Elm for the stock-Elm build, and sends each operation as an HTTP request to a local Node handler that performs it. A build picks one version through its source directories.

Errors cross that boundary as a plain triple of a tag, a path and a message, because neither the Node handler nor kernel code can build an Elm record whose layout the compiler decides.

> **Designs we didn't use.** We also tried collections at several boundaries between front-end phases. They lowered resident memory between phases, but the peak had already happened, in type checking, before the first of them, so they cost time without lowering the peak, and we removed them.

## Further reading

- [The compiler](/docs/compiler) — the phases the driver calls, and the typed and erased paths.
- [JavaScript output](/docs/javascript-output) — the back end for `.js` and `.html` builds.
- [The backend](/docs/backend) — what the in-process native handoff runs.
- [The compiler compiles itself](/docs/bootstrap) — why the driver must run on three hosts.
- The full design document: [Build driver theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/compiler/build-driver.md)
- Source: [`compiler/src/Builder`](https://github.com/eco-lang/eco-compiler/tree/master/compiler/src/Builder)
