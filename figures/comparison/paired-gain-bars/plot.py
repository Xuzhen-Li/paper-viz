"""Paired gain bars (house style): judge win rate of each model answering alone (grey) and the
same model after it is shown other models' answers (blue), as paired bars sorted by the second
condition; bar values on top and the gain in points above each pair. No error bars: each bar is
a single proportion over the prompts, and n is printed. Reads data.csv only. Run: python3 plot.py"""
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
Y_LABEL = "Win rate vs reference answer (%)"
FS_VAL = 6.5
FS_NOTE = 6.5
BAR_W = 0.34                      # two bars per model: 0.68 of the slot

rows = list(csv.DictReader(open(HERE / "data.csv")))
models = list(dict.fromkeys(r["model"] for r in rows))
conds = list(dict.fromkeys(r["condition"] for r in rows))
vals, n_per = {}, {}
for m in models:
    for c in conds:
        o = [float(r["outcome"]) for r in rows if r["model"] == m and r["condition"] == c]
        vals[(m, c)] = 100 * np.mean(o)
        n_per[(m, c)] = len(o)
n_set = set(n_per.values())
n_txt = f"{n_set.pop()} prompts per bar" if len(n_set) == 1 else f"{min(n_per.values())}-{max(n_per.values())} prompts per bar"
order = sorted(models, key=lambda m: vals[(m, conds[1])])

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
fill = {conds[0]: grey["ci"], conds[1]: hp[0]}          # #BFBFBF / #1F72AE fills
txtc = {conds[0]: grey["mid"], conds[1]: hp[0]}         # text: #6B6B6B / #1F72AE (>= 4.5:1 on white)
ink = "#1A1A1A"

house.apply_house_style()
fig, ax = house.house_figure(cells=CELLS)
x = np.arange(len(models))
for k, c in enumerate(conds):
    off = (k - 0.5) * BAR_W
    v = np.array([vals[(m, c)] for m in order])
    ax.bar(x + off, v, width=BAR_W, color=fill[c], edgecolor="none", zorder=2)
    for xi, vi in zip(x + off, v):
        ax.text(xi, vi + 1.0, f"{vi:.1f}", color=ink, fontsize=FS_VAL, ha="center", va="bottom")
for xi, m in zip(x, order):
    top = max(vals[(m, c)] for c in conds)
    d = vals[(m, conds[1])] - vals[(m, conds[0])]
    ax.text(xi, top + 6.0, f"{d:+.1f}", color=txtc[conds[1]], fontsize=7, ha="center", va="bottom")
ax.set_xticks(x)
ax.set_xticklabels(order)
ax.set_xlim(-0.6, len(models) - 0.4)
ax.set_ylim(0, 100)
ax.set_ylabel(Y_LABEL)
# key (direct coloured labels) top-left, footnote top-right
ax.text(0.015, 0.965, conds[0], transform=ax.transAxes, color=txtc[conds[0]], fontsize=7, ha="left", va="top")
ax.text(0.015, 0.905, conds[1], transform=ax.transAxes, color=txtc[conds[1]], fontsize=7, ha="left", va="top")
ax.text(0.015, 0.845, "+x.x above each pair: gain in points", transform=ax.transAxes, color=ink, fontsize=FS_NOTE, ha="left", va="top")
ax.text(0.985, 0.965, f"Simulated data; {n_txt};", transform=ax.transAxes, color=grey["mid"], fontsize=FS_NOTE, ha="right", va="top")
ax.text(0.985, 0.91, "win = 1, tie = 0.5, loss = 0", transform=ax.transAxes, color=grey["mid"], fontsize=FS_NOTE, ha="right", va="top")
house.save_house(fig, HERE / "figure")
gains = [vals[(m, conds[1])] - vals[(m, conds[0])] for m in models]
print(f"models = {len(models)}; {n_txt}; gain range {min(gains):+.1f} to {max(gains):+.1f} points")
