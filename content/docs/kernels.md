---
title: "Kernels"
description: "How eco replaces the JavaScript behind Elm's built-in functions with C++ kernels, so that unmodified Elm packages run natively, and the rules those kernels follow on the eco heap."
section: "The runtime"
sectionOrder: 4
order: 7
---

Elm's built-in functions, from `modBy` to `Json.Decode.decodeString`, are written in JavaScript inside the published `elm/*` packages. A native compiler cannot run JavaScript, so eco has a C++ version of each, with the same behaviour. The Elm side of every package stays exactly as published: the same `Json/Decode.elm` compiles to JavaScript and to native code without a line changed. This article shows what a rewritten kernel looks like and the rules that keep it safe on eco's heap.

> **Background**
>
> - [Kernel](/docs/glossary#kernel): a function with no Elm body, implemented by the platform. Elm source refers to one as `Elm.Kernel.<Home>.<name>`.
> - [ABI](/docs/glossary#abi): the calling convention, meaning how arguments and results are passed between compiled code and the C++.
> - [Boxed and unboxed](/docs/glossary#boxed-and-unboxed): whether a value is a pointer to a heap object or a raw machine number.
> - [eco thread](/docs/glossary#eco-thread): the one thread that runs Elm code and owns the heap.

## One kernel, two languages

Here is elm/core 1.0.5's `modBy`, from its JavaScript kernel:

```javascript
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? __Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});
```

And here is eco's version, from the C++ core kernels (one comment trimmed):

```cpp
long long modBy(long long modulus, long long x) {
    // Implements floored division modulo (result has same sign as modulus).
    // If answer and modulus have different signs, adjust by adding modulus.
    if (modulus == 0) {
        throw std::runtime_error("Elm.Kernel.Basics.modBy: modulus was zero");
    }
    long long answer = modulus == -1 ? 0 : x % modulus;
    if ((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0)) {
        return answer + modulus;
    }
    return answer;
}
```

The logic is the same line for line: take the remainder, and if its sign disagrees with the modulus, add the modulus. A zero modulus crashes in both. The one real difference is `modulus == -1 ? 0`. In JavaScript every number is a double, and `x % -1` is always zero. In C++, `x % -1` on 64-bit integers is undefined behaviour when `x` is the smallest integer, because the matching division overflows; on x86 it traps. Any number modulo −1 is zero, so the guard returns that answer without doing the division. Most of the porting work looks like this: the JavaScript defines what the function means, and the C++ has to reach the same answers without tripping over native arithmetic.

## How an Elm call reaches the C++

The link from Elm to C++ is a name and nothing else. elm/core's `Basics.modBy` is an ordinary Elm function whose body is `Elm.Kernel.Basics.modBy`. The compiler turns each kernel reference into a call to a C function named `<prefix>_Kernel_<home>_<name>`, so this call becomes `Elm_Kernel_Basics_modBy`. A module counts as a kernel module only when its name starts with `Elm.Kernel.` or `Eco.Kernel.` and its package is authored by `elm`, `elm-explorations` or `eco`, as in stock Elm.

Each package still ships its JavaScript kernel files. The native path ignores their bodies but reads their headers, which list the Elm modules each kernel imports, so the files must exist and parse. On the JavaScript target the same files are the implementation. One set of Elm sources therefore serves both targets.

Most C++ kernel modules are a pair of files: plain C++ logic (the `modBy` above) and a thin file of C-linkage exports that convert arguments, call the logic and convert the result. One header declares every exported symbol. Each module builds as its own static library, and the linker takes in only the object files a program references.

We keep the packages stock on purpose, because they belong to the Elm project and a program should not need eco-specific versions of them.

## The compiler owns the call

A kernel call joins two type systems that cannot see each other: Elm's type checker stops at the kernel reference, and C++'s starts at the function definition. Nothing checks the join unless one side owns it, and eco gives it to the compiler. For each kernel a program uses, the compiler writes one declaration into the emitted MLIR with explicit argument and result types, and every call must match it. The lowering to LLVM reads that declaration and infers nothing from the calls. If the back end rebuilt kernel types by looking at how each kernel is used, there would be two derivations of the calling convention, free to drift apart with no error at either end.

Int, Float and Char always cross as raw machine values; everything else, Bool included, crosses as a pointer to a heap value. That creates a problem for kernels that Elm declares generic over `number` or `comparable`. C++ cannot be generic over unboxed values, and boxing every number passed to a kernel would cost an allocation per call. Where a generic kernel is used at a number type, the C++ provides a typed sibling, and the compiler picks it from the types at the call site after [monomorphization](/docs/monomorphization):

```cpp
int64_t Elm_Kernel_Basics_add_Int  (int64_t a, int64_t b);
double  Elm_Kernel_Basics_add_Float(double  a, double  b);
```

The boxed `Elm_Kernel_Basics_add` still exists for call sites whose type is generic even after monomorphization. It reads the heap tag of its first argument, forwards to the right sibling and boxes the result. Addition, list cons, comparison, number-to-string and array push all have siblings.

Some small kernels whose meaning is fixed by the type at the call site, such as list cons, string length, append and the orderings of Int, Float and Char, are replaced by operations in the [eco dialect](/docs/eco-dialect), so the optimisers can fold them with the code around them. Calls across the kernel boundary take a small share of a program's running time, so this buys visibility more than speed. The list higher-order functions such as `List.map` and `List.filter` stay in C++: the C++ versions build each result list once, while the natural Elm versions build intermediate lists, and measurement confirmed the difference.

## Facts in place of a body

To the optimisers a kernel has no body to look inside, and there is no link-time optimisation across the boundary. The compiler keeps one audited table of facts about each kernel instead: what effect a call has, what it allocates, whether it calls back into Elm, and whether two identical calls may be merged. A kernel with no row is treated as conservatively as possible. Every pass asks the same table, so a judgement about a kernel is made once and every pass agrees.

A second table gives selected kernels real types, so the type checker constrains their uses. Each type is a claim about what the C++ does, which can differ from the JavaScript. In JavaScript, `List.fromArray` turns an array into a list. In C++ its one use receives the list that the string-split kernel already returns, so it returns its argument unchanged, and its row says `List a -> List a`. A third set of claims tells [Lambda-set specialization](/docs/lambda-set-specialization) which Elm functions a kernel may call, which lets the compiler turn later calls into direct calls. These are claims about C++ that Elm cannot check, so each row cites the C++ that supports it, and a manifest pins those files by hash. When a cited file changes, the build fails until someone audits the claim again.

## What a kernel may do with the heap

Kernels read and build eco heap values directly through the runtime's helpers. They keep no private model of Elm values and never store a C++ object inside a heap object. The collector would free the heap object without knowing about the C++ memory behind it. JSON shows the choice most clearly: a parsed JSON value is a real Elm custom type on the heap, and the C++ parser's document is thrown away as soon as that value is built. Regular expressions are the one deliberate exception. A compiled regex lives in a C++ side table and the Elm value holds only an integer index into it. Entries are never freed, which matches the JavaScript runtime, which never frees a compiled regex either.

A kernel never looks inside a string or a list either. The runtime stores strings and lists in several forms ([Runtime data structures](/docs/data-structures)), and kernels reach them only through the runtime's operations. The kernel decides what `String.split` means; the runtime decides how the pieces are stored.

The collector is precise and moves young objects, and it cannot see C++ local variables. A kernel that holds heap pointers across an allocation, or across a call back into Elm, first registers them as roots, and reads them back from their rooted slots after every call, because each call may have moved them. A kernel that collects many pointers registers its whole buffer with one record, so rooting costs the same however long the list; a check in the build rejects a root registration inside a loop. A kernel that receives an Elm function calls it through the runtime's generic apply entry, because only the runtime reads the closure header that says how the function takes its arguments ([Closures and calls](/docs/closures-and-calls)).

A kernel never lets Elm code observe a mutation. The collector depends on published values never changing, and a handle onto a mutable store would make Elm code correct only when its uses happened in a strict order the compiler cannot check.

## Tasks describe work; the scheduler performs it

A kernel that returns a `Task` does no input or output when it is called. It allocates a task binding, a heap object holding a callback, and the scheduler runs that callback when the task runs ([Scheduler and services](/docs/scheduler-and-services) follows `Process.sleep` through it). Doing the work at call time would break what a `Task` means. Two tasks built together would run in the order they were built, before the program chose to run either. A read of something that changes, such as the clock, would return the value from when the task was built. And a blocking call would stall the one thread that runs all Elm code.

## Matching JavaScript, and where it doesn't

A *code unit* is one 16-bit piece of UTF-16; a *code point* is a whole Unicode character, which may take two units. Elm's JavaScript kernels treat a string as UTF-16, so in eco a Char is a code unit everywhere. Converting a number to a Char clamps it to 16 bits, and the parser kernels index strings by UTF-16 unit, as JavaScript's `charCodeAt` does. Characters outside the 16-bit range are where differences remain. elm/core's `String.foldl` joins a surrogate pair into one character; eco's version walks code units, so a function folded over an emoji sees two halves rather than one character. Functions that need a browser, such as File, the Debugger and most of Browser, assert when called rather than return something plausible, because a plausible result would make a program that cannot work look as if it does.

## Three libraries

Elm's kernels are one of three C++ kernel libraries, and they stand apart because someone else wrote their contract.

| Library | Symbols | Serves |
|---|---|---|
| Elm's kernels | `Elm_Kernel_…` | The published packages: core, json, bytes, parser, regex, time, url, http, virtual-dom; file and browser mostly assert |
| `eco/kernel` | `Eco_Kernel_…` | The compiler itself: files, console, package downloads, processes, shared variables, the call into the native back end |
| `eco/system` | `Eco_Kernel_…` | eco programs: files, processes, streams, sockets, TLS, an HTTP server, WebSockets, the terminal |

The two eco libraries invent their own APIs and share a design for doing slow work off the eco thread; [System libraries](/docs/system-libraries) describes them.

> **Designs we didn't use.** Forking the `elm/*` packages for native code would mean eco-specific packages for every program and two copies of each package drifting apart. We leave the packages unchanged and rewrite only their kernels.

## Further reading

- [System libraries](/docs/system-libraries) — eco's own IO libraries, built on the same kernel mechanism.
- [Scheduler and services](/docs/scheduler-and-services) — what happens when the scheduler runs a kernel's task binding.
- [Value representation](/docs/value-representation) — which values cross the boundary boxed and which unboxed.
- [Closures and calls](/docs/closures-and-calls) — the generic apply entry every higher-order kernel uses.
- The full design documents: [Kernels theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/kernels/kernels.md) and [Elm kernel theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/kernels/elm-kernel.md)
- Source: [`elm-kernel-cpp`](https://github.com/eco-lang/eco-compiler/tree/master/elm-kernel-cpp)
