---
title: "Performance"
description: "Measured run times of Eco's native code against stock Elm's JavaScript, including the workloads where Eco is slower, plus how fast the compiler builds itself and how short its garbage-collector pauses are, with how each was measured."
section: "Introduction"
sectionOrder: 1
order: 6
---

On 62 benchmark workloads, Eco's native code is 1.58 times faster in total than stock Elm's JavaScript, and faster on 51 of them. The gap is widest in tight numeric and bit-level loops, where native code is several times faster and sometimes more than ten times. Eco is slower than JavaScript on JSON and on some string-heavy work. This page shows both ends, how fast the compiler builds itself, and how short the collector's pauses are.

> **Background**
> - [JIT and AOT](/docs/glossary#jit-and-aot): the JavaScript engine compiles Elm's output just in time; Eco compiles ahead of time.
> - [Nursery and eden](/docs/glossary#nursery-and-eden): the young part of the heap, collected often by a short pause.
> - [Fixed point](/docs/glossary#fixed-point): the compiler rebuilding itself and getting identical output.

## Run time against stock Elm

The suite lives in the compiler repository under `examples/benchmarks`, and you can run it yourself (see [Getting started](/docs/getting-started)). It has 62 workloads. Seventeen are the original set: recursion, allocation, lists, `Dict`, floats and sorting, plus standard programs such as nbody, spectral-norm and fannkuch-redux. The other 45 cover `Dict`, `Set`, `Array`, `String`, `Bitwise`, `elm/bytes`, `elm/json` and `elm/parser`, using standard benchmarks where they exist (the Benchmarks Game, plb2, kostya/benchmarks, nativejson-benchmark, Embench, FIPS test vectors). Every workload checks its own result, and each one's default size takes at least 200 ms on stock Elm.

These are medians in milliseconds, with Eco native measured from the release bundle. The first group is the best cases, the second is typical, and the third is every workload of the 45 where Eco was slower. We show the losses in full because a total hides them, and they are where the work remains.

| Workload | What it stresses | Elm (JS) | Eco native | Speed-up |
|---|---|---:|---:|---:|
| prng | xorshift random numbers, `Bitwise` | 294.7 | 18 | 16x |
| bytes-static | `elm/bytes` decoding, fused | 244.9 | 20 | 12x |
| crc32 | table-driven CRC-32, `Bitwise` | 227.2 | 29 | 7.8x |
| popcount | bit counting, `Bitwise` | 226.4 | 35 | 6.5x |
| sha256 | SHA-256 hash chain | 221.3 | 37 | 6.0x |
| matmul | matrix multiply, `Array` | 232.6 | 60 | 3.9x |
| word-freq | word counts, `Dict` | 262.3 | 111 | 2.4x |
| dict-int | `Dict` with `Int` keys | 278.3 | 141 | 2.0x |
| sudoku | constraint search, `Set` | 254.5 | 172 | 1.5x |
| json-parser | a JSON parser in `elm/parser` | 223.5 | 229 | 0.98x |
| csv-parser | a CSV parser in `elm/parser` | 210.7 | 257 | 0.82x |
| string-append | repeated `++` onto a long string | 248.5 | 295 | 0.84x |
| csv-split | CSV with `String.split` | 230.6 | 314 | 0.73x |
| json-shapes | decoding nativejson-benchmark-like documents | 230.0 | 335 | 0.69x |
| json | decoding coordinates (kostya/benchmarks) | 250.1 | 526 | 0.48x |
| json-decoders | wide and deep decoder combinators | 237.2 | 537 | 0.44x |

Eco native is weakest on JSON. Every JSON workload except encoding is slower than in JavaScript, and we have not yet profiled why. A ninth slow workload, json-dict, is left out of the table because the bundle measured predates a fix for it.

`elm/bytes` shows one of Eco's own optimisations at work. The workloads bytes-static and bytes-dynamic do the same decoding, but only the first is written in the shape that [Bytes fusion](/docs/bytes-fusion) recognises. On native code the fused version is 2.6 times faster (27 ms against 71 ms in the same development build), while on JavaScript the two take the same time.

## How fast the compiler builds itself

The compiler is the largest Elm program we have, about 240,000 lines, so the time the native compiler takes to compile its own source is our main measure of compile speed. These figures move from week to week and from run to run, so we give them only roughly.

The native self-compile from Elm to MLIR takes about a minute and peaks at about 6 GB of memory. That is several times faster than before the work on the front end, the specialization passes and the collector, and two changes account for most of it. The cached, typed module files store each distinct string and type once, which makes them about fifty times smaller and halves the time spent parsing, checking and building modules. The compiler also allocates much less, so far less data survives into the collector's old generation.

The backend then turns that MLIR into a native executable in about twenty seconds on a machine with many cores. Most of that speed comes from avoiding repeated linear symbol lookups and from compiling the program in partitions that LLVM handles in parallel ([The backend](/docs/backend)).

## Collector pauses

A *pause* is a stretch during which Elm code is stopped while the collector works; *collection time* is all the work the collector does, paused or not. Keeping pauses short means moving work off the eco thread. On the self-compile, the longest pause is under 100 ms, and only 1 in 100 lasts longer than about 20 ms. That is because the old generation is marked on background threads, minor collections run in parallel and survivors are promoted concurrently. A collector doing all of this on the eco thread would stop the program for a full collection of the old generation, which on the same compile takes nearly three seconds.

None of this needs a write barrier, because an Elm object can never point at a younger one. Concurrent collectors in other runtimes, such as the JVM's, rely on barriers to keep the mutator and the collector consistent; Eco's relies on immutability instead. See [The garbage collector](/docs/garbage-collector) and [Model-checking the collector](/docs/concurrency-models).

## How we measure, and the caveats

- **Run-time benchmarks.** Each workload runs on each backend in a process of its own, with 3 warm-up runs and then 11 timed runs, and we report the median. Eco times itself with `Time.now`, which has a resolution of 1 ms; stock Elm is timed from Node with `process.hrtime`. The fastest workloads (prng at 18 ms) therefore carry about 5% timing granularity. The 1.58x total includes json-dict, whose check failed on that bundle.
- **Compile-time and pause figures** come from the compiler compiling itself on one Linux workstation. The machine drifts (an unchanged binary has measured 10% apart in a single session), and the compiler's own source changes between measurements, so treat them as rough.
- **What we do not publish.** We have no fair comparison of the native compiler against the JavaScript-hosted compiler, because they have never been measured on the same engine and date. We make no claim about it.

## Where native results differ from Elm

Running the same programs on both backends also found places where Eco's native code gives a different answer from Elm's JavaScript. All of these are still open:

- **`Bitwise` works on 64 bits.** Elm defines it on 32-bit integers, so `Bitwise.shiftRightZfBy 0 -1` is 4294967295 in Elm and -1 natively. Hashing and crypto code that relies on 32-bit wrap-around gives wrong results. Fixing it would change the meaning of every Eco program, the compiler included, and it is not decided.
- **A `Char` is one UTF-16 code unit.** Characters outside the Basic Multilingual Plane, such as emoji, come out of `String.toList` as two surrogate halves rather than one `Char`.
- **`String.toUpper` and `Char.toUpper` change ASCII letters only.** Elm also maps letters such as é to É.
- **`Json.Encode.object` writes fields sorted by key.** Elm keeps the order given, so anything that depends on field order, including byte-for-byte output, differs.

## Further reading

- [Optimisations](/docs/optimisations) — what Eco does to get these numbers.
- [The garbage collector](/docs/garbage-collector) — how the barrier-free collector works.
- [Bytes fusion](/docs/bytes-fusion) — the optimisation behind the bytes-static result.
- [Why Eco](/docs/why-eco) — the project in brief.
- The full design document: [Garbage collector theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/runtime/garbage-collector.md)
- Source: [`examples/benchmarks`](https://github.com/eco-lang/eco-compiler/tree/master/examples/benchmarks), [`benchmarks`](https://github.com/eco-lang/eco-compiler/tree/master/benchmarks)
