# Eco Compiler Website (elm-pages)

## Project Overview

This is the Eco Compiler website built with elm-pages v3. Eco is a reimagined Elm compiler written entirely in Elm itself.

## Key Architecture

### File Structure
- `app/Route/` - elm-pages file-based routing (each file = a route)
- `app/Shared.elm` - Shared layout and state across all pages
- `app/Site.elm` - Site-wide configuration and head tags
- `src/` - Shared Elm code (layouts, content parsing, settings)
- `content/blog/` - Markdown blog posts with frontmatter
- `content/authors/` - Author profiles in markdown
- `public/` - Static assets (copied to dist/)
- `content/packages/<author>/<name>/` - API docs for a hosted package: its `docs.json` (from `elm make --docs`), `elm.json` and `README.md`, copied from the package. Rendered at `/packages`, `/packages/<author>/<name>` and `/packages/<author>/<name>/<Module-Name>` (`src/Content/Packages.elm`, `src/Layout/Packages.elm`, `src/Layout/PackageMarkdown.elm`, `src/Code/ElmSignature.elm`). These pages are laid out as a separate site modelled on package.elm-lang.org (green band, menu on the right) with their own stylesheet, `src/Style/Packages.elm` (`pkg-*` classes); `Shared.view` picks the stylesheet by route
- `src/Style.elm` - the whole stylesheet, written with elm-css `Css.Global` as `eco-*` classes; phone rules sit inside each class as `mobile [ … ]` (below 768px). `src/Style/Layout.elm` has the layout functions (`row`, `gap 7`, `padX 4`, …) and the CSS reset. There is no Tailwind and no CSS file.
- `script/check-layout.mjs` - after `npm run build`: `fit` checks every page fits 390–1440px and the phone menu works; `snapshot`/`compare` (with `--by-box`) detect layout changes

### Routing
Routes are automatically generated from `app/Route/` files:
- `Index.elm` → `/` (landing page - custom layout, no blog wrapper)
- `Blog.elm` → `/blog`
- `Blog/Slug_.elm` → `/blog/:slug` (dynamic routes use `_` suffix)
- `About.elm` → `/about`
- `Tags.elm` → `/tags`
- `Tags/Slug_.elm` → `/tags/:slug`

### Layout System
- `Shared.elm` wraps pages with `Layout.view` from `src/Layout.elm`
- **Exception**: Index route bypasses the standard layout for custom landing page
- Each route returns a `View` type with `title` and `body`

### Blog Content
Markdown files in `content/blog/` with frontmatter:
```yaml
---
title: "Post Title"
description: "SEO description"
published: "2023-09-06"
tags: ["elm", "blog"]
authors: ["default"]
status: "published"  # or "draft"
---
```

## Development

```bash
npm start           # Dev server with drafts (INCLUDE_DRAFTS=true)
npm run build       # Production build to dist/
```

## Configuration

- `src/Settings.elm` - Site title, subtitle, author, canonical URL
- `elm-pages.config.mjs` - Vite config, Netlify adapter, head templates

## Design System Colors (from pencil design)

- Accent Green: `#4CAF50`
- Background: `#F8F8F8`
- Text Primary: `#242424`
- Text Heading: `#646464`
- Text Muted: `#999999`
- Border: `#E0E0E0`
- Code Background: `#2D2D2D`

## Fonts
- Headings: Montserrat
- Body: Inter
- Code: Roboto Mono
