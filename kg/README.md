# kg: a knowledge graph of the eco compiler

kg reads eco-compiler's history and files, and answers questions about its
structure, history and documentation through an MCP server for Claude Code.
It is written in Elm and built with eco. The design, the measurements and the
results are in [`../plans/compiler-knowledge-graph.md`](../plans/compiler-knowledge-graph.md).

## Build

```sh
npm run kg            # from the repository root: vendor the parser, then eco make
```

or by hand:

```sh
cd kg
scripts/vendor-compiler.sh ~/sc/gitlab/eco-compiler   # the compiler sources at vendor/COMMIT
eco make src/Main.elm --output=bin/kg
cd tests && eco make Run.elm --output=../bin/kg-test && ../bin/kg-test
```

## Use with Claude Code

Register once, from inside any eco-compiler worktree. Claude Code keys local
scope by the main repository, so this serves every worktree:

```sh
claude mcp add --transport stdio --scope local eco-kg -- ~/sc/gitlab/www-eco-lang/kg/bin/kg serve
```

The server works on the worktree in `CLAUDE_PROJECT_DIR`. The first session in
a worktree builds its snapshot in the background (about 40 s once the fact
cache is warm; about 8 minutes the very first time). After that it checks
HEAD and the dirty files before every query, and watches the source roots.

Vector search needs Ollama with `nomic-embed-text`
(`ollama pull nomic-embed-text`), used at 384 dimensions. Without it, search
is keyword-only. The first build of the vectors takes about 32 minutes on this
machine; run it with `kg embed`, or let the server do it in the background.
`ECO_KG_MODEL=all-minilm` builds in 11 minutes and did nearly as well.

## Commands

```
kg serve                                the MCP server
kg build | update                       build or update the snapshot
kg query <tool> '<json>'                run one tool: overview, locate, context, neighbours, path, history, layering
kg summary                              write out/compiler-map.md
kg check [--determinism N] [--atlas-parity <history.json>]
kg export --atlas <file> | --neo4j <dir>
kg embed [--max-minutes M]
kg eval eval/questions.json [--arms with,without] [--phase P] [--only id,...]
```

Add `--worktree <path>` to any command to choose the worktree. Settings:
`ECO_KG_OLLAMA`, `ECO_KG_MODEL`, `ECO_KG_DIMENSIONS`, `ECO_KG_CACHE`
(default `~/.cache/eco-kg`), `ELM_HOME`.
