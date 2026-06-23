# Suggested Commands

## Development
```bash
npm start              # Dev server at localhost:1234 with INCLUDE_DRAFTS=true
npm run build          # Production build to dist/
```

## Build System
- elm-pages uses Vite under the hood
- Config in `elm-pages.config.mjs`
- Netlify adapter for deployment

## Elm Tooling
```bash
npx elm-pages dev      # Run dev server directly
npx elm-pages build    # Build directly
npx elm-review         # Run elm-review linter (elm-review 2.13.5 installed)
```

## Deployment
- Deployed to Netlify
- Build command in `netlify.toml` downloads lamdera binary, installs deps, runs `npm run build`
- Output to `dist/`
- Functions in `functions/`

## System Utilities (Linux)
- `git` — version control
- Standard Linux commands: `ls`, `cd`, `grep`, `find`, etc.
