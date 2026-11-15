import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[2] / "styles" / "python"))
import house  # noqa: E402

house.apply_house_style()
PAL = house.pv_palette("house")
GREY = house.pv_palette("house_grey")
LW = house.LW_PT

# ---- parameters
cols = {"Base": GREY["mid"], "Retry": PAL[0], "Self-critique": PAL[2], "Critique + memory": PAL[1]}
# ----

df = pd.read_csv(HERE / "data.csv")
fig, ax = house.house_figure(cells="2x2")
ends = []
for m, c in cols.items():
    d = df[df.method == m]; p = d.solved / d.n_tasks; n = d.n_tasks.values
    z = 1.96; dd = 1 + z ** 2 / n; cc = (p + z ** 2 / (2 * n)) / dd; hw = z * np.sqrt(p * (1 - p) / n + z ** 2 / (4 * n ** 2)) / dd
    ax.fill_between(d.trial, cc - hw, cc + hw, color=c, alpha=0.15, lw=0)
    ax.plot(d.trial, p, color=c, lw=LW["main"], marker="o", ms=3.2, mec="black", mew=0.3)
    ends.append((m, c, p.values[-1], p.values[0]))
ends.sort(key=lambda e: e[2])
ypos = []
for m, c, y, y0 in ends:
    y_ = max(y, ypos[-1] + 0.035) if ypos else y
    ypos.append(y_)
    ax.text(10.25, y_, m, color=c, fontsize=7, va="center", ha="left")
best = ends[-1]
ax.text(0.03, 0.97, f"{best[0]}: +{(best[2] - best[3]) * 100:.0f} points\nfrom trial 1 to 10\nbands: Wilson 95% CI (n = {df.n_tasks.iloc[0]} tasks)\nsimulated data",
        transform=ax.transAxes, va="top", fontsize=6.5)
ax.set_xlim(0.7, 13.6); ax.set_xticks(range(1, 11)); ax.set_ylim(0.3, 1.0)
ax.set_xlabel("Trial"); ax.set_ylabel("Tasks solved (cumulative share)")
house.save_house(fig, HERE / "figure")
