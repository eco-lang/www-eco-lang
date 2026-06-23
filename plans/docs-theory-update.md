# Plan: Update Docs from Updated Theory

## Context

The theory has been updated in `eco-runtime/THEORY.md` and 17 files under `eco-runtime/design_docs/theory/`. The website has 7 existing docs in `content/docs/`. This plan covers adding new docs for uncovered theory areas and updating existing docs to reflect changes.

## Theory Coverage Analysis

### Currently covered by existing docs

| Theory file | Covered by |
|---|---|
| pass_post_solve_theory.md | type-system.md |
| pass_typed_optimization_theory.md | type-system.md |
| pass_monomorphization_theory.md | monomorphization.md |
| staged_currying_theory.md | staged-currying.md |
| pass_global_optimization_theory.md | staged-currying.md |
| pass_mlir_generation_theory.md | code-generation.md |
| pass_eco_to_llvm_theory.md | code-generation.md |
| pass_joinpoint_normalization_theory.md | code-generation.md |
| pass_eco_control_flow_to_scf_theory.md | code-generation.md |
| pass_rc_elimination_theory.md | code-generation.md |
| pass_undefined_function_theory.md | code-generation.md |
| pass_type_table_theory.md | code-generation.md |

### NOT covered by any existing doc

| Theory file | Lines | Topic |
|---|---|---|
| heap_representation_theory.md | ~370 | Four representation models (ABI, SSA, Heap, Logical) |
| kernel_abi_theory.md | ~300 | Three ABI modes for C++ kernel functions |
| bytes_fusion_theory.md | ~300 | Bytes.encode/decode fusion to BF dialect |
| typed_closure_calling_theory.md | ~290 | PAP wrapper elimination, ABI cloning |
| mlir_verification_theory.md | ~300 | MLIR verification infrastructure |

---

## New Docs (4 pages)

### 1. `content/docs/heap-representation.md` — Architecture section, order 3

**Source**: heap_representation_theory.md, relevant parts of THEORY.md object layout
**Frontmatter**: section "Architecture", sectionOrder 1, order 3

This is a foundational concept currently scattered across monomorphization (unboxing rules) and memory model (object layout). Centralizing the four representation models clarifies the mental model.

**Content outline** (~250 lines):
- **Why four models?** — Values look different at function boundaries, in SSA registers, in heap storage, and in Elm semantics
- **The four models**: ABI representation (function boundaries — what callers/callees see), SSA representation (MLIR operands — i64, f64, !eco.value), Heap representation (runtime object fields — boxed vs unboxed), Logical representation (Elm semantics — the programmer's view)
- **Boundaries and transitions** — Boxing/unboxing at ABI↔SSA boundary, projection at SSA↔Heap boundary, construct/project for Logical↔Heap
- **Unboxing rules** — Only Int, Float, Char are unboxed in heap fields. Bool is always boxed (True/False are embedded pointer constants). String and compounds are always boxed.
- **The unboxed bitmap** — How containers mark which fields are raw values vs pointers, used by both codegen and GC
- **Embedded constants** — How Unit, True, False, Nil, EmptyString avoid heap allocation (cross-link to memory model)
- Cross-links: [Memory Model § Object Layout], [Monomorphization § Unboxing Rules], [Code Generation § EcoToLLVM]

### 2. `content/docs/kernel-functions.md` — Compilation section, order 4

**Source**: kernel_abi_theory.md, THEORY.md § Kernel Functions
**Frontmatter**: section "Compilation", sectionOrder 2, order 4

Kernel functions are a cross-cutting concern affecting PostSolve, monomorphization, and code generation. Currently only mentioned in passing.

**Content outline** (~200 lines):
- **What are kernel functions?** — C++ runtime primitives (List.map, Basics.add, String.append, etc.) called from compiled Elm code
- **Type inference** — How PostSolve discovers kernel types via alias seeding and usage inference (cross-link to type-system.md)
- **The three ABI modes**:
  - `UseSubstitution` — Monomorphic kernels use typed parameters directly (e.g., `String.length : String -> Int`)
  - `PreserveVars` — Polymorphic kernels receive boxed `eco.value` for type variables (e.g., `List.cons : a -> List a -> List a`)
  - `NumberBoxed` — Number-polymorphic kernels receive boxed numbers and dispatch by runtime tag (e.g., `Basics.add : number -> number -> number`)
- **Boxing at call boundaries** — Where boxing/unboxing happens when calling kernels, with examples
- **C++ implementation patterns** — What kernel functions look like on the C++ side
- Cross-links: [Type Preservation § Kernel Type Inference], [Code Generation § EcoToLLVM], [Heap Representation § ABI Representation]

### 3. `content/docs/bytes-fusion.md` — Compilation section, order 5

**Source**: bytes_fusion_theory.md
**Frontmatter**: section "Compilation", sectionOrder 2, order 5

A novel domain-specific optimization unique to Eco.

**Content outline** (~200 lines):
- **The problem** — Elm's `Bytes.encode` and `Bytes.decode` use an interpreter-style kernel: build a data structure describing the operation, then walk it at runtime. This has overhead from intermediate allocations and dispatch.
- **Why fusion is possible** — The `elm/bytes` API is an opaque DSL builder. Encoders and decoders are constructed via a chain of combinator calls (`Bytes.Encode.unsignedInt8`, `Bytes.Encode.sequence`, etc.) that build a description of the operation. Because the API is opaque — user code cannot inspect or destructure encoder/decoder values — the compiler is free to replace the entire construction-then-interpretation pipeline with direct operations. The DSL structure is visible at compile time even though it's sealed at runtime.
- **The solution: fusion** — Recognize encode/decode patterns at compile time and lower them directly to cursor-based operations, skipping the interpreter entirely.
- **The BF dialect** — Custom MLIR dialect for byte operations. Cursor-based model: allocate a buffer, advance a cursor, read/write at cursor position.
- **Two phases**: Reification (pattern-match Elm AST into encoder/decoder node trees) and Emission (generate fused MLIR operations from the node trees)
- **Static width computation** — When encoder size is known at compile time, allocate exact buffer. When dynamic, use growth strategy.
- **Benefits** — Zero intermediate allocations (no encoder/decoder data structures built at runtime), no dispatch overhead (direct read/write ops), enables LLVM to further optimize the generated byte operations, buffer size known at compile time for many common patterns
- **Example**: Show a Bytes.encode pipeline and its fused output
- Cross-links: [Code Generation § ECO Dialect], [Overview § Compilation Pipeline]

### 4. `content/docs/typed-closure-calling.md` — Compilation section, order 6

**Source**: typed_closure_calling_theory.md
**Frontmatter**: section "Compilation", sectionOrder 2, order 6

An important optimization in the EcoToLLVM lowering that eliminates wrapper functions for closures and partial application. Standalone page since it's substantial (~290 lines of theory) and code-generation.md is already the largest doc.

**Content outline** (~200 lines):
- **The problem** — Generic evaluator wrappers for closures prevent inlining and add overhead. In a naive implementation, every closure call goes through a generic wrapper that unpacks captured values from a `void*[]` array and calls the underlying function. This is an opaque barrier to LLVM optimization.
- **The solution: two entry points** — Generate a fast clone (explicit typed capture parameters for direct calls) and a generic clone (taking a closure pointer for indirect calls). When the closure structure is statically known, the fast clone is called directly.
- **Homogeneous vs heterogeneous call paths** — When all branches of a case/if produce closures with the same structure, the compiler can use the homogeneous path (unpack captures, call fast clone directly). When structures vary, the heterogeneous path passes the closure pointer.
- **ABI cloning** — Functions are cloned into direct and indirect entry points as needed. The direct entry point takes captures as typed parameters. The indirect entry point takes a closure pointer and unpacks.
- **Inline papExtend** — The `eco.papExtend` operation is lowered inline (not as a runtime call), enabling LLVM to optimize saturated calls. Float arguments/results require `i64`↔`f64` bitcasts since closures store all values as `i64`.
- **Benefits** — Direct typed calls enable inlining, closures with known structure avoid pointer indirection, LLVM sees through the call chain
- Cross-links: [Code Generation § Closures], [Staged Currying § Kernel Functions], [Heap Representation § ABI Representation]

---

## Updates to Existing Docs (5 pages)

### 5. `content/docs/overview.md` — Minor updates

- **Pipeline diagram**: Add "Bytes Fusion" as an optional optimization between MLIR Generation and ECO Dialect Lowering. Add "CheckEcoClosureCaptures" to ECO Dialect Lowering passes.
- **MLIR Generation and Lowering subsection**: Mention bytes fusion (with cross-link to new doc) and typed closure calling (with cross-link to new doc).
- **Design Philosophy — "Start simple, prove correctness"**: Expand with mention of MLIR verification infrastructure (three layers: inline verifiers on operation creation, dedicated verification passes, Elm-side property tests against generated AST). Source: mlir_verification_theory.md.
- **New doc cross-links**: Add references to Heap Representation, Kernel Functions, Bytes Fusion, and Typed Closure Calling in relevant pipeline descriptions.

### 6. `content/docs/staged-currying.md` — Significant update

The theory now describes a **graph-based constraint solver** rather than the simpler "collect stagings, pick majority" algorithm the current doc presents.

Changes needed:
- **Replace "The Majority Staging Algorithm" section** with an accessible high-level explanation of the graph-based approach:
  - Every closure is a "producer" of a function value; every slot expecting a function is a "consumer"
  - The constraint graph connects producers to their consumer slots — if a closure flows into a call site, they're linked
  - Connected components (found via union-find) must agree on a staging signature
  - Within each component, majority voting picks the canonical segmentation
  - Non-conforming producers are eta-wrapped to match
  - Keep the explanation conceptual — no ProducerId/SlotId type definitions or union-find implementation details
- **Update GlobalOpt phases** to match current structure:
  - Phase 1 → "Build staging graph" (construct constraint graph connecting producers to consumer slots)
  - Phase 2 → "Solve staging" (union-find to group connected components, majority voting within each group)
  - Phase 3 → "Rewrite with staging" (eta-wrap non-conforming producers)
- **Keep the Branch Problem section** — it's still valid and motivates the solver
- **Keep Kernel Functions section** — still relevant, add cross-link to new kernel-functions.md
- **Brief mention of the Staging Subsystem modules** — one paragraph noting the separation into GraphBuilder, Solver, Rewriter without diving into internal types

The overall narrative stays the same (why staging matters, the branch problem, eta-wrapping) but the mechanism section gets updated from "simple majority" to "constraint graph solving."

### 7. `content/docs/code-generation.md` — Moderate updates

- **Update "Lowering to LLVM" section**:
  - Add CheckEcoClosureCaptures to the list of verification passes (validates closure capture consistency)
  - Add "Inline papExtend" note: the eco.papExtend operation is lowered inline rather than as a runtime call
  - Mention float arguments require i64↔f64 bitcasts in closures
- **Add Bytes Fusion cross-link**: Brief mention under ECO Dialect or MLIR Generation, linking to new bytes-fusion.md
- **Add Typed Closure Calling cross-link**: Brief mention in the Closures section or EcoToLLVM section, linking to new typed-closure-calling.md
- **Add cross-link to Heap Representation**: From the Type Mapping table, link to heap-representation.md for the full representation model

### 8. `content/docs/monomorphization.md` — Minor updates

- **Add cross-link to Kernel Functions**: In the "Constraints" section where `CEcoValue` and `CNumber` are discussed, reference the new kernel-functions.md for full kernel ABI details
- **Add cross-link to Heap Representation**: From "Unboxing Rules" section, link to heap-representation.md which now centralizes the four representation models
- **Check for new MonoType variants or layout changes** against pass_monomorphization_theory.md — update if any new types or layout fields have been added

### 9. `content/docs/memory-model.md` — Minor updates

- **Add cross-link to Heap Representation**: From "Object Layout" section, reference heap-representation.md for the compile-time perspective on how these layouts are computed
- **Check against THEORY.md runtime sections** for any changes to heap configuration, address space partitioning, or embedded constants

---

## No Changes Expected

- **type-system.md** — Reviewed against pass_post_solve_theory.md (232 lines) and pass_typed_optimization_theory.md (282 lines). The existing doc appears comprehensive and consistent with the theory. No substantive updates needed unless the theory files contain new details not present when the doc was written.
- **garbage-collection.md** — The GC theory is in THEORY.md (not a separate theory file). The runtime sections appear stable. No updates expected.

---

## Implementation Order

1. Create `heap-representation.md` (new, Architecture)
2. Create `kernel-functions.md` (new, Compilation)
3. Create `bytes-fusion.md` (new, Compilation)
4. Create `typed-closure-calling.md` (new, Compilation)
5. Update `staged-currying.md` (significant — graph-based solver)
6. Update `code-generation.md` (verification passes, cross-links)
7. Update `overview.md` (pipeline, verification, cross-links)
8. Update `monomorphization.md` (cross-links)
9. Update `memory-model.md` (cross-links)
10. Build and verify (`npm run build`)

---

## Resolved Decisions

1. **Staged currying depth**: Accessible high-level. Explain the constraint graph conceptually (producers, consumers, connected components, majority voting) without diving into internal types (ProducerId, SlotId) or union-find implementation mechanics.

2. **Bytes fusion scope**: Concept + examples. Explain the benefits and why fusion is possible — the `elm/bytes` API is an opaque DSL builder, so the compiler can see the full construction at compile time while user code cannot inspect the values. Skip TableGen/MLIR dialect definitions.

3. **Typed closure calling**: Standalone page (`typed-closure-calling.md`) in the Compilation section rather than a section within code-generation.md.
