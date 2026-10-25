"""Generate the docs flowchart SVGs in the site's design palette.

Usage: python3 script/diagrams/generate.py public/images/docs
"""
import sys, os
from xml.sax.saxutils import escape

TEXT = "#242424"
MUTED = "#646464"
BORDER = "#BDBDBD"
ACCENT = "#4CAF50"
FILL = "#FFFFFF"
FILL_ACCENT = "#F1F8F1"
FILL_EXT = "#F8F8F8"

CH = 7.4      # px per char at 13px Inter (approx)
LCH = 6.4     # px per char for 11.5px labels
LINE = 17
LLINE = 15
PADX, PADY = 14, 10


class Node:
    def __init__(self, id, x, y, text, kind="normal", w=None):
        self.id, self.x, self.y, self.kind = id, x, y, kind
        self.lines = text.split("\n")
        self.w = w or max(len(l) for l in self.lines) * CH + 2 * PADX
        self.h = len(self.lines) * LINE + 2 * PADY


def border_point(n, tx, ty):
    """Point where the line from n's centre towards (tx, ty) leaves n's box."""
    dx, dy = tx - n.x, ty - n.y
    if dx == 0 and dy == 0:
        return n.x, n.y
    sx = (n.w / 2) / abs(dx) if dx else float("inf")
    sy = (n.h / 2) / abs(dy) if dy else float("inf")
    s = min(sx, sy)
    return n.x + dx * s, n.y + dy * s


def render(name, title, width, nodes, edges, out):
    ns = {n.id: n for n in nodes}
    ext = [(n.x - n.w / 2, n.x + n.w / 2) for n in nodes]
    o = []
    o.append(f'<svg xmlns="http://www.w3.org/2000/svg" PLACEHOLDER" '
             f'role="img">')
    o.append(f'<title id="t">{escape(title)}</title>')
    o.append('<defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" '
             f'markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{MUTED}"/></marker></defs>')
    o.append('<style>text{font-family:Inter,system-ui,sans-serif}'
             f'.n{{font-size:13px;fill:{TEXT}}}.l{{font-size:11.5px;fill:{MUTED}}}</style>')
    for e in edges:
        a, b = ns[e[0]], ns[e[1]]
        label = e[2] if len(e) > 2 else ""
        opts = e[3] if len(e) > 3 else {}
        x1, y1 = border_point(a, b.x, b.y)
        x2, y2 = border_point(b, a.x, a.y)
        o.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
                 f'stroke="{MUTED}" stroke-width="1.4" marker-end="url(#a)"/>')
        if label:
            lines = label.split("\n")
            mx, my = (x1 + x2) / 2, (y1 + y2) / 2
            side = opts.get("side", "right")
            dx = opts.get("dx", 0)
            dy = opts.get("dy", 0)
            anchor = {"right": "start", "left": "end", "center": "middle"}[side]
            off = {"right": 8, "left": -8, "center": 0}[side]
            top = my - (len(lines) - 1) * LLINE / 2 + 4 + dy
            if side == "center":
                lw = max(len(l) for l in lines) * LCH + 8
                o.append(f'<rect x="{mx + dx - lw / 2:.1f}" y="{top - 13 + 0:.1f}" width="{lw:.1f}" '
                         f'height="{len(lines) * LLINE + 3}" fill="#FFFFFF" fill-opacity="0.92"/>')
            tw = max(len(l) for l in lines) * LCH
            lx = mx + off + dx
            ext.append({"start": (lx, lx + tw), "end": (lx - tw, lx), "middle": (lx - tw / 2, lx + tw / 2)}[anchor])
            for i, l in enumerate(lines):
                o.append(f'<text class="l" x="{mx + off + dx:.1f}" y="{top + i * LLINE:.1f}" '
                         f'text-anchor="{anchor}">{escape(l)}</text>')
    for n in nodes:
        stroke, fill, dash = BORDER, FILL, ""
        if n.kind == "accent":
            stroke, fill = ACCENT, FILL_ACCENT
        elif n.kind == "ext":
            fill, dash = FILL_EXT, ' stroke-dasharray="5 4"'
        o.append(f'<rect x="{n.x - n.w / 2:.1f}" y="{n.y - n.h / 2:.1f}" width="{n.w:.1f}" height="{n.h:.1f}" '
                 f'rx="6" fill="{fill}" stroke="{stroke}" stroke-width="1.4"{dash}/>')
        top = n.y - (len(n.lines) - 1) * LINE / 2 + 4.5
        for i, l in enumerate(n.lines):
            o.append(f'<text class="n" x="{n.x:.1f}" y="{top + i * LINE:.1f}" text-anchor="middle">{escape(l)}</text>')
    o.append("</svg>")
    x0 = min(a for a, _ in ext) - 12
    x1 = max(b for _, b in ext) + 12
    y0 = min(n.y - n.h / 2 for n in nodes) - 12
    y1 = max(n.y + n.h / 2 for n in nodes) + 12
    o[0] = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x0:.0f} {y0:.0f} {x1 - x0:.0f} {y1 - y0:.0f}" '
            f'width="{x1 - x0:.0f}" height="{y1 - y0:.0f}" role="img" aria-labelledby="t">')
    with open(os.path.join(out, name + ".svg"), "w") as f:
        f.write("\n".join(o) + "\n")


N = Node
D = {}

D["overview-pipeline"] = ("How Eco turns Elm source into a native program", 760, [
    N("src", 380, 30, "Elm source", "ext"),
    N("c", 380, 125, "compiler\nwritten in Elm", "accent"),
    N("js", 640, 125, "web output", "ext"),
    N("b", 380, 250, "backend\nwritten in C++", "accent"),
    N("r", 120, 375, "runtime:\ncollector and scheduler", "accent"),
    N("l", 380, 375, "link"),
    N("k", 640, 375, "kernels:\nC++ built-in functions", "accent"),
    N("exe", 380, 480, "executable, library\nor Node addon", "ext"),
], [
    ("src", "c"),
    ("c", "js", "JavaScript\nor HTML", {"side": "center", "dy": -14}),
    ("c", "b", "eco-dialect bytecode\nin a temporary file"),
    ("b", "l", "object files"),
    ("r", "l", "prebuilt\narchive", {"side": "center", "dy": -16}),
    ("k", "l", "prebuilt\narchives", {"side": "center", "dy": -16}),
    ("l", "exe"),
])

D["compiler-pipeline"] = ("The parts of the Eco compiler and what passes between them", 760, [
    N("src", 380, 30, "Elm modules", "ext"),
    N("fe", 380, 120, "front end", "accent"),
    N("lo", 380, 230, "local optimization", "accent"),
    N("link", 220, 350, "link\nin the build driver"),
    N("js", 560, 350, "JavaScript output", "accent"),
    N("mono", 220, 480, "monomorphization,\nwith lambda-set specialization\ninside its demand list", "accent"),
    N("go", 220, 610, "global optimization", "accent"),
    N("mlir", 220, 720, "MLIR generation", "accent"),
    N("be", 220, 820, "C++ backend", "ext"),
], [
    ("src", "fe"),
    ("fe", "lo", "canonical module,\ntyped on the typed path"),
    ("lo", "link", "typed graph\nper module, cached", {"side": "center"}),
    ("lo", "js", "erased graph\nper module, cached", {"side": "center"}),
    ("link", "mono", "one typed program"),
    ("mono", "go", "closed graph of\nspecializations"),
    ("go", "mlir", "graph with call kinds,\nstaging and layouts"),
    ("mlir", "be", "eco-dialect bytecode"),
])

D["backend-pipeline"] = ("The path of one module through the backend", 720, [
    N("f", 300, 30, "compiler", "ext"),
    N("d", 300, 135, "eco dialect\nand verifier", "accent"),
    N("p", 300, 250, "lowering passes", "accent"),
    N("n", 300, 365, "native drivers", "accent"),
    N("x", 160, 490, "executable, library\nor Node addon", "ext"),
    N("j", 480, 490, "JIT for tests\nand tools", "ext"),
], [
    ("f", "d", "eco-dialect bytecode\nin a temporary file"),
    ("d", "p", "verified module"),
    ("p", "n", "LLVM dialect, whole-program\nfacts stamped as attributes"),
    ("n", "x", "objects per partition,\nthen link", {"side": "center"}),
    ("n", "j", "code in memory", {"side": "center"}),
])

D["build-driver-pipeline"] = ("How the build driver runs a build", 760, [
    N("cli", 380, 35, "command line\nor JSON request", "ext"),
    N("lock", 380, 155, "lock project, find root,\nread settings", "accent"),
    N("det", 380, 275, "project details:\nsolve, verify, build packages", "accent"),
    N("build", 380, 395, "crawl imports,\ncompile in parallel", "accent"),
    N("js", 170, 525, "Elm JavaScript\ngenerator", "accent"),
    N("gen", 590, 525, "whole-program steps", "accent"),
    N("out", 590, 640, "MLIR file or\nin-process native link", "ext"),
], [
    ("cli", "lock", "flags"),
    ("lock", "det", "settings and hash"),
    ("det", "build", "module states"),
    ("build", "js", "untyped graphs\n(JavaScript, HTML)", {"side": "center"}),
    ("build", "gen", "typed graphs\n(MLIR, native)", {"side": "center"}),
    ("gen", "out", "MLIR bytecode"),
])

D["global-optimization-steps"] = ("The steps around global optimization, in order", 720, [
    N("tp", 300, 30, "linked typed program,\nidentity numbers assigned", "ext"),
    N("af", 300, 130, "alias forwarding", "accent"),
    N("ee", 300, 215, "eta-expansion", "accent"),
    N("mono", 300, 310, "monomorphization\nand lambda sets", "ext"),
    N("inl", 300, 410, "inline and simplify", "accent"),
    N("pr", 300, 495, "prune", "accent"),
    N("wr", 300, 580, "wrap callables", "accent"),
    N("rg", 300, 665, "regroup closure types", "accent"),
    N("st", 300, 750, "stamp single-callee calls", "accent"),
    N("an", 300, 835, "annotate every call", "accent"),
    N("gen", 300, 925, "MLIR generation", "ext"),
], [
    ("tp", "af"),
    ("af", "ee", "references retargeted"),
    ("ee", "mono", "definitions at declared arity"),
    ("mono", "inl", "specializations with\nlambda-set members"),
    ("inl", "pr", "rewritten bodies"),
    ("pr", "wr", "reachable specializations"),
    ("wr", "rg", "every function value a closure"),
    ("rg", "st", "closure types as emitted"),
    ("st", "an", "stamps"),
    ("an", "gen", "a call record on every call"),
])

D["mlir-generation-flow"] = ("How MLIR generation walks the specialized graph", 760, [
    N("g", 300, 35, "specialized graph\nwith call and closure facts", "ext"),
    N("c", 300, 150, "context", "accent"),
    N("n", 300, 255, "each specialization\nin id order", "accent"),
    N("t", 600, 380, "closure bodies, main,\nkernel declarations,\ntype table", "accent"),
    N("e", 300, 500, "bytecode encoder with\nappend-only tables", "accent"),
    N("b", 300, 610, "C++ backend", "ext"),
], [
    ("g", "c", "tables built once"),
    ("c", "n"),
    ("n", "t", "queued closure bodies,\nkernels called", {"side": "center"}),
    ("n", "e", "one function,\nper-function\nstate cleared", {"side": "left"}),
    ("t", "e"),
    ("e", "b", "bytecode file"),
])

D["runtime-threads"] = ("Threads in a running Eco program and what passes between them", 800, [
    N("h", 120, 60, "host thread,\nwhen embedded", "ext"),
    N("q", 400, 60, "ready queues"),
    N("w", 680, 60, "service threads:\ntimers, HTTP,\nprocess waits"),
    N("e", 400, 230, "eco thread:\nscheduler and Elm code", "accent"),
    N("hp", 400, 390, "Elm heap", "accent"),
    N("g", 120, 390, "collector\nhelper threads"),
], [
    ("h", "q", "port messages as\nserialized JSON", {"side": "center", "dy": -24}),
    ("w", "q", "plain data:\nresults and tokens", {"side": "center", "dy": -24}),
    ("q", "e", "drained by\nthe scheduler", {"side": "left"}),
    ("e", "w", "plain requests", {"side": "center"}),
    ("e", "hp", "allocate and read"),
    ("g", "hp", "mark and promote under\nthe collector's protocol", {"side": "center", "dy": -22}),
])

D["bootstrap-chain"] = ("The bootstrap chain from the stock Elm compiler to one native eco binary", 760, [
    N("elm", 300, 30, "stock Elm compiler", "ext"),
    N("s1", 300, 125, "eco as JavaScript\n(built by stock Elm)", "accent"),
    N("s2", 300, 235, "eco-boot.js\n(eco compiles itself to JS)", "accent"),
    N("s3", 300, 345, "eco-boot-2.js", "accent"),
    N("s4", 600, 345, "eco-boot-3.js\nmust equal eco-boot-2.js", "ext"),
    N("s5", 300, 460, "compiler as MLIR\n(lighter engine, fits in V8)", "accent"),
    N("s6", 300, 570, "native compiler", "accent"),
    N("s7", 300, 680, "native compiler, rebuilt\nby the native compiler", "accent"),
    N("s8", 600, 680, "rebuilt again:\nmust be identical", "ext"),
    N("s9", 300, 795, "one eco binary:\nfront end + backend", "accent"),
], [
    ("elm", "s1", "stage 1"),
    ("s1", "s2", "stage 2"),
    ("s2", "s3", "stage 3"),
    ("s3", "s4", "stage 4: JS fixed point", {"side": "center", "dy": -14}),
    ("s3", "s5", "stage 5"),
    ("s5", "s6", "stage 6: native backend"),
    ("s6", "s7", "stage 7"),
    ("s7", "s8", "stage 8: native fixed point", {"side": "center", "dy": -14}),
    ("s7", "s9", "stage 9"),
])


# ---------------------------------------------------------------------------
# Non-flowchart diagrams: bit fields, object layouts, heap map, sequence.

def svg_doc(title, w, h, body):
    return "\n".join([
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img">',
        f'<title>{escape(title)}</title>',
        '<defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" '
        f'markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{MUTED}"/></marker></defs>',
        '<style>text{font-family:Inter,system-ui,sans-serif}'
        f'.n{{font-size:13px;fill:{TEXT}}}.l{{font-size:11.5px;fill:{MUTED}}}'
        f'.m{{font-family:"Roboto Mono",monospace;font-size:12px;fill:{TEXT}}}'
        f'.h{{font-size:13px;font-weight:600;fill:{TEXT}}}</style>',
    ] + body + ["</svg>"]) + "\n"


def box(x, y, w, h, kind="normal"):
    stroke, fill, dash = BORDER, FILL, ""
    if kind == "accent":
        stroke, fill = ACCENT, FILL_ACCENT
    elif kind == "ext":
        fill, dash = FILL_EXT, ' stroke-dasharray="5 4"'
    return (f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="4" '
            f'fill="{fill}" stroke="{stroke}" stroke-width="1.4"{dash}/>')


def text(x, y, s, cls="n", anchor="middle"):
    return f'<text class="{cls}" x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}">{escape(s)}</text>'


def arrow(x1, y1, x2, y2, dash=False):
    d = ' stroke-dasharray="4 3"' if dash else ""
    return (f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{MUTED}" '
            f'stroke-width="1.4" marker-end="url(#a)"{d}/>')


def value_word():
    # 64-bit word, LSB on the right as in a register diagram.
    fields = [  # (name, hi, lo, kind, note)
        ("padding", 63, 53, "ext", "always 0"),
        ("ctor index", 52, 43, "normal", "nullary ctor"),
        ("pointer", 42, 3, "accent", "40-bit field"),
        ("ptr?", 2, 2, "normal", ""),
        ("const", 1, 0, "normal", ""),
    ]
    x0, scale, y = 20, 11, 50
    body = [text(x0, 24, "One Elm value outside a function body: a 64-bit word", "h", "start")]
    x = x0
    widths = {"padding": 11, "ctor index": 10, "pointer": 40, "ptr?": 1, "const": 2}
    minw = {"ptr?": 44, "const": 50}
    for name, hi, lo, kind, note in fields:
        w = max(widths[name] * scale, minw.get(name, 0))
        body.append(box(x, y, w, 44, kind))
        body.append(text(x + w / 2, y + 19, name))
        body.append(text(x + w / 2, y + 36, f"{hi}–{lo}" if hi != lo else f"{hi}", "l"))
        if note:
            body.append(text(x + w / 2, y + 62, note, "l"))
        x += w
    total = x
    body.append(text(x0, y + 92, "ptr? = 0: a heap object. The low 43 bits of the word are its address", "n", "start"))
    body.append(text(x0, y + 110, "(8-byte aligned, so the low 3 bits are already 0). No base register, no shift.", "n", "start"))
    body.append(text(x0, y + 136, "ptr? = 1: a constant held in the word itself, never traced by the collector:", "n", "start"))
    rows = [("0x4", "False"), ("0x5", "True"),
            ("0x6", "Empty: shared by (), [], Nothing, \"\" and {}"),
            ("0x7 | index << 43", "any other constructor with no fields")]
    for i, (k, v) in enumerate(rows):
        yy = y + 160 + i * 20
        body.append(text(x0 + 16, yy, k, "m", "start"))
        body.append(text(x0 + 170, yy, v, "n", "start"))
    return svg_doc("Layout of the 64-bit Elm value word", int(total + 20), int(y + 160 + 4 * 20 + 10), body)


def cons_cell():
    x0, y, rw = 20, 56, 150
    body = [text(x0, 24, "5 :: rest   as a heap object (24 bytes)", "h", "start")]
    cells = [
        ("header", "0x00000018_00000406", "accent"),
        ("head", "5   (raw i64)", "normal"),
        ("tail", "pointer to rest", "normal"),
    ]
    for i, (name, val, kind) in enumerate(cells):
        yy = y + i * 46
        body.append(text(x0 + 52, yy + 27, f"+{i * 8}", "l", "end"))
        body.append(box(x0 + 60, yy, 230, 46, kind))
        body.append(text(x0 + 70, yy + 19, name, "l", "start"))
        body.append(text(x0 + 70, yy + 36, val, "m", "start"))
    # tail arrow
    ty = y + 2 * 46 + 23
    body.append(arrow(x0 + 290, ty, x0 + 350, ty))
    body.append(box(x0 + 352, ty - 17, 90, 34, "ext"))
    body.append(text(x0 + 397, ty + 5, "rest"))
    # header breakdown
    bx = x0 + 330
    body.append(text(bx, y + 10, "header fields", "h", "start"))
    parts = [("tag = 6", "Cons"), ("unboxed = 01", "head is a raw Int (bit 10)"),
             ("size = 24", "upper 32 bits"), ("age, pin, builder", "collector bookkeeping")]
    for i, (k, v) in enumerate(parts):
        yy = y + 32 + i * 19
        body.append(text(bx, yy, k, "m", "start"))
        body.append(text(bx + 140, yy, v, "l", "start"))
    return svg_doc("Heap layout of a Cons cell holding the Int 5", 640, int(y + 3 * 46 + 16), body)


def closure_layout():
    x0, y = 20, 56
    body = [text(x0, 24, "A closure on the heap, and the static descriptor it points to", "h", "start")]
    rows = [
        ("header", "tag = Closure, size", "accent"),
        ("arity word", "arguments held (n_values) / taken (max_values)", "normal"),
        ("evaluator", "pointer to the descriptor", "normal"),
        ("values[0]", "first captured or applied argument", "normal"),
        ("values[…]", "…", "normal"),
    ]
    w = 330
    for i, (name, val, kind) in enumerate(rows):
        yy = y + i * 44
        body.append(box(x0, yy, w, 44, kind))
        body.append(text(x0 + 10, yy + 18, name, "l", "start"))
        body.append(text(x0 + 10, yy + 35, val, "n", "start"))
    # descriptor
    dx, dy = x0 + 420, y + 44
    body.append(text(dx, dy - 10, "evaluator descriptor (static data)", "h", "start"))
    drows = [("generic", "uniform entry point"), ("kinds", "argument kinds"),
             ("stage_arity", "arguments this stage takes"), ("sat[n]", "fast entry for n new arguments")]
    for i, (k, v) in enumerate(drows):
        yy = dy + i * 40
        body.append(box(dx, yy, 250, 40, "ext"))
        body.append(text(dx + 10, yy + 17, k, "m", "start"))
        body.append(text(dx + 10, yy + 33, v, "l", "start"))
    body.append(arrow(x0 + w, y + 2 * 44 + 22, dx - 2, dy + 20))
    note_y = y + 5 * 44 + 26
    body.append(text(x0, note_y, "The arity word also records the result kind and a 2-bit kind (pointer, Int, Float, Char)",
                     "l", "start"))
    body.append(text(x0, note_y + 16, "for each argument, so generic apply and the collector need no static type information.",
                     "l", "start"))
    return svg_doc("Closure object layout", 700, note_y + 26, body)


def heap_layout():
    x0, y, W = 20, 60, 720
    body = [text(x0, 24, "One reserved address range per process (below 2^43)", "h", "start")]
    old_w = 440
    body.append(box(x0, y, old_w, 70, "normal"))
    body.append(text(x0 + old_w / 2, y - 8, "old generation: never moves", "l"))
    segs = [("uniform blocks", "one size class each", 160),
            ("mixed blocks", "several sizes", 150),
            ("large payloads", "strings, bytes", 130)]
    x = x0
    for name, note, w in segs:
        body.append(box(x + 6, y + 8, w - 12, 54, "ext"))
        body.append(text(x + w / 2, y + 31, name))
        body.append(text(x + w / 2, y + 48, note, "l"))
        x += w
    nx = x0 + old_w + 20
    nw = W - old_w - 20
    body.append(box(nx, y, nw, 70, "accent"))
    body.append(text(nx + nw / 2, y - 8, "nursery: young objects, copied", "l"))
    body.append(box(nx + 6, y + 8, 100, 54, "ext"))
    body.append(text(nx + 56, y + 31, "survivor"))
    body.append(text(nx + 56, y + 48, "extents", "l"))
    body.append(box(nx + 112, y + 8, nw - 118, 54, "normal"))
    body.append(text(nx + 112 + (nw - 118) / 2, y + 31, "eden"))
    body.append(text(nx + 112 + (nw - 118) / 2, y + 48, "bump allocation", "l"))
    body.append(text(x0, y + 92, "low addresses", "l", "start"))
    body.append(text(x0 + W, y + 92, "high addresses", "l", "end"))
    # flows
    fy = y + 120
    lines = [
        "1. Compiled code allocates in eden by bumping a pointer; one compare tests both “full” and “time to collect”.",
        "2. A minor collection copies eden’s survivors into a survivor extent.",
        "3. A background thread later promotes (tenures) survivors that are still live into the old generation.",
        "4. The old generation is marked by background threads while the program runs, then swept.",
    ]
    for i, l in enumerate(lines):
        body.append(text(x0, fy + i * 19, l, "n", "start"))
    return svg_doc("Heap layout: old generation and nursery", W + 40, fy + 4 * 19, body)


def sleep_sequence():
    lanes = [("Elm code", 110), ("scheduler (eco thread)", 330), ("timer thread", 560)]
    top = 60
    steps = [  # (from lane, to lane, label lines)
        (0, 1, ["Process.sleep 500 returns a Task", "(a description: no timer yet)"]),
        (1, 1, ["steps the task: makes a resume closure,", "parks it, gets a 64-bit token"]),
        (1, 2, ["schedule(500 ms, token)"]),
        (2, 2, ["waits; the heap is never touched"]),
        (2, 1, ["token is ready"]),
        (1, 1, ["event loop pops the token, takes the", "resume closure, calls it with Task.succeed ()"]),
        (1, 0, ["the Elm program continues"]),
    ]
    body = [text(20, 24, "Process.sleep: only the eco thread touches the Elm heap", "h", "start")]
    y = top + 40
    ys = []
    for f, t, lab in steps:
        ys.append(y)
        y += 30 + 15 * len(lab) + (14 if f == t else 0)
    bottom = y
    for name, x in lanes:
        body.append(box(x - 85, top - 8, 170, 30, "accent" if "eco" in name else "normal"))
        body.append(text(x, top + 12, name))
        body.append(f'<line x1="{x}" y1="{top + 22}" x2="{x}" y2="{bottom}" stroke="{BORDER}" stroke-width="1.2" stroke-dasharray="4 4"/>')
    for (f, t, lab), yy in zip(steps, ys):
        fx, tx = lanes[f][1], lanes[t][1]
        if f == t:
            body.append(f'<path d="M{fx},{yy} h26 v18 h-24" fill="none" stroke="{MUTED}" stroke-width="1.4" marker-end="url(#a)"/>')
            for i, l in enumerate(lab):
                body.append(text(fx + 34, yy + 4 + i * 15, l, "l", "start"))
        else:
            body.append(arrow(fx, yy + 15 * (len(lab) - 1) + 8, tx, yy + 15 * (len(lab) - 1) + 8))
            mx = (fx + tx) / 2
            for i, l in enumerate(lab):
                body.append(text(mx, yy - 2 + i * 15, l, "l"))
    return svg_doc("Sequence of a Process.sleep call across the eco thread and the timer thread",
                   790, bottom + 10, body)


CUSTOM = {
    "value-word": value_word,
    "cons-cell-layout": cons_cell,
    "closure-layout": closure_layout,
    "heap-layout": heap_layout,
    "sleep-sequence": sleep_sequence,
}

if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, (title, width, nodes, edges) in D.items():
        render(name, title, width, nodes, edges, out)
        print("wrote", name)
    for name, fn in CUSTOM.items():
        with open(os.path.join(out, name + ".svg"), "w") as f:
            f.write(fn())
        print("wrote", name)
