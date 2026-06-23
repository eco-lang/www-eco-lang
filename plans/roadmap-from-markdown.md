# Plan: Render roadmap from markdown content

## Context

The `/roadmap` page currently has all 7 milestones hardcoded as an Elm data structure in `app/Route/Roadmap.elm` (~100 lines of milestone records). This makes content updates require code changes. The goal is to move milestone content into a markdown file under `content/`, following the same content-loading patterns used by Docs and Articles, so that the roadmap can be maintained as prose.

This requires a custom markdown renderer because the roadmap has unique visual elements (timeline dots, version badges, status tags) that don't exist in the standard docs renderer.

## Markdown format

Single file: `content/roadmap.md`

```yaml
---
title: "Roadmap"
description: "Track the evolution of Eco from first commit to stable release."
statuses:
  v0.1.0: released
  v0.2.0: released
  v0.3.0: released
  v0.4.0: current
  v0.5.0: planned
  v1.0.0: planned
  v1.1.0: planned
---

## v0.1.0 — Genesis

The initial release establishing the foundation of the Eco compiler toolchain.

- Core parser and lexer implementation
- Basic AST generation and traversal
- CLI scaffolding with init, build, and run commands
- Error reporting with source location tracking

## v0.4.0 — Current

Performance tuning, concurrency primitives, and cross-compilation targets.

- Incremental compilation pipeline
- Async/await with green thread runtime
```

**Rules:**
- Every H2 becomes a milestone with a timeline dot
- Version is extracted from the H2 text before the " — " separator
- Status is looked up in the frontmatter `statuses` map by version key
- All content must be under an H2 (no orphan intro text)
- Unknown versions default leniently to `Planned` status

## Files to create (3)

### 1. `content/roadmap.md`

Move the 7 milestone records from `Route/Roadmap.elm` into markdown. Each milestone becomes an H2 heading + paragraph + bullet list, matching the current content exactly.

### 2. `src/Content/Roadmap.elm`

Content loading module following the `Content.About` single-file pattern (`BackendTask.File.bodyWithFrontmatter` on a known path).

**Types:**
```elm
type MilestoneStatus = Released | Current | Planned

type alias RoadmapMeta =
    { title : String
    , description : String
    , statuses : Dict String String
    }

type alias MilestoneGroup =
    { version : String
    , codename : String
    , status : MilestoneStatus
    , blocks : List Markdown.Block.Block
    }
```

**Key functions:**
- `roadmapData : BackendTask FatalError { meta : RoadmapMeta, milestones : List MilestoneGroup }`
  - Loads `content/roadmap.md` via `File.bodyWithFrontmatter`
  - Parses frontmatter into `RoadmapMeta` (title, description, statuses dict)
  - Parses markdown body into `List Block`
  - Calls `groupByMilestones` to split blocks at H2 boundaries
- `groupByMilestones : Dict String String -> List Block -> List MilestoneGroup`
  - Walks the block list, splitting at each H2
  - For each H2: splits text at " — " to get version + codename
  - Looks up version in statuses dict → `Released | Current | Planned` (default: `Planned`)
  - Collects subsequent blocks (paragraphs, lists, etc.) until next H2
- `extractNavItems : List MilestoneGroup -> List { version : String, codename : String, status : MilestoneStatus }`
  - Derives sidebar nav items from the grouped milestones (used by Layout)

**Frontmatter decoder:** Uses `Decode.field "statuses" (Decode.dict Decode.string)` to get the status map. Pattern: `Content.About.authorDecoder` for the `bodyWithFrontmatter` callback shape.

### 3. `src/Layout/Roadmap.elm`

New layout module that extracts all view functions from `Route/Roadmap.elm`. This follows the pattern of `Layout.Docs` and `Layout.Articles`.

**Exposes:** `viewRoadmapPage`

**Signature:**
```elm
viewRoadmapPage :
    { title : String, description : String }
    -> List MilestoneGroup
    -> List (Html msg)
```

**Contains:**
- Page structure: sidebar + timeline + content area (moved from Route/Roadmap.elm)
- `viewSidebar` — generates nav items from milestone groups (version + codename + status-colored dot)
- `viewMilestone` — renders station dot, version badge, codename, status tag, then body blocks
- `viewStation`, `viewMilestoneHeader` — status-aware rendering (moved from Route/Roadmap.elm)
- `roadmapRenderer : Markdown.Renderer.Renderer (Html msg)` — custom renderer for milestone body blocks

**Custom `roadmapRenderer`:**

Built from `Markdown.Renderer.defaultHtmlRenderer` with overrides for:

| Block type | Override | Class |
|---|---|---|
| `paragraph` | Yes | `eco-roadmap-desc` (Inter 15px, #646464, line-height 1.6) |
| `unorderedList` | Yes | Items rendered with `eco-roadmap-feature` + bullet char prefix |
| `codeBlock` | Yes | Reuse `docsSyntaxHighlight` from `Layout.Markdown` |
| `codeSpan` | Yes | Reuse `eco-doc-code-inline` class |
| `strong` | Yes | `eco-doc-strong` class |
| `link` | Yes | `eco-doc-link` class |
| `heading` | No | H2s are consumed by pre-processing; H3/H4 pass through as-is |

**Note:** H2 headings never reach the renderer — they are consumed by `groupByMilestones` in `Content.Roadmap`. The renderer only sees blocks *within* each milestone (paragraphs, lists, sub-headings, code). To make `Layout.Markdown.docsSyntaxHighlight` available, it needs to be exposed from that module.

## Files to modify (2)

### 4. `app/Route/Roadmap.elm`

Simplify significantly (~200 lines deleted):
- `Data` becomes `{ meta : Content.Roadmap.RoadmapMeta, milestones : List Content.Roadmap.MilestoneGroup }`
- `data` calls `Content.Roadmap.roadmapData`
- `view` delegates to `Layout.Roadmap.viewRoadmapPage`
- Remove: `MilestoneStatus` type, `Milestone` type, `milestones` list, all `view*` functions, all SVG icons

### 5. `src/Layout/Markdown.elm`

Expose `docsSyntaxHighlight` so that `Layout.Roadmap` can reuse it for code blocks within the roadmap renderer. Change the module declaration from:
```elm
module Layout.Markdown exposing (blocksToHtml, docsBlocksToHtml, toHtmlBlocks)
```
to:
```elm
module Layout.Markdown exposing (blocksToHtml, docsBlocksToHtml, docsSyntaxHighlight, toHtmlBlocks)
```

No other changes to this file.

## Implementation order

1. Create `content/roadmap.md` — transcribe current hardcoded milestones to markdown
2. Create `src/Content/Roadmap.elm` — content loader + block grouping logic
3. Expose `docsSyntaxHighlight` from `src/Layout/Markdown.elm`
4. Create `src/Layout/Roadmap.elm` — layout + custom renderer
5. Simplify `app/Route/Roadmap.elm` — wire up data loading and layout
6. Verify

## Verification

- `npm run build` — compiles without errors
- `npx elm-review` — no new warnings beyond the 4 pre-existing ones
- Visual comparison: roadmap page should look identical to current version
- Edit `content/roadmap.md` (e.g. change a description), rebuild, confirm change appears
- Confirm sidebar nav items match H2 headings with correct dot colors

## Style changes

None. All existing `eco-roadmap-*` classes in `src/Style.elm` are already correct and will be reused as-is by the new layout module.
