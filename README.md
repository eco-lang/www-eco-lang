# Eco Website

Website for the [Eco compiler](https://github.com/eco-lang/eco) (Elm Compiler Optimized). Built with [elm-pages](https://elm-pages.com) v3 and Tailwind CSS v4, deployed on Netlify.

**https://eco-lang.org**

## Development

```bash
npm install
npm start         # Dev server on localhost:1234 (includes drafts)
npm run build     # Production build to dist/
npx elm-review    # Lint
```

## Project Structure

```
app/Route/           Route modules (file-based routing)
  Index.elm            Landing page
  About.elm            About page
  Docs.elm             Docs index
  Docs/Slug_.elm       Individual doc pages
src/
  Layout/Site.elm      Shared header and footer
  Layout/About.elm     About page layout
  Layout/Docs.elm      Docs sidebar and layout
  Layout/Markdown.elm  Markdown renderers
  Content/Docs.elm     Docs content loader
  Content/About.elm    Author content loader
  Settings.elm         Site title, URL, metadata
content/
  docs/                Documentation (markdown with frontmatter)
  authors/             Author profiles
public/                Static assets (copied to dist/)
style.css              Tailwind CSS v4
```

## Documentation

Docs live in `content/docs/` as markdown files with YAML frontmatter:

```yaml
---
title: "Page Title"
description: "SEO description"
section: "Architecture"       # Sidebar section grouping
sectionOrder: 1               # Section sort order
order: 1                      # Page sort order within section
---
```

Sections: **Architecture** (overview, type system), **Compilation** (monomorphization, staged currying, code generation), **Runtime** (memory model, garbage collection).
