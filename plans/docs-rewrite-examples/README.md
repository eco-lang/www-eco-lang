# Example programs for the docs rewrite

Small Elm programs compiled with `eco` 0.2.0 to textual eco-dialect MLIR, used as source
material for the before/after examples in `plans/docs-rewrite-for-outsiders.md`.

Regenerate one with:

    cd plans/docs-rewrite-examples
    eco make src/Stage.elm --text-mlir --output=out/Stage-default.mlir
    ECO_INLINE_THRESHOLD=0 eco make src/Stage.elm --text-mlir --output=out/Stage-zero.mlir
    ECO_MONO_LSS=0 eco make src/Lss.elm --text-mlir --output=out/Lss-nolss.mlir

File suffixes in `out/`:

- `-default` — default settings.
- `-zero` — `ECO_INLINE_THRESHOLD=0`, so small functions are not inlined away and each
  specialization stays visible.
- `-nolss` — lambda-set specialization switched off, for on/off contrast.
- no suffix — default settings.

When quoting the output in an article, strip the `_operand_types = [...]` attributes and say
that the listing is trimmed.
