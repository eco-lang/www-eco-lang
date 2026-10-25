---
title: "Runtime data structures"
description: "Why an Eco String, List or Bytes value can take one of several heap forms, such as ropes, slices, ASCII strings and chunked lists, how the runtime chooses between them, and what the choice is worth."
section: "The runtime"
sectionOrder: 4
order: 4
---

An Elm `String` has one meaning but, in Eco's heap, several layouts. It may be a flat array, a slice of another string, a rope joining two strings, or a compact all-ASCII form, and a `List` may mix single cons cells with views over dense arrays. The runtime picks a form for every value it builds, choosing between sharing and copying, and the choice only ever changes speed and memory, never results. Kernels and compiled code never see which form they hold, which is what lets the runtime add a form without rewriting the code that uses the type.

> **Background**
>
> - A [kernel](/docs/glossary#kernel) is one of Elm's built-in functions, such as `String.append`; Eco's are written in C++.
> - [Boxed and unboxed](/docs/glossary#boxed-and-unboxed): a list of `Int` can hold its numbers raw, with no pointer per element.
> - A rope is a tree whose leaves are pieces of a string; appending two ropes allocates one node instead of copying.

## One meaning, many layouts

Every form of a type means the same thing: two equal strings in different forms compare equal, order the same way and print the same. Any code that compares two values by their tags first must therefore pass strings and lists on to a comparison of content.

A string's header always records its length in UTF-16 code units, whatever its form. `String.length` and slice arithmetic count in those units, so compiled code can read a length inline without testing the form, and a rope can add its children's lengths whatever their encodings.

The forms can share structure only because no heap object is ever written after it is published (see [The garbage collector](/docs/garbage-collector)). A slice can point into another string's buffer, and a chunk view into an array, because neither will change underneath it.

## Strings

| Form | What it holds | Why it exists | When it is built |
|---|---|---|---|
| UTF-16 leaf | a header and inline UTF-16 code units | the plain, contiguous form | non-ASCII literals; any non-ASCII result |
| Large header | a 16-byte header pointing at a payload that never moves | keeps big payloads out of the copying collector | at the large-object threshold |
| Slice | a base string, an offset and a length | `slice`, `trim` and `uncons` share the buffer instead of copying | slicing more than 128 code units |
| Rope | left and right children, height, leaf count | repeated `++` on flat strings copies quadratically | `append`, `concat`, `join` above 128 Ki code units |
| UTF-8 leaf | a header and inline ASCII bytes | half the memory of UTF-16, and already the bytes UTF-8 output needs | ASCII literals, number conversions, ASCII results, text read from files and the network |
| UTF-8 view | a base, an offset and a byte length | reading a string out of `Bytes` with no copy | decoding long ASCII strings from `Bytes` |

The UTF-8 forms hold only bytes below 0x80. For ASCII text, the index of a code unit equals its byte offset, so `length`, `slice` and character access stay constant-time with no index translation, byte order equals UTF-16 order so comparison can use `memcmp`, and the bytes are already valid UTF-8, so a string moves between `Bytes` and `String` without a copy in either direction. Text with anything outside ASCII stays UTF-16 and behaves exactly as it would without these forms.

Two rules keep slices shallow. A slice's base is always a leaf or a large header, never another slice, so slicing a slice adds the offsets and points at the deeper base. And a short slice is copied rather than shared, because a short slice that is kept would otherwise hold a large buffer alive.

### How `append` and `slice` choose

In outline (checked against the runtime's string operations):

```text
append(a, b):
  if a or b is empty: return the other                # no new object
  n = len(a) + len(b)
  if n > 128 Ki units: return a rope node (a, b)
  if a and b are UTF-8: return an ASCII leaf of bytes(a) ++ bytes(b)
  data = units(a) ++ units(b)
  if every unit < 0x80: return an ASCII leaf(data)    # "chain healing"
  return a UTF-16 leaf(data)

slice(s, start, end):
  empty range -> ""; whole range -> s
  if k <= 128 units: copy (an ASCII leaf if the content is ASCII)
  leaf or large header: a slice of s
  slice: a slice of s.base at s.offset + start         # no slice chains
  rope:  recurse into the child holding the range, or join two sub-slices
```

Ropes appear only above the flatten limit, so everyday strings stay flat and kernel loops, UTF-8 encoding and the parser get one contiguous buffer. The "chain healing" line narrows an ASCII result back to UTF-8 even when an input was UTF-16. Without it, one UTF-16 operand in a chain of appends would widen every result after it.

`concat` and `join` build a balanced rope in one pass with a merge stack. Folding left with `++` would build a rope that leans to one side, and walking that is quadratic.

### The empty string

`""` is not a heap object at all. It is the shared Empty word, the same word as `[]`, `Nothing`, `()` and `{}` ([Value representation](/docs/value-representation) gives the encoding). Every constructor returns that word for a length of zero, so no zero-length heap string exists and equality can treat the word as the only empty string.

## Lists

`x :: rest` always allocates a 24-byte cons cell: a header, the head, and a pointer to the tail. Functions that build a whole list at once may instead produce a chain of *chunk views*, each over a dense array called a backing, and a list's spine can mix cells and views freely (from the runtime's heap definitions):

```cpp
typedef struct {
    Header header;    // Header.unboxed bits 1:0 = element kind (mirror of backing).
    HPointer backing; // -> Tag_ListBacking.
    u32 offset;       // First live index in the backing.
    u32 len;          // Total logical length of this list value (>= 1).
    HPointer next;    // Rest of the spine after this chunk's run.
} ConsChunk;

typedef struct {
    Header header;  // header.size = capacity (element count); unboxed bits 1:0 = kind.
    u32 hd;         // Frontmost claimed slot (v1: always 0).
    u32 _pad;
    Unboxable elems[];
} ListBacking;
```

A view's `len` is the length of the whole list from that view onward, not the length of its own run, so `List.length` can stop at the first view it meets. A backing has one element kind for all its slots. The collector can scan a backing from its header alone, and a backing of raw `Int`s is never scanned at all.

We keep `::` as a cell because chunking it would cost more than it saves: a view is larger than a cell, and every compiled `x :: rest` pattern would have to allocate a view for the tail. The savings come from bulk builders. The compiler rewrites elm/core's `reverse`, `append`, `concat`, `take` and `drop` into kernel calls, and loops that accumulate with `::` into pushes onto a scratch stack that one runtime call turns into a list. A batch becomes chunk views only when it has at least four elements of the same kind and fits comfortably in the nursery.

Building a chunk chain has to respect the collector. With no write barrier, a backing that was promoted to the old generation before it was filled would end up holding young pointers that nothing records. For that reason, every backing and view is created with a *builder* bit set, which keeps it young; the builder fills the chain with no allocation in between and clears the bit before the list escapes.

Chunked lists are one switch for the whole program, because compiled code reads list cells inline. Compiled code that knew only cons cells would misread a view returned by a kernel. In a program compiled for chunks, compiled head and tail projections test for a cell and call the runtime for a view.

## Bytes

`Bytes` has three forms: a flat buffer, a slice of one, and a large buffer split from its header like a large string. Empty `Bytes` is the shared Empty word. Strings and `Bytes` meet without copying in two places: decoding ASCII bytes as a string returns a UTF-8 view over the source buffer, and encoding a UTF-8 string is a `memcpy`. Compiled encoders and decoders that work on buffers directly are the subject of [Bytes fusion](/docs/bytes-fusion).

## Who may look inside

Outside the runtime, strings are reached only through a small interface: length, character access, conversion, a call that returns a flat UTF-16 buffer, and a test for UTF-8 with access to its bytes. Lists are reached through cursors and list builders, and `Bytes` through a call that returns a pointer and a length. Because kernels read strings only through these functions, a new string form changes kernels only where they create strings. Nothing checks this boundary mechanically. Review keeps it, along with tests that run every operation on every form.

## What chunked lists are worth

On the compiler compiling itself, chunked lists cut cons cells by roughly 50%, all objects by nearly 5% and list spine bytes by approximately 25%. Wall time is about the same with and without them, but minor-collection time and peak memory are lower with them, and we think that is reason enough to leave them on by default. The result fits a general pattern on this workload: cutting allocation does not move wall time, but cutting promotion into the old generation does.

> **Designs we didn't use.** *Promotion-time* list chunking would pack runs of cons cells into dense chunks as they survive into the old generation. It needs long runs to pay off, but the cons cells that survive come in short runs, most of them a single cell. Measured, the compile ran slower, so we removed it.

## Further reading

- [The garbage collector](/docs/garbage-collector) — builders, the large-object space and why published objects never change.
- [Value representation](/docs/value-representation) — the Empty word and element kinds.
- [Kernels](/docs/kernels) — the C++ functions that build these values.
- [Bytes fusion](/docs/bytes-fusion) — encoders and decoders compiled straight to buffer reads and writes.
- The full design document: [Runtime data structures theory](https://github.com/eco-lang/eco-compiler/blob/master/design_docs/theory/runtime/data-structures.md)
- Source: [`runtime/src/allocator`](https://github.com/eco-lang/eco-compiler/tree/master/runtime/src/allocator)
