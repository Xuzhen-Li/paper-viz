"""Learning curves across random seeds: validation error vs training-set size,
one thin line per seed, the across-seed mean (bold) and a mean +/- 1 s.d. band.
Log x-axis with plain-number tick labels (no mathtext exponents).
House style, single 2x2 panel: the +2 pt bump is applied up front (9 pt ticks,
10 pt axis titles), labels are placed at printed size, then save_house(bump=0).
Reads data.csv only. Run from this directory: python3 plot.py"""
import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import FixedLocator, NullLocator

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

X_LABEL = "Training-set size (examples)"
Y_LABEL = "Validation error"
CELLS = (2, 2)
FS_LABEL = 9
FS_NOTE = 7

rows = list(csv.DictReader(open("data.csv")))
methods = list(dict.fromkeys(r["method"] for r in rows))
sizes = np.array(sorted({int(r["n_train"]) for r in rows}))
table = {}
for r in rows:
    table[(r["method"], int(r["seed"]), int(r["n_train"]))] = float(r["val_error"])

hp = house.pv_palette("house")
cols = [hp[i] for i in (0, 3, 2, 4)][: len(methods)]   # blue, red, green, purple: all >= 3:1 on white
grey = house.pv_palette("house_grey")
ink = "#1A1A1A"

house.apply_house_style(single_panel=True)
fig, ax = house.house_figure(cells=CELLS)

seed_counts = {}
ends = []
for m, c in zip(methods, cols):
    seeds = sorted({s for (mm, s, _) in table if mm == m})
    seed_counts[m] = len(seeds)
    arr = np.array([[table[(m, s, n)] for n in sizes] for s in seeds])
    for curve in arr:
        ax.plot(sizes, curve, color=c, lw=house.LW_PT["minor"] * 0.75, alpha=0.6, zorder=2)
    mean = arr.mean(axis=0)
    sd = arr.std(axis=0, ddof=1) if arr.shape[0] > 1 else np.zeros_like(mean)
    ax.fill_between(sizes, mean - sd, mean + sd, color=c, alpha=0.20, lw=0, zorder=1)
    ax.plot(sizes, mean, color=c, lw=house.LW_PT["emph"], zorder=3)
    ends.append((m, c, float(mean[-1]), float(sd[-1])))

ax.set_xscale("log")
ax.xaxis.set_major_locator(FixedLocator(sizes))
ax.xaxis.set_minor_locator(NullLocator())
ax.set_xticklabels([f"{int(n):,}".replace(",", " ") if n >= 10000 else str(int(n)) for n in sizes])
ax.set_xlabel(X_LABEL)
ax.set_ylabel(Y_LABEL)
ax.set_xlim(sizes.min() / 1.15, sizes.max() * 2.6)       # room for end labels inside the frame
ymin = min(float(v) for v in table.values())
ymax = max(float(v) for v in table.values())
span = ymax - ymin
ax.set_ylim(max(0.0, ymin - 0.06 * span), ymax + 0.10 * span)

# direct labels just right of the last point, nudged apart if needed
ends.sort(key=lambda e: e[2])
min_gap = 0.075 * (ax.get_ylim()[1] - ax.get_ylim()[0])
placed = []
for m, c, y_end, _ in ends:
    yl = y_end if not placed or y_end - placed[-1] >= min_gap else placed[-1] + min_gap
    placed.append(yl)
    ax.text(sizes.max() * 1.12, yl, m, color=c, fontsize=FS_LABEL, ha="left", va="center")

ns = sorted(set(seed_counts.values()))
seed_txt = f"{ns[0]} seeds per method" if len(ns) == 1 else "seeds per method: " + ", ".join(
    f"{m} {k}" for m, k in seed_counts.items())
note = (f"Simulated data; {seed_txt}.\n"
        "Thin lines: individual seeds.\n"
        "Bold line: mean across seeds.\n"
        "Band: mean +/- 1 s.d. across seeds.")
ax.text(0.97, 0.97, note, transform=ax.transAxes, color=ink, fontsize=FS_NOTE,
        ha="right", va="top", linespacing=1.2)

house.save_house(fig, "figure", cells=CELLS, bump=0)
print("wrote figure.pdf, figure.png, preview.png")
