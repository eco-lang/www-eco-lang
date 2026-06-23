# Code Style and Conventions

## Elm Conventions
- Standard Elm 0.19.1 formatting (elm-format style)
- 4-space indentation in Elm files
- Module exposing list on first line: `module Route.Blog exposing (ActionData, Data, Model, Msg, RouteParams, route)`
- Type aliases for route module types: `Model`, `Msg`, `RouteParams`, `Data`, `ActionData`
- All route modules are stateless (use `buildNoState`, `Model = {}`, `Msg = ()`)
- Pipe-heavy style for BackendTask composition (`|> BackendTask.map`, `|> BackendTask.andThen`)
- Section comments like `-- HEADER`, `-- HERO`, `-- FOOTER` for visual separation
- Functions prefixed with `view` for rendering: `viewHeader`, `viewHero`, `viewFeatureCard`
- Icon functions as standalone: `githubIcon`, `sparkleIcon`, `downloadIcon`

## HTML/CSS Style
- Tailwind CSS v4 utility classes via `Attrs.class`
- Inline styles via `Attrs.style` for design-system-specific values (colors, fonts)
- SVG icons defined inline as Elm functions (not external files)
- Landing page uses inline styles for design system colors rather than Tailwind custom colors
- Blog layout pages use Tailwind's dark mode classes

## CSS
- Tailwind v4 with `@import 'tailwindcss'` and `@plugin '@tailwindcss/typography'`
- Custom theme colors defined in `@theme` block (primary-50 through primary-950)
- Elm Syntax Highlight CSS classes (`.elmsh-line`, `pre.elmsh`, `code.elmsh`)

## Naming Conventions
- Elm standard: camelCase for functions/variables, PascalCase for types/modules
- Route modules follow elm-pages convention: `Route.Blog.Slug_` for dynamic segments
- Slug normalization via `String.Normalize.slug`
- Content files: markdown with YAML frontmatter

## Blog Post Frontmatter Schema
```yaml
title: "Post Title"           # required
description: "SEO description" # optional
published: "2023-09-06"       # optional (ISO date string)
tags: ["elm", "blog"]         # optional (defaults to [])
authors: ["default"]          # optional (defaults to ["default"])
status: "published"           # optional ("draft" | "published")
slug: "custom-slug"           # optional (defaults from filename)
image: "/media/image.png"     # optional
```
