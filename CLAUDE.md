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
- `style.css` - Tailwind CSS v4 styling

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
