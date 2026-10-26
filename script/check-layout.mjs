// Layout checks for the built site in dist/, run in headless Chrome.
//
//   node script/check-layout.mjs snapshot <dir>      record every element's box and styles, and screenshots
//   node script/check-layout.mjs compare <dir> <dir> [--all]
//                                                    list elements that moved or changed between two snapshots
//   node script/check-layout.mjs compare <dir> <dir> --by-box [width…]
//                                                    the same, matching elements by tag, box and styles rather than by
//                                                    their place in the tree, so added wrappers and hidden elements
//                                                    do not count as changes
//   node script/check-layout.mjs fit                 fail if any page is wider than the viewport, and test the mobile menu
//
// Run `npm run build` first. Uses Node's built-in fetch and WebSocket and the Chrome DevTools protocol, so it needs
// no npm packages. Set CHROME to choose the browser binary (default: google-chrome).

import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync, existsSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, extname } from "node:path";

const PAGES = [
  "/",
  "/docs",
  "/docs/data-structures",
  "/docs/reification",
  "/articles",
  "/articles/introduction",
  "/roadmap",
  "/about",
];
const WIDTHS = [390, 768, 1024, 1440];
const HEIGHT = 900;
const DIST = new URL("../dist/", import.meta.url).pathname;
const PORT = 8790;
const CDP_PORT = 9340;

const PROPS = [
  "display",
  "position",
  "margin-top",
  "margin-right",
  "margin-bottom",
  "margin-left",
  "padding-top",
  "padding-right",
  "padding-bottom",
  "padding-left",
  "font-family",
  "font-size",
  "line-height",
  "font-weight",
  "letter-spacing",
  "color",
  "background-color",
  "text-decoration-line",
  "border-top-width",
  "border-right-width",
  "border-bottom-width",
  "border-left-width",
  "border-radius",
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---- static server for dist/, resolving /path to /path/index.html as Netlify does

const TYPES = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".css": "text/css",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".json": "application/json",
  ".woff2": "font/woff2",
};

function serve() {
  const server = createServer((req, res) => {
    let path = decodeURIComponent(new URL(req.url, "http://x").pathname);
    let file = join(DIST, path);
    if (existsSync(file) && statSync(file).isDirectory()) file = join(file, "index.html");
    else if (!existsSync(file) && existsSync(file + "/index.html")) file = file + "/index.html";
    if (!existsSync(file)) {
      res.writeHead(404);
      res.end();
      return;
    }
    res.writeHead(200, { "content-type": TYPES[extname(file)] || "application/octet-stream" });
    res.end(readFileSync(file));
  });
  return new Promise((r) => server.listen(PORT, "127.0.0.1", () => r(server)));
}

// ---- Chrome over the DevTools protocol

async function launchChrome() {
  const profile = mkdtempSync(join(tmpdir(), "check-layout-"));
  const chrome = spawn(
    process.env.CHROME || "google-chrome",
    [
      "--headless=new",
      "--no-sandbox",
      "--hide-scrollbars",
      "--disable-gpu",
      `--remote-debugging-port=${CDP_PORT}`,
      `--user-data-dir=${profile}`,
      "about:blank",
    ],
    { stdio: "ignore" }
  );
  let targets;
  for (let i = 0; i < 100 && !targets; i++) {
    try {
      targets = await (await fetch(`http://127.0.0.1:${CDP_PORT}/json`)).json();
    } catch {
      await sleep(100);
    }
  }
  const page = targets.find((t) => t.type === "page");
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => (ws.onopen = r));
  let id = 0;
  const pending = new Map();
  ws.onmessage = (e) => {
    const m = JSON.parse(e.data);
    if (pending.has(m.id)) {
      pending.get(m.id)(m);
      pending.delete(m.id);
    }
  };
  const send = (method, params = {}) =>
    new Promise((r) => {
      const i = ++id;
      pending.set(i, r);
      ws.send(JSON.stringify({ id: i, method, params }));
    });
  const evaluate = async (expression) => {
    const m = await send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
    if (m.result.exceptionDetails) throw new Error(JSON.stringify(m.result.exceptionDetails));
    return m.result.result.value;
  };
  const close = () => {
    ws.close();
    chrome.kill();
    try {
      rmSync(profile, { recursive: true, force: true });
    } catch {}
  };
  return { send, evaluate, close };
}

async function open(cdp, width, path) {
  await cdp.send("Emulation.setDeviceMetricsOverride", {
    width,
    height: HEIGHT,
    deviceScaleFactor: 1,
    mobile: width < 768,
  });
  await cdp.send("Page.navigate", { url: `http://127.0.0.1:${PORT}${path}` });
  await sleep(300);
  await cdp.evaluate(
    // Load every declared font, not only those already in use, so text measured later does not change size when a
    // late font arrives.
    `new Promise(r => { const go = () => Promise.all([...document.fonts].map(f => f.load().catch(() => {}))).then(() => document.fonts.ready).then(() => setTimeout(r, 400)); document.readyState === 'complete' ? go() : addEventListener('load', go); })`
  );
}

// Every element in the body, keyed by a path that ignores <style>, <script> and <link> elements and elm-css's
// hidden wrapper around its <style>, so moving a stylesheet does not shift the keys of everything after it.
const SNAPSHOT_JS = `(() => {
  const props = ${JSON.stringify(PROPS)};
  const skip = e => ['STYLE', 'SCRIPT', 'LINK', 'NOSCRIPT'].includes(e.tagName) || e.classList.contains('elm-css-style-wrapper');
  const out = {};
  const walk = (el, path) => {
    const kids = [...el.children].filter(c => !skip(c));
    kids.forEach((c, i) => {
      const p = path + '/' + c.tagName.toLowerCase() + '[' + i + ']';
      const r = c.getBoundingClientRect();
      const cs = getComputedStyle(c);
      const entry = { box: [r.left, r.top + scrollY, r.width, r.height].map(v => Math.round(v * 2) / 2) };
      for (const k of props) entry[k] = cs.getPropertyValue(k);
      if (!c.children.length && c.textContent.trim()) entry.text = c.textContent.trim().slice(0, 40);
      out[p] = entry;
      walk(c, p);
    });
  };
  walk(document.body, 'body');
  return { width: document.documentElement.scrollWidth, height: document.documentElement.scrollHeight, elements: out };
})()`;

const slug = (path) => (path === "/" ? "home" : path.slice(1).replace(/\//g, "_"));

async function snapshot(dir) {
  mkdirSync(dir, { recursive: true });
  const server = await serve();
  const cdp = await launchChrome();
  const data = {};
  try {
    for (const width of WIDTHS) {
      for (const path of PAGES) {
        await open(cdp, width, path);
        data[`${width} ${path}`] = await cdp.evaluate(SNAPSHOT_JS);
        const { width: w, height: h } = data[`${width} ${path}`];
        const shot = await cdp.send("Page.captureScreenshot", {
          format: "png",
          captureBeyondViewport: true,
          clip: { x: 0, y: 0, width: Math.max(w, width), height: Math.min(h, 16000), scale: 1 },
        });
        writeFileSync(join(dir, `${slug(path)}-${width}.png`), Buffer.from(shot.result.data, "base64"));
        process.stdout.write(".");
      }
    }
  } finally {
    cdp.close();
    server.close();
  }
  writeFileSync(join(dir, "layout.json"), JSON.stringify(data));
  console.log(`\nSnapshot of ${PAGES.length} pages at ${WIDTHS.length} widths written to ${dir}`);
}

function compare(dirA, dirB, all) {
  const limit = all ? Infinity : 400;
  const a = JSON.parse(readFileSync(join(dirA, "layout.json")));
  const b = JSON.parse(readFileSync(join(dirB, "layout.json")));
  let differences = 0;
  const report = (key, msg) => {
    differences++;
    if (differences <= limit) console.log(`${key}  ${msg}`);
  };
  for (const key of Object.keys(a)) {
    if (!b[key]) {
      report(key, "page missing from second snapshot");
      continue;
    }
    if (a[key].width !== b[key].width || a[key].height !== b[key].height)
      report(key, `page size ${a[key].width}x${a[key].height} -> ${b[key].width}x${b[key].height}`);
    const ea = a[key].elements;
    const eb = b[key].elements;
    for (const p of Object.keys(ea)) {
      if (!eb[p]) {
        report(key, `${p} removed`);
        continue;
      }
      const changes = [];
      if (ea[p].box.join() !== eb[p].box.join()) changes.push(`box ${ea[p].box} -> ${eb[p].box}`);
      for (const k of PROPS) if (ea[p][k] !== eb[p][k]) changes.push(`${k} ${ea[p][k]} -> ${eb[p][k]}`);
      if (changes.length) report(key, `${p}${ea[p].text ? ` "${ea[p].text}"` : ""}: ${changes.join("; ")}`);
    }
    for (const p of Object.keys(eb)) if (!ea[p]) report(key, `${p} added`);
  }
  if (differences > limit) console.log(`… and ${differences - limit} more`);
  console.log(differences ? `${differences} differences` : "No differences");
  process.exitCode = differences ? 1 : 0;
}

// Measured against the device width, not innerWidth: with mobile emulation, as on a real phone, the browser widens
// the layout viewport to fit content that is too wide, so innerWidth grows with the page.
// Elements matched by what they look like rather than where they are: every element of the first snapshot must have an
// identical element (tag, box and styles) somewhere in the second, and every visible element of the second one in the
// first. An added wrapper or a hidden element is not a change; anything that moved or restyled is.
function compareByBox(dirA, dirB, widths) {
  const a = JSON.parse(readFileSync(join(dirA, "layout.json")));
  const b = JSON.parse(readFileSync(join(dirB, "layout.json")));
  const signature = (path, e) => [path.split("/").pop().replace(/\[\d+\]$/, ""), e.box, ...PROPS.map((k) => e[k])].join("|");
  const visible = (e) => e.display !== "none" && e.box[2] > 0 && e.box[3] > 0;
  let differences = 0;
  for (const key of Object.keys(a)) {
    if (widths.length && !widths.includes(key.split(" ")[0])) continue;
    const count = (elements, filter) => {
      const m = new Map();
      for (const [p, e] of Object.entries(elements)) if (filter(e)) m.set(signature(p, e), (m.get(signature(p, e)) || 0) + 1);
      return m;
    };
    const inA = count(a[key].elements, () => true);
    const inB = count(b[key].elements, () => true);
    const report = (elements, other, label, filter) => {
      const seen = new Map();
      for (const [p, e] of Object.entries(elements)) {
        if (!filter(e)) continue;
        const sig = signature(p, e);
        seen.set(sig, (seen.get(sig) || 0) + 1);
        if (seen.get(sig) > (other.get(sig) || 0)) {
          differences++;
          console.log(`${key}  ${label} ${p}${e.text ? ` "${e.text}"` : ""} box ${e.box}`);
        }
      }
    };
    report(a[key].elements, inB, "changed or gone:", () => true);
    report(b[key].elements, inA, "new or changed:", visible);
  }
  console.log(differences ? `${differences} differences` : "No differences");
  process.exitCode = differences ? 1 : 0;
}

const FIT_JS = (vw) => `(() => {
  const vw = ${vw};
  const over = [...document.body.querySelectorAll('*')].filter(e => {
    const r = e.getBoundingClientRect();
    if (r.right <= vw + 0.5 || r.width === 0) return false;
    for (let p = e.parentElement; p && p !== document.body; p = p.parentElement)
      if (['auto', 'scroll', 'hidden', 'clip'].includes(getComputedStyle(p).overflowX)) return false;
    return true;
  });
  const outermost = over.filter(e => !over.includes(e.parentElement));
  return { width: Math.max(document.documentElement.scrollWidth, innerWidth), viewport: vw,
    culprits: outermost.slice(0, 6).map(e => e.tagName.toLowerCase() + (e.className && typeof e.className === 'string' ? '.' + e.className.trim().split(/\\s+/).join('.') : '') + ' right=' + Math.round(e.getBoundingClientRect().right)) };
})()`;

async function fit() {
  const server = await serve();
  const cdp = await launchChrome();
  let failures = 0;
  try {
    for (const width of WIDTHS) {
      for (const path of PAGES) {
        await open(cdp, width, path);
        const r = await cdp.evaluate(FIT_JS(width));
        if (r.width > r.viewport) {
          failures++;
          console.log(`FAIL ${width} ${path}: page is ${r.width}px wide; ${r.culprits.join(", ")}`);
        }
      }
    }
    failures += await checkMenu(cdp);
  } finally {
    cdp.close();
    server.close();
  }
  console.log(failures ? `${failures} failures` : "All pages fit at every width, and the mobile menu works");
  process.exitCode = failures ? 1 : 0;
}

// On a phone, the site menu must be visible, closed, open on a tap, list the section's contents with the current
// page marked, navigate, and be closed again on the new page.
async function checkMenu(cdp) {
  let failures = 0;
  const fail = (msg) => {
    failures++;
    console.log(`FAIL menu: ${msg}`);
  };
  await open(cdp, 390, "/docs/reification");
  const before = await cdp.evaluate(`(() => {
    const menu = document.querySelector('details.eco-menu');
    if (!menu) return null;
    const summary = menu.querySelector('summary');
    return { open: menu.open, visible: summary.getBoundingClientRect().width > 0 };
  })()`);
  if (!before) return fail("no details.eco-menu on /docs/reification"), failures;
  if (!before.visible) fail("menu button not visible at 390px");
  if (before.open) fail("menu starts open");
  const opened = await cdp.evaluate(`(() => {
    document.querySelector('details.eco-menu summary').click();
    const menu = document.querySelector('details.eco-menu');
    const links = [...menu.querySelectorAll('a')].map(a => ({ href: a.getAttribute('href'), current: a.getAttribute('aria-current'), visible: a.getBoundingClientRect().width > 0 }));
    return { open: menu.open, links };
  })()`);
  if (!opened.open) fail("menu does not open on click");
  const hrefs = opened.links.map((l) => l.href);
  for (const href of ["/", "/docs", "/articles", "/roadmap", "/about", "/docs/bytes-fusion", "/docs/glossary"])
    if (!hrefs.includes(href)) fail(`menu has no link to ${href}`);
  if (!opened.links.some((l) => l.href === "/docs/reification" && l.current === "page"))
    fail("current page is not marked with aria-current");
  if (opened.links.some((l) => !l.visible)) fail("some menu links are not visible when open");
  await cdp.evaluate(
    `[...document.querySelectorAll('details.eco-menu a')].find(a => a.getAttribute('href') === '/docs/glossary').click()`
  );
  await sleep(1500);
  const after = await cdp.evaluate(
    `({ path: location.pathname, open: document.querySelector('details.eco-menu')?.open })`
  );
  if (after.path.replace(/\/$/, "") !== "/docs/glossary") fail(`menu link went to ${after.path}`);
  if (after.open) fail("menu still open after navigating");
  await open(cdp, 1440, "/docs/reification");
  const desktop = await cdp.evaluate(
    `(() => { const s = document.querySelector('details.eco-menu summary'); return s ? s.getBoundingClientRect().width : 0; })()`
  );
  if (desktop > 0) fail("menu button visible at 1440px");
  return failures;
}

const [mode, ...args] = process.argv.slice(2);
if (mode === "snapshot" && args.length === 1) await snapshot(args[0]);
else if (mode === "compare" && args[2] === "--by-box") compareByBox(args[0], args[1], args.slice(3));
else if (mode === "compare" && (args.length === 2 || (args.length === 3 && args[2] === "--all")))
  compare(args[0], args[1], args[2] === "--all");
else if (mode === "fit") await fit();
else {
  console.log(readFileSync(new URL(import.meta.url).pathname, "utf8").split("\n").slice(0, 6).join("\n"));
  process.exitCode = 2;
}
