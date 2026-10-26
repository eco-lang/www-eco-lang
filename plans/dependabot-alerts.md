# Plan: Clear the Dependabot alerts

## Status

Done locally, not yet committed or pushed. Dependabot reads the lockfile on GitHub, so the alerts close only once this
reaches the `publish` remote.

Before: 43 open alerts on `eco-lang/www-eco-lang` across 17 packages (1 critical, 20 high, 18 medium, 4 low), and 28
packages flagged by `npm audit`. After: `npm audit` reports one low-severity package, esbuild, which is left as it is
(see below).

Every alert is a development dependency. None of this code is in the static site Netlify serves; the exposure is to the
machine running `npm start` or `npm run build`.

## What was done

1. **`npm audit fix`**, without `--force`. This updated the lockfile within the ranges `package.json` already allowed:
   vite to 7.3.7 (the dev-server file-read and `server.fs.deny` alerts), rollup, express and its parts (including the
   critical proxy-addr), ws, lodash, js-yaml, minimatch, picomatch, brace-expansion, postcss, nanoid, source-map-js, qs,
   ip-address and http-cache-semantics. It also updated elm-codegen to 0.6.3.

2. **elm-pages pinned to exactly `3.0.27`.** The audit fix also raised the npm package to 3.5.1, and even 3.0.28 refuses
   to build against the Elm package the site uses (`dillonkearns/elm-pages` 10.2.2): "The elm-pages NPM package is ahead
   of the elm-pages Elm package." The pin keeps `npm audit fix` from doing that again.

3. **Overrides for the three alerts the audit fix could not reach**, all below elm-pages and its Elm tools:
   - `node-elm-compiler` → `cross-spawn ^6.0.6` (ReDoS). Same major version, so no API change.
   - `devcert` and `elm-doc-preview` → `tmp ^0.2.6` (path traversal and symlink write). devcert asked for `tmp` 0.0.33,
     but it only calls `tmp.fileSync({ discardDescriptor: true }).name`, which 0.2.7 still provides. The nested copy
     under `node_modules/devcert` had to be removed from the lockfile for the override to apply.

4. **Checked:** `npm run build` succeeds; `node script/check-layout.mjs fit` passes (every page fits at every width,
   and the phone menu works); `npm start` serves pages; `npx elm-review` runs.

## Left as it is

- **esbuild** (low): arbitrary file read through its dev server *on Windows only*. elm-pages 3.0.27 needs this esbuild
  range. It goes away with the elm-pages upgrade below.

## Next steps

1. Commit `package.json` and `package-lock.json`, push to `publish`, and check the alerts close:
   `gh api 'repos/eco-lang/www-eco-lang/dependabot/alerts?state=open' --jq length`.
2. Later, as its own piece of work: upgrade elm-pages to 3.5.x, the npm package together with the
   `dillonkearns/elm-pages` Elm package, following its upgrade notes. That clears esbuild, and could let the `tmp`
   override go. Then drop the pin back to a `^` range.
3. Dismiss on GitHub any alert that remains open after the push only if the advisory doesn't apply, and say why.
