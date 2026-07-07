---
title: "The Big Machine is Back"
description: "How modern hardware and simpler architectures are shaping eco."
section: "Compilers"
image: /images/xeon6.jpg
sectionOrder: 1
order: 2
---

## The hardware changed

Modern servers are extraordinarily capable. They offer large core counts, vast memory, fast local storage, and network interfaces that would once have belonged in a supercomputer. John O’Hara, inventor of AMQP, argues in "Uncomplex" that software architecture has failed to keep pace with hardware.

[InfoQ: John O'Hara presents Uncomplex: Modern Hardware for Better Software](https://www.infoq.com/presentations/hardware-software-succes/)

Many applications are still designed as if machines were small, unreliable, and likely to fail at any moment. Even modest systems are split into fleets of services and surrounded by containers, orchestration platforms, gateways, queues, tracing systems, and distributed databases. That complexity is sometimes necessary but often it is not. Frequently we see systems built with the assumption that this complexity will be required that do not really need it, or even suffer because of it in terms of their cost and time to develop and runtime performance.

## Distribution has a cost

A network boundary is not just an architectural line. It introduces serialisation, latency, retries, timeouts, versioning, partial failure, deployment coordination, and observability requirements. Microservices can provide useful isolation between teams and systems. But they are frequently adopted before the workload or organisation requires them.

Many business applications can now serve substantial workloads from one large machine. Keeping more of the system together can make it faster, cheaper, and easier to understand. The principle is not that everything must run on one server. It is that distribution should be introduced because the problem requires it, not because the architecture assumes it.

## A single process still needs structure

Putting an application into one executable does not automatically make it simple. A large program can become as tangled as a badly designed distributed system. The difference is that structure inside a program can be enforced by the language and compiler using types.

Types can define precise boundaries between components. Opaque data can prevent one part of the system from depending on another part’s representation. Pure functions can separate business logic from effects. Messages can coordinate independent parts of the program without exposing shared mutable state.

These boundaries can be checked continuously by a compiler. They do not require a network protocol, a deployment pipeline, or a monitoring system to hold them together.

As a language with a strong type system, this makes Elm interesting.

## Elm without the browser boundary

Elm is well suited to building software from strongly separated components. Its type system makes interfaces explicit. Pure functions make behaviour easier to reason about. Effects remain visible at the edges of the application. Compiler errors expose disagreements between components before the program runs.

But Elm’s mainstream compiler and ecosystem are primarily designed for browser applications. eco asks what this programming model could do on modern native hardware. The goal is to retain Elm’s semantic discipline while targeting native executables, servers, command-line tools, and backend systems.

## The big machine

A modern server is not just a faster old server. It is a network of cores, caches, memory channels, storage devices, and accelerators contained within one machine. Although we do not often think of it this way, the CPU itself is a network of cores, just not the more familiar Ethernet and IP protocol network.

Software that respects that structure can avoid a great deal of unnecessary data movement. Components can communicate through memory rather than remote calls. Working data can remain close to the processors using it. The compiler can optimise representations and calls across the whole application.

This is one of eco’s intended targets: large machines running compact, carefully structured programs.

Not every system belongs on one machine. Geographic distribution, multi-site replication, team ownership, security boundaries, and extreme workloads can all justify separate services, but many systems should be able to remain simple for much longer than they do today.

## So what does this look like ?

eco is not only an attempt to compile Elm to native code. It is an attempt to make a particular style of system practical:

* high-level application code;
* strong compile-time boundaries;
* actor model with cpu core affinity;
* efficient native execution;
* fewer operational components.

**"wheels on the bus" architecture**

![Wheels on the bus architecture](/images/elm-actors.svg)

In his Uncomplex talk John describes a "wheels on the bus" architecture. This is one where we have a fixed actor topology, no more than one actor per CPU core, passing events (or pointers to events) between actors using lock-free ring buffers (the wheels).

eco imagines a multi-threaded Elm with parallel actors. Permitting strict type-enforced domain modelling in a high level language to be built elegantly yet capable of massive throughput and scaling on todays high core count servers.

John O’Hara’s challenge is to engineer for this decade rather than the last one. eco is one answer to that challenge: a compiler for building simpler software on powerful machines.
