# Plan: Remove Tailwind, then make the site work on phones

## Status

Phases 1 and 2 are implemented and checked.

- **Phone check.** Run in the two engines behind the target browsers, with Playwright's device profiles (screen size,
  pixel ratio, touch, user agent and mobile viewport handling): iPhone 13 in WebKit, the engine of iOS Safari, and
  Pixel 7 in Chromium, the engine of Android Chrome. On all eight pages in both, the layout viewport equals the screen
  width, the zoom is 1 and the page does not scroll sideways. The menu opens on a tap, marks the current page, and a
  tapped link navigates and leaves the menu closed. This is an emulation, not a physical device: browser chrome, the
  on-screen keyboard and real touch scrolling are not covered, so a look on an actual phone after deploying is still
  worthwhile.

- **Phase 1.** Tailwind, PostCSS, `style.css` and `postcss.config.js` are gone, along with the `tailwindcss`,
  `@tailwindcss/postcss`, `@tailwindcss/typography` and `postcss` packages. Every element has one `eco-*` class in
  `Style.elm`, built from `src/Style/Layout.elm`. Snapshot comparison against the site before the change found no
  difference on any page at any of the four widths, apart from one link whose height varies between runs of the
  unchanged site.
- **Phase 2.** `script/check-layout.mjs fit` passes: no page is wider than the screen at 390, 768, 1024 or 1440 px, and
  the phone menu opens, lists the section, marks the current page, navigates and closes. At 1024 and 1440 px every
  element has the same box as before. At 768 px the two doc pages that were wider than the screen now fit.
- **Decisions taken:** one menu holding the site links and the section's contents; the home comparison table becomes
  one card per feature on phones, labelled with CSS-generated text so the desktop markup is unchanged.
- **Additions not in the original plan:** each roadmap milestone has an `id` (`v0-2-0`), so the phone menu can link to
  it; the snapshot comparison has a `--by-box` mode that matches elements by tag, box and styles instead of their place
  in the tree, so an added wrapper (the table scroller) or a hidden element (the desktop menu) does not count as a
  change.

## Summary

At phone width (390 px) every page on the site is wider than the screen, so mobile browsers open it at 100% zoom with the
right-hand edge cut off. The `<head>` is already correct (`width=device-width,initial-scale=1`); the problems are all in
the layout CSS.

The site styles each element with two systems: Tailwind utilities in the markup for structure, and `eco-*` classes from
`Css.Global` in `src/Style.elm` for design. The mobile fixes are mostly overrides of `eco-*` rules, and Tailwind cannot
reliably override those (see below). So the work has two phases:

1. **Remove Tailwind**, moving everything it provides into `Style.elm`, with no visible change to the site.
2. **Make every page fit a phone**, with mobile rules written beside the desktop rules they change, and navigation for
   the docs, articles and roadmap on small screens.

---

## Why remove Tailwind

- **It is a thin layer.** The site uses 61 distinct Tailwind utilities, 290 times, across six files: flex layout, gaps,
  padding, a few type sizes. Only seven are responsive or state variants (`md:flex`, `md:flex-row`, `md:px-18`,
  `md:px-30`, `md:px-40`, `md:self-start`, `hover:underline`). The design itself, 173 `eco-*` classes in about 1,300
  lines of `Style.elm`, does not use Tailwind.
- **It cannot override our rules.** Tailwind v4 puts its utilities in `@layer utilities`, and the `Css.Global`
  stylesheet is unlayered, so any `eco-*` rule beats any Tailwind utility on the same property. A Tailwind `md:` class
  could not fix most of what breaks on a phone.
- **One system, checked by the compiler.** Styles in `Style.elm` are Elm values: a mistake is a compile error, where a
  mistyped Tailwind class compiles and does nothing. Each element's desktop and mobile rules sit together in one class.
- **Fewer moving parts.** It removes three npm packages (`tailwindcss`, `@tailwindcss/postcss`, and
  `@tailwindcss/typography`, which nothing uses), the PostCSS step, and the elm-pages starter's leftover body styles.

Tailwind ships no JavaScript to the browser. It is a build step: PostCSS runs it over `style.css`, it scans the project
for class names, and writes CSS for the ones it finds. Removing it changes the build, not what the browser runs.

---

## What has to replace the build tool

| Today, from Tailwind | Replacement |
|---|---|
| Rules for the 61 utilities in the markup | Functions in a new module, `src/Style/Layout.elm`, used inside `eco-*` class rules |
| Preflight, Tailwind's CSS reset | `reset : List Css.Global.Snippet`, the parts of Preflight the site relies on |
| Body rule: `@apply antialiased text-slate-500 dark:text-slate-400 bg-white dark:bg-slate-900` | A plain `body` rule in `Style.elm` with the same light-mode values; the dark-mode values are dropped, since the site has no dark theme |
| `@plugin '@tailwindcss/typography'` | Nothing; `prose` is not used |
| Theme variables (`--spacing`, palette) | Nothing; only the utilities and the body rule use them |
| Processing `style.css` | Its hand-written rules (`pre { contain: inline-size }`, the `elmsh` and `eco-hl-*` highlighting rules, line numbers) move into `Style.elm`, and `style.css` is deleted |

### `src/Style/Layout.elm`

Small functions returning `Css.Style`, in the same `Css.property` idiom as `Style.elm`. They follow Tailwind's values
exactly, so a converted element renders the same, and Tailwind's names map one to one (`gap-7` is `gap 7`), which keeps
the conversion easy to review.

| Family | Functions | Covers |
|---|---|---|
| Spacing (0.25rem steps) | `space`, `gap`, `padX`, `padY`, `padLeft`, `padTop`, `marginTop`, `marginBottom` | `gap-*`, `px-*`, `py-*`, `pl-*`, `pt-*`, `mt-*`, `mb-*` |
| Flex | `row`, `column`, `grow`, `noShrink`, `alignItems`, `alignSelf`, `spaceBetween` | `flex`, `flex-col`, `flex-1`, `flex-shrink-0`, `items-*`, `self-*`, `justify-between` |
| Type | `textXs`, `textSm`, `textLg`, `text4xl` (size and line height together, as Tailwind pairs them), `weight`, `tracking` | `text-*`, `font-*`, `tracking-*` |
| Sizing | `fullWidth`, `fullHeight`, `minScreenHeight`, `maxWidth`, `height` | `w-full`, `h-full`, `min-h-screen`, `max-w-[520px]`, `h-12`, `h-16` |
| Other | `rounded`, `roundedLg`, `relative`, `hidden`, `noUnderline`, `hoverUnderline`, `srOnly` | the rest |
| Responsive | `mobile : List Css.Style -> Css.Style`, a `(max-width: 767.98px)` media query | used in phase 2; the six `md:` utilities become a desktop rule plus a `mobile` override (`hidden md:flex` becomes `column` and `mobile [ hidden ]`) |

Roughly 100–150 lines including the reset.

### The style nodes, rendered once in `Shared.view`

Two `<style>` elements carry the site's CSS, and neither is placed well today.

- **`Style.styleNode`**, the `Css.Global` stylesheet. It is a top-level constant, so Elm builds it once and the
  virtual-DOM diff skips it on every render by identity (`if (x === y) return;` in `_VirtualDom_diffHelp`); `Html.lazy`
  is not needed. But five layouts each place it in their own tree (`app/Route/Index.elm`, `app/Route/Roadmap.elm`,
  `src/Layout/Docs.elm`, `src/Layout/Articles.elm`, `src/Layout/About.elm`), so a navigation that moves between layouts
  sees a different structure and recreates the element, and the browser re-reads about 15 KB of CSS.
- **The syntax-highlighting theme**, `SyntaxHighlight.useTheme SyntaxHighlight.oneDark`. It is called inside the view
  functions of `src/Layout/Docs.elm` and `src/Layout/Articles.elm`, so it is rebuilt and diffed on every render, and it
  is missing from the roadmap page, whose code blocks are rendered with the same highlighter.

The refactoring renders both once, as the first children of the body in `Shared.view`, for every route:

```elm
view _ page model toMsg pageView =
    { body = Style.styleNode :: Style.highlightTheme :: pageView.body
    , title = pageView.title
    }
```

`Style.highlightTheme` is a new top-level constant wrapping `useTheme`. Both are removed from the layouts. This also
replaces `Shared.view`'s `case`, whose eight branches all return `pageView.body` unchanged.

Both must stay constants. If either became a function of its arguments, such as a palette chosen at run time, it would
be rebuilt on every render, and `Html.lazy` would then be the way to keep the diff from comparing it.

`Css.Global` CSS is inline in every page (about 15 KB today) rather than a cached stylesheet. Moving Tailwind's rules in
adds a few KB per page, which is acceptable: it costs no extra request and the page renders without waiting for a
stylesheet.

---

## Phase 1: remove Tailwind, no visible change

1. **Baseline.** Write `script/check-layout.mjs` (see Verification) and record the current site at 390, 768, 1024 and
   1440 px.
2. **Foundations.** Add `src/Style/Layout.elm` and the `reset`. While Tailwind is still loaded, the reset duplicates
   Preflight harmlessly.
3. **Convert file by file:** `src/Layout/Site.elm`, `src/Layout/Docs.elm`, `src/Layout/Articles.elm`,
   `src/Layout/Roadmap.elm` with `app/Route/Roadmap.elm`, `src/Layout/About.elm`, `app/Route/Index.elm`. In each,
   every element's utilities move into its `eco-*` class (giving it one where it has none), and the `class` attribute
   keeps only `eco-*` names. Check against the baseline after each file.
4. **Move `style.css` into `Style.elm`, and render the style nodes once in `Shared.view`** (see "The style nodes"
   above). The snapshot comparison must also show the roadmap's code blocks gaining the theme, the one intended change.
5. **Remove Tailwind:** delete `style.css`, `postcss.config.js`, the stylesheet link in `elm-pages.config.mjs`, and the
   three npm packages.
6. **Check:** no class in `app/` or `src/` outside `eco-*`, `elmsh*` and the highlighters' classes; the baseline
   comparison passes at all four widths.

Phase 1 changes nothing visible except in two places: in dark mode, the page background behind the content stops
turning slate, and the roadmap's code blocks, if it has any, gain the syntax-highlighting theme the docs already use.

---

## Phase 2: make every page fit a phone

All rules are `mobile [ … ]` overrides inside the `eco-*` class they change. Desktop browsers never match them, so the
desktop layout cannot regress. `mobile` is `max-width: 767.98px`; a second, tablet breakpoint is added only if the
check at 768 px shows one is needed.

### What breaks today

Measured in headless Chrome at 390 px wide.

| # | Where | Cause | Page width |
|---|---|---|---|
| 1 | Header, every page | logo, badge and six nav links in one row that does not wrap (441 px) | ≈ 560 px |
| 2 | Docs, Articles, Roadmap | the sidebar is hidden below 768 px, with nothing in its place | — no navigation |
| 3 | Doc and article pages | `.eco-content-area` is a flex item without `min-width: 0`, so it grows to its widest unbreakable child: tables, long inline code such as the `Reify.elm` source path. Its padding (64 px left, 80 px right) leaves about 250 px for text | up to 685 px |
| 4 | Home | hero puts text and the 493 px editor side by side; "How it works" and the community cards are rows of three; the comparison table is three columns; sections have 80 px side padding | ≈ 870 px |
| 5 | Roadmap | the timeline's vertical line is positioned for the desktop layout and runs through the text | — |

Code blocks already scroll sideways inside the page and need no change.

### 1. Header and site navigation (`src/Layout/Site.elm`)

- On mobile, the header shows the logo, the version badge and a menu button. The six nav links move into the menu.
- On Docs, Articles and Roadmap pages, the same menu also lists that section's contents, the entries the sidebar shows
  on desktop, with the current page marked.
- The menu is a `<details>`/`<summary>` element. It opens and closes with no Elm state and no JavaScript, so it works on
  the pre-rendered HTML before the app starts. It is wrapped in `Html.Keyed` on the current path, so that navigating to
  another page renders a fresh, closed menu.
- The unused `showMenu` / `MenuClicked` state in `app/Shared.elm` is removed.
- Header side padding: 16 px.

### 2. Doc and article content (`src/Layout/Docs.elm`, `src/Layout/Articles.elm`, `src/Layout/Markdown.elm`)

- `.eco-content-area`: `min-width: 0` at all widths (it is a flex item); on mobile, padding `24px 16px 48px`.
- Markdown tables: the renderer wraps each table in `div.eco-doc-table-wrap` with `overflow-x: auto`, so a wide table
  scrolls inside the page the way code blocks do.
- Inline code: `overflow-wrap: anywhere`, so long paths break instead of widening the page.
- Page title and description: smaller type.
- Previous/next links at the foot of a page: stacked.

### 3. Home page (`app/Route/Index.elm`)

- Hero: the text above the editor. The editor takes the full width and scrolls its code sideways.
- "How it works" and the community cards: one column.
- Comparison table: one card per feature, with the Elm and eco values stacked under the feature name.
- Call-to-action band: the text above the buttons.
- Section side padding: 16 px.

### 4. Roadmap timeline (`src/Layout/Roadmap.elm`)

- The timeline line and its dots move to the left gutter, with the release entries indented beside it.

### 5. About (`src/Layout/About.elm`)

- Already stacks on mobile; the header was its only overflow. Check after change 1.

---

## Verification

`script/check-layout.mjs` drives headless Chrome over the DevTools protocol, using Node's built-in `WebSocket` (no new
dependencies), against a static server on `dist/`. Page set: home, docs index, a doc with tables
(`/docs/data-structures`), a doc with long inline code (`/docs/reification`), articles index, an article, roadmap, about.
Widths: 390, 768, 1024, 1440 px.

- **Snapshot mode** (phase 1). For every element on every page at every width, record its bounding box and its computed
  `display`, `margin`, `padding`, `font-size`, `line-height`, `font-weight`, `letter-spacing`, `color` and
  `background-color`, and save a screenshot. `--compare` diffs a new snapshot against the baseline and lists every
  element that moved or changed. Phase 1 is done when the diff is empty, apart from changes we have decided to accept.
  `--by-box` matches elements by tag, box and styles rather than by path, for comparisons across markup changes.
- **Fit mode** (phase 2). At each width, check that `document.documentElement.scrollWidth` equals the viewport width.
  Any page wider than the viewport fails, and the script names the widest elements. It also opens the mobile menu on a
  doc page and checks that the section's contents are listed and the links work.

Each phase is done when:

1. The script passes (snapshot comparison for phase 1, fit at all four widths for phase 2).
2. Phase 2 only: the 1440 px snapshot still matches phase 1's, so the desktop layout is unchanged.
3. `npm run build` succeeds and `elm-review` reports no new errors.
4. Phase 2 only: a check on a real phone (iOS Safari and Android Chrome) shows no horizontal scroll and a working menu.

---

## Decisions to confirm

- **Menu contents on section pages.** Proposed: one menu holding both the site links and the section's contents. The
  alternative is a separate "Contents" control on Docs, Articles and Roadmap pages, which keeps the site menu short but
  adds a second control to a small screen.
- **Comparison table on the home page.** Proposed: one card per feature. The alternative, a table that scrolls
  sideways, keeps the comparison side by side but hides the eco column off-screen at first.
