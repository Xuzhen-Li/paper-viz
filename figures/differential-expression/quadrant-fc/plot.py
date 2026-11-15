"""Four-way (quadrant) plot of log2 fold changes in two contrasts with counts per quadrant; house style, 2x2."""
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
cut = 1.0                     # |log2FC| threshold in both contrasts
x_label, y_label = r"log$_2$ FC, drought vs control", r"log$_2$ FC, heat vs control"
# ----

df = pd.read_csv(HERE / "data.csv")
a, b = df.lfc_a.values, df.lfc_b.values
q = {"up-up": (a > cut) & (b > cut), "down-down": (a < -cut) & (b < -cut), "up-down": (a > cut) & (b < -cut), "down-up": (a < -cut) & (b > cut)}
cols = {"up-up": PAL[3], "down-down": PAL[0], "up-down": PAL[1], "down-up": PAL[4]}
rest = ~np.any(np.vstack(list(q.values())), axis=0)
r = np.corrcoef(a, b)[0, 1]
fig, ax = house.house_figure(cells="2x2")
ax.scatter(a[rest], b[rest], s=3, color=GREY["light"], linewidths=0, rasterized=True)
for k, m in q.items():
    ax.scatter(a[m], b[m], s=5, color=cols[k], linewidths=0)
for v in (-cut, cut):
    ax.axvline(v, color=GREY["ref"], lw=LW["ref"], ls=(0, (2, 1.5))); ax.axhline(v, color=GREY["ref"], lw=LW["ref"], ls=(0, (2, 1.5)))
lim = np.ceil(np.abs(np.r_[a, b]).max())
ax.set_xlim(-lim, lim); ax.set_ylim(-lim, lim)
pos = {"up-up": (0.97, 0.97, "right", "top"), "down-down": (0.03, 0.03, "left", "bottom"), "up-down": (0.97, 0.03, "right", "bottom"), "down-up": (0.03, 0.97, "left", "top")}
for k, (x, y, ha, va) in pos.items():
    ax.text(x, y, f"{k}\nn = {q[k].sum()}", transform=ax.transAxes, ha=ha, va=va, color=cols[k], fontsize=7)
ax.text(0.5, 0.97, f"Pearson r = {r:.2f}; simulated data", transform=ax.transAxes, ha="center", va="top", fontsize=6.5, color=GREY["mid"])
ax.set_xlabel(x_label); ax.set_ylabel(y_label)
house.save_house(fig, HERE / "figure")
