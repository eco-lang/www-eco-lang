"""Summarise kg eval results: per question and per category, by arm.
Usage: python3 -I scripts/eval-summary.py results/<a>.json [results/<b>.json ...]"""
import json, sys, statistics
runs = []
for path in sys.argv[1:]:
    d = json.load(open(path))
    for o in d["outcomes"]:
        if o["valid"]:
            runs.append(dict(o, file=path.split("/")[-1].replace(".json", "")))
labels = sorted({(r["file"], r["arm"]) for r in runs})
qs = sorted({r["question"] for r in runs})
def cell(rs):
    g = [r["grade"] for r in rs if r["grade"] is not None]
    calls = statistics.median(r["toolCalls"] for r in rs)
    kg = statistics.median(r["kgCalls"] for r in rs)
    return f'{calls:>4}/{kg:<3} g{sum(g)/len(g) if g else 0:.2f} ${sum(r["costUsd"] for r in rs)/len(rs):.2f} n{len(rs)}'
print("question".ljust(28) + "".join(f"{f[:22]}:{a}".ljust(30) for f, a in labels))
for q in qs:
    row = q.ljust(28)
    for f, a in labels:
        rs = [r for r in runs if r["question"] == q and r["file"] == f and r["arm"] == a]
        row += (cell(rs) if rs else "-").ljust(30)
    print(row)
print()
cats = sorted({r["category"] for r in runs})
print("category (median tool calls, mean grade, cost per pass over its questions)")
for c in cats + ["ALL"]:
    row = c.ljust(28)
    for f, a in labels:
        rs = [r for r in runs if (c == "ALL" or r["category"] == c) and r["file"] == f and r["arm"] == a]
        if rs:
            g = [r["grade"] for r in rs if r["grade"] is not None]
            row += f'{statistics.median(r["toolCalls"] for r in rs):>4} calls, grade {sum(g)/len(g) if g else 0:.2f}, ${sum(r["costUsd"] for r in rs)/len(rs)*len({r["question"] for r in rs}):.2f}'.ljust(30)
        else:
            row += "-".ljust(30)
    print(row)
