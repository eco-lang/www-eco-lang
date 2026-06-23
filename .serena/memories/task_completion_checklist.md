# Task Completion Checklist

When a code change task is completed, verify:

1. **Elm compilation**: Ensure the code compiles without errors. Run `npm run build` or `npx elm-pages build` to verify.
2. **elm-review**: Run `npx elm-review` if available, to check for lint issues.
3. **Route module exports**: Every route module must export `ActionData, Data, Model, Msg, RouteParams, route`.
4. **Shared.elm consistency**: If adding a new route, check if it needs special treatment in `Shared.elm` view function (like Index does).
5. **Content files**: If adding blog posts, ensure frontmatter follows the schema in `style_and_conventions.md`.
6. **Settings.elm**: Update if site-wide config changes are needed.
7. **No broken imports**: Elm will catch these at compile time, but verify module paths match file paths.

## Notes
- There are no test dependencies or test files in this project currently.
- elm-review is installed as a devDependency but there's no review config visible in the project root (may need `elm-review init`).
- The Elm LSP may not resolve elm-pages generated modules (like `Route`, `RouteBuilder`, `PagesMsg`) since they're generated at build time in `.elm-pages/` and `gen/`.
