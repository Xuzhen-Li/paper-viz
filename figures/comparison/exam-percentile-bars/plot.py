"""Exam percentile bars (house style): for each exam, the percentile of human test-takers that
each of two models beats, as paired horizontal bars sorted by the newer model; the 50th
percentile (median test-taker) is a dashed reference line. Values at bar ends, model names as
coloured direct labels, everything inside the frame. Reads data.csv only. Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np

def _find_styles():
    here = Path(__file__).resolve()
    cands = []
    if len(here.parents) > 3:
        cands.append(here.parents[3] / "styles" / "python")   # future figures/<cat>/<slug>/ layout
    for c in cands:
        if (c / "house.py").is_file():
            return c
    raise FileNotFoundError("styles/python/house.py not found; tried " + ", ".join(map(str, cands)))


sys.path.insert(0, str(_find_styles()))
import house  # noqa: E402


HERE = Path(__file__).resolve().parent
CELLS = (3, 2)                    # 135 x 89 mm, no +2 pt bump
X_LABEL = "Percentile of human test-takers"
FS_VAL = 6.5
FS_NOTE = 6.5
BAR_H = 0.36                      # two bars per exam: 2 x 0.36 = 0.72 of the row

rows = list(csv.DictReader(open(HERE / "data.csv")))
models = list(dict.fromkeys(r["model"] for r in rows))
exams = list(dict.fromkeys(r["exam"] for r in rows))
pct = {(r["exam"], r["model"]): float(r["percentile"]) for r in rows}
newer = models[-1]
order = sorted(exams, key=lambda e: pct[(e, newer)])          # bottom -> top: low -> high
n_exams = len(exams)
n_higher = sum(pct[(e, models[1])] > pct[(e, models[0])] for e in exams)

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
cols = {models[0]: grey["mid"], models[1]: hp[0]}             # older grey, newer blue (both >= 3:1)
ink = "#1A1A1A"

house.apply_house_style()
fig, ax = house.house_figure(cells=CELLS)
y = np.arange(n_exams)
for k, m in enumerate(models):
    off = (+BAR_H / 2) if k == 1 else (-BAR_H / 2)            # newer model on top of each pair
    v = np.array([pct[(e, m)] for e in order])
    ax.barh(y + off, v, height=BAR_H, color=cols[m], edgecolor="none", zorder=2)
    for yi, vi in zip(y + off, v):
        ax.text(vi + 1.2, yi, f"{vi:.0f}", color=ink, fontsize=FS_VAL, ha="left", va="center")
ax.set_yticks(y)
ax.set_yticklabels(order)
ax.set_xlim(0, 118)
ax.set_xticks([0, 25, 50, 75, 100])
ax.set_ylim(-0.7, n_exams + 0.2)
ax.set_xlabel(X_LABEL)
# direct labels (no legend box), bottom-right where the bars are shortest
lx = 117
ax.text(lx, 2.15, models[1], color=cols[models[1]], fontsize=7, ha="right", va="center")
ax.text(lx, 1.45, models[0], color=cols[models[0]], fontsize=7, ha="right", va="center")
ax.text(lx, 0.55, f"{models[1]} higher on {n_higher}/{n_exams} exams", color=ink, fontsize=FS_NOTE, ha="right", va="center")
ax.text(lx, -0.25, "Simulated data; one sitting per exam", color=grey["mid"], fontsize=FS_NOTE, ha="right", va="center")
ref_txt = ax.text(50.8, n_exams - 0.45, "50th percentile", color=grey["ref"], fontsize=FS_VAL, ha="left", va="bottom")
# dashed 50th-percentile line, broken wherever a value label would sit on it (gap >= 0.8 units)
fig.canvas.draw()
inv = ax.transData.inverted()
gaps = []
for t in ax.texts:
    if t is ref_txt:
        continue
    bb = t.get_window_extent().transformed(inv)
    if bb.x0 - 0.8 < 50 < bb.x1 + 0.8:
        gaps.append((bb.y0 - 0.06, bb.y1 + 0.06))
y_lo, y_hi = -0.7, n_exams - 0.5
segs, cur = [], y_lo
for g0, g1 in sorted(gaps):
    if g0 > cur:
        segs.append((cur, g0))
    cur = max(cur, g1)
segs.append((cur, y_hi))
for a, b_ in segs:
    ax.plot([50, 50], [a, b_], color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (3, 2)), zorder=1)
house.save_house(fig, HERE / "figure")
print(f"n_exams = {n_exams}; {models[1]} higher on {n_higher}/{n_exams}")
