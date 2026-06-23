# Plan: Add Documentation Route

## Summary

Add a `/docs/:slug` route that renders documentation pages with a sidebar table-of-contents, breadcrumbs, and previous/next navigation — matching the "Documentation Page" design in pencil.

---

## Decisions

- **`/docs` route**: Renders the first doc page (Installation) directly — same layout as `/docs/installation`.
- **Header/footer sharing**: Extract the landing-page-style header/footer from `Route.Index` into a new shared module (`src/Layout/Site.elm`) so both Index and Docs reuse the same code.
- **Sample content**: 3 doc pages in the "Getting Started" section only. Other sections (Language Guide, Compiler Internals) appear in the sidebar TOC but their pages don't exist yet (links disabled or show as coming soon).
- **TOC ordering**: Derived from frontmatter `section` + `order` fields. The sidebar groups pages by `section`, sorts by `order` within each section, and sections themselves are ordered by the lowest `order` value among their pages.

---

## Design Reference (from pencil)

The design shows a three-part layout:
- **Header**: eco logo + version badge, nav links (Home, Docs, GitHub) — matches landing page style, NOT the blog layout
- **Body**: left sidebar (280px, TOC grouped by section) + main content area (markdown rendered with headings, paragraphs, code blocks, bullet lists, tables, note boxes, breadcrumbs, prev/next nav)
- **Footer**: same eco footer as landing page

Three TOC sections visible in the design sidebar:
1. **Getting Started**: Installation, Quick Start, Project Structure
2. **Language Guide**: Types & Values, Functions, Pattern Matching, Modules, Records
3. **Compiler Internals**: Architecture, Type System, MLIR Dialect, LLVM Backend, Native Code Generation

Design details:
- Sidebar: white background (`#FFFFFF`), right border (`#E0E0E0`), 280px wide, padding 32px top/bottom, 72px left
- Active sidebar item: green left border (2px `#4CAF50`), green text, `fontWeight: 500`
- Inactive sidebar item: `#646464` text, padding 7px top/bottom 12px left
- Section titles: `#242424`, `fontWeight: 600`, fontSize 13
- Breadcrumbs: `#999999` text, current page `#242424` fontWeight 500, separated by `/`
- Page title: Montserrat 36px semibold `#646464`
- Body text: Inter 16px `#242424` lineHeight 1.7
- H2 headings: Montserrat 24px semibold `#646464`
- Code blocks: `#2D2D2D` background, Roboto Mono 14px, padding 24px
- Note box: green left border (3px), light green background (`#4CAF500A`), info icon
- Previous/Next nav: green text/arrows, "Previous"/"Next" labels in muted text

---

## New Files

### 1. `content/docs/` — Markdown doc pages (3 sample files)

Each file has YAML frontmatter:
```yaml
---
title: "Installation"
description: "How to install the Eco compiler on your system."
section: "Getting Started"
sectionOrder: 1
order: 1
---
```

Fields:
- `title` (required): Page title
- `description` (optional): Short description shown below the title
- `section` (required): Section name for TOC grouping (display name, e.g. "Getting Started")
- `sectionOrder` (required): Ordering of the section itself in the sidebar (all pages in a section should have the same value)
- `order` (required): Ordering of this page within its section

Sample files to create:

**`content/docs/installation.md`** — Content derived from the pencil design:
- Prerequisites (system requirements, bullet list)
- Install via Script (curl command, note box about PATH)
- Manual Download (platform/architecture table)
- Verify Your Installation (version check + test compile)
- Build from Source (git clone + build commands)

**`content/docs/quick-start.md`** — Brief placeholder:
- Creating a new project
- Writing your first module
- Compiling and running

**`content/docs/project-structure.md`** — Brief placeholder:
- Directory layout of an Eco project
- Key files (eco.json, src/, build/)

### 2. `src/Content/Docs.elm` — Doc content loading module

Modelled after `Content.Blogpost`:

```elm
module Content.Docs exposing
    ( DocPage
    , DocMetadata
    , TocSection
    , allDocPages
    , docPageFromSlug
    , tocSections
    )
```

**Types:**
- `DocMetadata`: `{ title, slug, description, section, sectionOrder, order }`
- `DocPage`: `{ metadata : DocMetadata, body : List Block, previousPage : Maybe DocMetadata, nextPage : Maybe DocMetadata }`
- `TocSection`: `{ name : String, pages : List DocMetadata }`

**Functions:**
- `allDocPages : BackendTask FatalError (List DocPage)` — Globs `content/docs/*.md`, parses frontmatter + body, sorts globally by `(sectionOrder, order)`, adds previous/next links
- `docPageFromSlug : String -> BackendTask FatalError DocPage` — Finds a single page by slug
- `tocSections : BackendTask FatalError (List TocSection)` — Groups all pages by `section`, sorts sections by `sectionOrder`, sorts pages within each section by `order`

Frontmatter decoder parses: `title`, `description` (optional), `section`, `sectionOrder` (int), `order` (int). Slug is derived from the filename via `String.Normalize.slug` (same as blog posts).

### 3. `src/Layout/Site.elm` — Shared header/footer (extracted from Index)

Extract the landing-page-style header and footer from `Route.Index` into a reusable module:

```elm
module Layout.Site exposing (viewHeader, viewFooter, viewFooterDivider)
```

- `viewHeader : Html msg` — eco logo + version badge + nav links (Home, Docs, GitHub)
- `viewFooter : Html msg` — eco branding + Documentation/GitHub/Elm Lang links
- `viewFooterDivider : Html msg` — 1px `#E0E0E0` divider

These are currently defined as local functions in `Route.Index`. After extraction:
- `Route.Index` imports and calls `Layout.Site.viewHeader`, etc.
- `Layout.Docs` also imports and calls them.

The header nav links in the design show: Home, **Docs** (bold/active when on docs), GitHub. This differs slightly from Index's current header which only shows the GitHub link. The shared module should accept a parameter or the current route to highlight the active nav item.

### 4. `src/Layout/Docs.elm` — Docs layout rendering

Implements the docs-specific layout wrapping around the shared header/footer:

```elm
module Layout.Docs exposing (viewDocsPage)
```

`viewDocsPage : String -> DocPage -> List TocSection -> List (Html msg)`

Parameters: current slug (for active highlighting), the doc page data, TOC sections.

Layout structure (matching pencil):
1. Outer container: `min-h-screen flex flex-col`, background `#F8F8F8`
2. `Layout.Site.viewHeader` (with "Docs" highlighted)
3. Body: `flex` row
   - Sidebar (280px, white bg, right border): "Documentation" title, TOC sections with items
   - Content area (flex-grow, padding 48/80/64/64): breadcrumbs, page title + description, divider, markdown body, bottom divider, prev/next nav
4. `Layout.Site.viewFooterDivider`
5. `Layout.Site.viewFooter`

Sidebar rendering:
- Section title: bold, `#242424`
- Items: padded left, clickable links using `Route.Docs__Slug_ { slug = ... }`
- Active item: green left border + green text
- Items for pages that don't exist yet: rendered in muted grey, not linked (or linked but showing "Coming soon" content)

Content area:
- Breadcrumbs: "Docs / {Section} / {Title}" with `/` separators
- Title: Montserrat 36px semibold
- Description: Inter 17px, `#646464`, lineHeight 1.7
- Markdown body: rendered via `Layout.Markdown.renderer` (same as blog)
- Prev/Next navigation: left-aligned "Previous" with left arrow, right-aligned "Next" with right arrow

### 5. `app/Route/Docs/Slug_.elm` — Dynamic doc route (`/docs/:slug`)

Follows existing route module pattern:
```elm
module Route.Docs.Slug_ exposing (ActionData, Data, Model, Msg, RouteParams, route)
```

- `RouteParams = { slug : String }`
- `route`: Uses `RouteBuilder.preRender` (like `Blog/Slug_.elm`)
- `pages`: Enumerates all doc slugs from `Content.Docs.allDocPages`
- `data`: Loads `{ docPage : DocPage, tocSections : List TocSection }` via `Content.Docs.docPageFromSlug` and `Content.Docs.tocSections`
- `view`: Renders via `Layout.Docs.viewDocsPage`
- `head`: SEO tags with doc page title, description, canonical URL

### 6. `app/Route/Docs.elm` — Docs index route (`/docs`)

Static route that loads and displays the first doc page (Installation):
```elm
module Route.Docs exposing (ActionData, Data, Model, Msg, RouteParams, route)
```

- `RouteParams = {}`
- `route`: Uses `RouteBuilder.single` (like `Blog.elm`)
- `data`: Loads the first doc page (by lowest sectionOrder + order) + TOC sections
- `view`: Renders via `Layout.Docs.viewDocsPage` with the first page's slug and content

---

## Modified Files

### 7. `app/Shared.elm` — Bypass standard layout for docs routes

Add docs routes to the layout bypass in `Shared.view`:

```elm
view _ page model toMsg pageView =
    case page.route of
        Just Route.Index ->
            { body = pageView.body, title = pageView.title }

        Just (Route.Docs__Slug_ _) ->
            { body = pageView.body, title = pageView.title }

        Just Route.Docs ->
            { body = pageView.body, title = pageView.title }

        _ ->
            { body = Layout.view model.showMenu (toMsg MenuClicked) pageView.body
            , title = pageView.title
            }
```

*(The exact Route constructor names depend on what elm-pages generates — will verify after creating route files.)*

### 8. `app/Route/Index.elm` — Refactor to use shared header/footer

Replace the local `viewHeader`, `viewFooter`, `viewFooterDivider` functions with imports from `Layout.Site`. Remove the extracted functions. The `githubIcon` and `downloadIcon` helpers either move to `Layout.Site` (if shared) or stay in Index (if only used there).

### 9. `src/Layout.elm` — Add Docs to blog nav menu

Add "Docs" link to the blog-layout navigation so blog/tags/about pages link to docs:
```elm
menu =
    [ { label = "Blog", route = Route.Blog }
    , { label = "Docs", route = Route.Docs }
    , { label = "Tags", route = Route.Tags }
    , { label = "About", route = Route.About }
    ]
```

---

## Implementation Order

1. Create `content/docs/` with 3 sample markdown files
2. Create `src/Content/Docs.elm` (content loading, frontmatter-driven TOC)
3. Create `src/Layout/Site.elm` (extract header/footer from Index)
4. Refactor `app/Route/Index.elm` to use `Layout.Site`
5. Create `src/Layout/Docs.elm` (docs page layout from pencil design)
6. Create `app/Route/Docs/Slug_.elm` (dynamic route)
7. Create `app/Route/Docs.elm` (index route — loads first doc page)
8. Modify `app/Shared.elm` (layout bypass for docs routes)
9. Modify `src/Layout.elm` (add Docs to blog nav menu)
10. Build and verify (`npm run build`)

---

## Risk / Notes

- **elm-pages generated route names**: The exact constructor names for `Route.Docs__Slug_` in the generated `Route` module need to be verified after creating the route files. May need to run `elm-pages dev` once to generate them, then adjust `Shared.elm` accordingly.
- **Markdown rendering**: The docs content uses the same markdown-to-HTML pipeline as blog posts (`Layout.Markdown.renderer`). Special elements from the pencil design like "note boxes" (green-bordered info callouts) and tables would need custom markdown extensions. For the initial implementation, standard markdown rendering is sufficient — these can be enhanced later.
- **Active sidebar item**: Requires knowing the current slug in the layout. The route's view function passes this through to `Layout.Docs.viewDocsPage`.
- **Header nav active state**: The pencil design shows "Docs" in bold (`#242424`) when on a docs page and "Home" in regular weight (`#646464`). The shared header should accept the current route or a flag to highlight the active item.
- **Missing doc pages in sidebar**: The 3 created pages cover "Getting Started" only. The sidebar will show all 3 sections from the design, but Language Guide and Compiler Internals items won't have corresponding markdown files. These items should render as non-clickable/muted text or simply be omitted from the sidebar until content exists. Since TOC is frontmatter-driven, only pages with actual content files will appear — so the sidebar will only show "Getting Started" with 3 items initially. The other sections from the pencil design won't appear until their markdown files are created.
