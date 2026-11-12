import csv
import os
import sys
from pathlib import Path

import numpy as np

os.environ.setdefault("SOURCE_DATE_EPOCH", "0")  # reproducible PDF metadata
HERE = Path(__file__).resolve().parent


def _house_dir():
    """styles/python: parents[3] first (future figures/<cat>/<slug>/ layout), then the known checkouts."""
    here = Path(__file__).resolve()
    cands = [here.parents[3] / "styles" / "python"] if len(here.parents) > 3 else []
    for c in cands:
        if (c / "house.py").is_file():
            return c
    raise FileNotFoundError("styles/python/house.py not found; tried " + ", ".join(map(str, cands)))


sys.path.insert(0, str(_house_dir()))
import house  # noqa: E402


def lum(h):
    import matplotlib.colors as mc
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = mc.to_rgb(h)
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(a, b="#FFFFFF"):
    x, y = sorted([lum(a), lum(b)], reverse=True)
    return (x + 0.05) / (y + 0.05)


def text_col(c, bg="#FFFFFF", need=4.5):
    """Use the data colour for a label if it reaches `need`:1 (default 4.5) on `bg`, else near-black."""
    return c if contrast(c, bg) >= need else "#1A1A1A"
"""--- head-to-head-grid: array of small head-to-head win-rate heatmaps, one panel per
metric (columns) and corpus (rows). Cell = share of judgments the ROW method wins against
the COLUMN method (ties count 0.5); n questions per pair counted from data.csv."""
from collections import defaultdict

# Parameters ---------------------------------------------------------------------------
cells = (4, 2)                      # 183 x 89 mm
tie_weight = 0.5

rows = list(csv.DictReader((HERE / "data.csv").open()))
corpora = list(dict.fromkeys(r["corpus"] for r in rows))
metrics = list(dict.fromkeys(r["metric"] for r in rows))
methods = sorted({r["method_a"] for r in rows} | {r["method_b"] for r in rows})
k = len(methods)
idx = {m: i for i, m in enumerate(methods)}
score = defaultdict(lambda: np.zeros((k, k)))
count = defaultdict(lambda: np.zeros((k, k)))
nq = defaultdict(set)
for r in rows:
    key = (r["corpus"], r["metric"])
    a, b = idx[r["method_a"]], idx[r["method_b"]]
    wa = {"a": 1.0, "b": 0.0, "tie": tie_weight}[r["outcome"]]
    score[key][a, b] += wa
    score[key][b, a] += 1 - wa
    count[key][a, b] += 1
    count[key][b, a] += 1
    nq[(r["corpus"], r["method_a"], r["method_b"])].add(r["question"])
n_per_corpus = {}
for c in corpora:
    ns = {len(v) for (cc, _, _), v in nq.items() if cc == c}
    n_per_corpus[c] = ns.pop() if len(ns) == 1 else f"{min(ns)}-{max(ns)}"
wr = {key: np.where(count[key] > 0, 100 * score[key] / np.maximum(count[key], 1), np.nan) for key in score}
allwr = np.concatenate([m[np.isfinite(m)] for m in wr.values()])
span = 5 * np.ceil(np.max(np.abs(allwr - 50)) / 5)

house.apply_house_style()
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.colors import TwoSlopeNorm  # noqa: E402

grey = house.pv_palette("house_grey")
cmap = house.house_cmap("house_div").copy()
cmap.set_bad(grey["bg"])
norm = TwoSlopeNorm(vcenter=50, vmin=50 - span, vmax=50 + span)
fig, axes = house.house_figure(cells=cells, nrows=len(corpora), ncols=len(metrics), sharex=True, sharey=True)
axes = np.atleast_2d(axes)
strip = 0.85                        # in-frame title strip above the matrix (cell units)
for ri, c in enumerate(corpora):
    for ci, m in enumerate(metrics):
        ax = axes[ri, ci]
        M = wr[(c, m)]
        im = ax.imshow(np.ma.masked_invalid(M), cmap=cmap, norm=norm, aspect="auto",
                       extent=(-0.5, k - 0.5, k - 0.5, -0.5), interpolation="nearest")
        for i in range(k):
            for j in range(k):
                if not np.isfinite(M[i, j]):
                    continue
                bg = cmap(norm(M[i, j]))
                tc = "#000000" if contrast("#000000", bg) >= contrast("#FFFFFF", bg) else "#FFFFFF"
                assert contrast(tc, bg) >= 4.5, (M[i, j], bg)
                ax.text(j, i, f"{M[i, j]:.0f}", ha="center", va="center", fontsize=6.5, color=tc)
        # white 0.3 pt grid between cells
        for g in np.arange(0.5, k - 0.5, 1):
            ax.axhline(g, color="white", lw=0.3, gid="ignore")
            ax.axvline(g, color="white", lw=0.3, ymax=k / (k + strip), gid="ignore")
        ax.axhline(-0.5, color=grey["dark"], lw=0.4, gid="ignore")
        ax.set_ylim(k - 0.5, -0.5 - strip)
        ax.set_xlim(-0.5, k - 0.5)
        ax.text(0.04, 1 - 0.5 * strip / (k + strip), m, transform=ax.transAxes, fontsize=7, ha="left", va="center")
        ax.tick_params(length=0)
        ax.set_xticks(range(k))
        ax.set_xticklabels([s.split()[-1] for s in methods])
        ax.set_yticks(range(k))
        ax.set_yticklabels(methods)
        if ci == 0:
            ax.set_ylabel(f"{c}\nn = {n_per_corpus[c]} questions per pair", fontsize=7)
last = axes[-1, -1]
last.text(0.96, 1 - 0.5 * strip / (k + strip), "Simulated data", transform=last.transAxes,
          fontsize=6, color=grey["mid"], ha="right", va="center")
for ax in axes[-1]:
    ax.set_xlabel("Column method (opponent)", fontsize=7)
for ri, c in enumerate(corpora):
    house.add_house_tag(axes[ri, 0], "ab"[ri])
cb = fig.colorbar(im, ax=axes, location="right", shrink=0.6, aspect=22, pad=0.01)
cb.set_label(f"Row method win rate (%)\nties count {tie_weight:g}", fontsize=7)
cb.ax.tick_params(labelsize=7, length=1 * house.PT_PER_MM, width=0.5)
cb.outline.set_linewidth(0.5)
cb.set_ticks(np.linspace(50 - span, 50 + span, 5))
house.save_house(fig, HERE / "figure")
print("n questions per pair:", n_per_corpus)
print("wrote figure.pdf, figure.png, preview.png")
