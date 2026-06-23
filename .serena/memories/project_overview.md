# Project Overview: www-eco-lang

## Purpose
Website for the **Eco Compiler** (Elm Compiler Optimized) — a reimagined Elm compiler written entirely in Elm itself. The site serves as a landing page + blog built with **elm-pages v3**.

## Tech Stack
- **Language**: Elm 0.19.1
- **Framework**: elm-pages v3 (package: `dillonkearns/elm-pages` 10.2.2, CLI: `elm-pages` 3.0.27)
- **CSS**: Tailwind CSS v4 with `@tailwindcss/typography` plugin, PostCSS
- **Build tool**: Vite 7.x (via elm-pages config)
- **Deployment**: Netlify (adapter in `elm-pages.config.mjs`, config in `netlify.toml`)
- **Markdown**: `dillonkearns/elm-markdown` 7.0.1 for blog content
- **Syntax highlighting**: `pablohirafuji/elm-syntax-highlight`
- **Icons**: `phosphor-icons/phosphor-elm`

## Key Dependencies
- `elm-pages` handles routing, data loading (BackendTask), SEO, and static site generation
- `elm-markdown` parses blog post markdown into structured blocks
- `elm-form` for form handling (available but minimally used)
- `justinmimbs/date` for date handling in blog posts
- `kuon/elm-string-normalize` for slug generation

## Design System Colors (from CLAUDE.md)
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
