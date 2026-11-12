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
"""--- violin-grid: violins of review scores by base model, one panel per domain; inside
each violin the IQR (bar) and median (point). n papers per violin counted from data.csv.
No test is run."""
from collections import defaultdict

# Parameters ---------------------------------------------------------------------------
cells = (4, 1)                       # 183 x 43 mm, one 1x1 cell per domain
threshold = 6.0                      # reference score drawn as a dashed line
y_label = "Review score (1-10)"
bw = 0.35                            # KDE bandwidth factor (scipy gaussian_kde)

rows = list(csv.DictReader((HERE / "data.csv").open()))
domains = list(dict.fromkeys(r["domain"] for r in rows))
models = list(dict.fromkeys(r["model"] for r in rows))
vals = defaultdict(list)
for r in rows:
    vals[(r["domain"], r["model"])].append(float(r["score"]))

house.apply_house_style()
import matplotlib.pyplot as plt  # noqa: E402

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
cols = dict(zip(models, [hp[0], hp[1], hp[2], hp[4]]))
fig, axes = house.house_figure(cells=cells, nrows=1, ncols=len(domains), sharey=True)
axes = np.atleast_1d(axes)
for di, (ax, d) in enumerate(zip(axes, domains)):
    for mi, m in enumerate(models):
        v = np.array(vals[(d, m)])
        vp = ax.violinplot([v], positions=[mi], widths=0.82, showextrema=False, bw_method=bw)
        body = vp["bodies"][0]
        body.set_facecolor(cols[m]); body.set_alpha(0.6); body.set_edgecolor("none")
        body.set_clip_on(True)
        q1, med, q3 = np.percentile(v, [25, 50, 75])
        ax.plot([mi, mi], [q1, q3], color="#1A1A1A", lw=2.2, solid_capstyle="butt", zorder=3)
        ax.plot([mi], [med], ls="none", marker="o", ms=3.0, mfc="white", mec="#1A1A1A", mew=0.5, zorder=4)
        ax.text(mi, 0.55, f"n = {len(v)}", fontsize=6, ha="center", va="center", color=grey["mid"])
    ax.axhline(threshold, color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=0, gid="ignore")
    ax.set_xticks(range(len(models)))
    ax.set_xticklabels(models)
    ax.set_xlim(-0.55, len(models) - 0.45)
    ax.set_ylim(0, 11.4)
    ax.set_yticks([2, 4, 6, 8, 10])
    ax.text(0.04, 0.965, d, transform=ax.transAxes, fontsize=7, ha="left", va="top")
axes[0].set_ylabel(y_label)
house.add_house_tag(axes[0], "a")
axes[-1].text(0.96, 0.965, "Simulated data", transform=axes[-1].transAxes, fontsize=6,
              color=grey["mid"], ha="right", va="top")
axes[0].text(len(models) - 0.5, threshold + 0.15, f"Threshold {threshold:g}", fontsize=6,
             color=grey["mid"], ha="right", va="bottom")
axes[1].text(0.96, 0.965, "Bar: IQR; point: median", transform=axes[1].transAxes, fontsize=6,
             color=grey["mid"], ha="right", va="top")
house.save_house(fig, HERE / "figure")
for d in domains:
    print(d, {m: (len(vals[(d, m)]), float(np.median(vals[(d, m)]))) for m in models})
print("wrote figure.pdf, figure.png, preview.png")
