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
"""--- proportion-bars-ci: share of tasks per keyword that show a property, with a 95%
Wilson score interval; bar label k/n. n = distinct tasks per keyword, counted from data.csv.
A task with several keywords counts once under each. No test is run."""
from collections import defaultdict

from scipy.stats import norm as znorm

# Parameters ---------------------------------------------------------------------------
cells = "2x2"
ci_level = 0.95
min_n = 5                            # keywords with fewer tasks are not drawn
x_label = "Tasks showing the property (%)"


def wilson(k, n, level):
    z = znorm.ppf(0.5 + level / 2)
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * np.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return c - h, c + h


rows = list(csv.DictReader((HERE / "data.csv").open()))
by_kw = defaultdict(dict)
task_y = {}
for r in rows:
    by_kw[r["keyword"]][r["task"]] = int(r["has_property"])
    task_y[r["task"]] = int(r["has_property"])
stats = []
for kw, d in by_kw.items():
    n, k = len(d), sum(d.values())
    if n < min_n:
        continue
    lo, hi = wilson(k, n, ci_level)
    stats.append((kw, k, n, 100 * k / n, 100 * lo, 100 * hi))
stats.sort(key=lambda s: s[3])               # largest share at the top
N_all, K_all = len(task_y), sum(task_y.values())
pct = int(round(ci_level * 100))

house.apply_house_style(single_panel=True)   # one 2x2 panel: 9 pt ticks, 10 pt axis title
import matplotlib.pyplot as plt  # noqa: E402

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
fig, ax = house.house_figure(cells=cells)
y = np.arange(len(stats))
ax.barh(y, [s[3] for s in stats], height=0.64, color=hp[0], alpha=0.35, lw=0)
for yi, (kw, k, n, p, lo, hi) in zip(y, stats):
    ax.plot([lo, hi], [yi, yi], color="#000000", lw=house.LW_PT["errorbar"], solid_capstyle="butt")
    ax.plot([p], [yi], ls="none", marker="o", ms=3.2, mfc=hp[0], mec="#000000", mew=0.4)
    ax.text(hi + 1.5, yi, f"{k}/{n}", fontsize=8, va="center", ha="left", color="#1A1A1A")
overall = 100 * K_all / N_all
top = len(stats) - 0.5 + 1.2
bottom = -0.5 - 1.9                          # in-frame band for the footnote
ax.plot([overall, overall], [-0.5, len(stats) + 0.05], color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=0)
ax.text(overall, len(stats) + 0.15, f"All tasks {overall:.0f}% ({K_all}/{N_all})", fontsize=8,
        color=grey["mid"], ha="center", va="bottom")
ax.set_yticks(y)
ax.set_yticklabels([s[0] for s in stats])
ax.tick_params(axis="y", length=0)
ax.set_ylim(bottom, top)
xmax = 10 * np.ceil((max(s[5] for s in stats) + 16) / 10)
ax.set_xlim(0, xmax)
ax.set_xlabel(x_label)
ax.axhline(-0.5 - 0.35, color=grey["light"], lw=0.4, gid="ignore")
ax.text(0.03, 0.02, f"Simulated data. Bar, point: share k/n of tasks\nLine: {pct}% Wilson CI; n = tasks per keyword",
        transform=ax.transAxes, fontsize=7, color=grey["mid"], ha="left", va="bottom", linespacing=1.2)
house.save_house(fig, HERE / "figure", bump=0)
print("tasks:", N_all, "with property:", K_all, "keywords drawn:", len(stats))
for s in stats[::-1]:
    print(f"  {s[0]}: {s[1]}/{s[2]} = {s[3]:.1f}% ({pct}% Wilson {s[4]:.1f}-{s[5]:.1f})")
print("wrote figure.pdf, figure.png, preview.png")
