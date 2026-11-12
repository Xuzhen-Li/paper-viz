"""SuperPlot: cell-level points coloured by replicate with replicate means and a paired test on means; house style, 2x1."""
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
conditions = ["Control", "Drug A", "Drug B"]
y_label = "Cell speed (um/min)"
seed = 2
# ----

df = pd.read_csv(HERE / "data.csv")
rng = np.random.default_rng(seed)
reps = sorted(df.replicate.unique()); cols = [PAL[0], PAL[1], PAL[2]]
fig, ax = house.house_figure(cells="2x1")
means = {}
for i, c in enumerate(conditions):
    for k, r in enumerate(reps):
        v = df[(df.condition == c) & (df.replicate == r)].speed.values
        ax.scatter(i + rng.uniform(-0.28, 0.28, v.size), v, s=4, color=cols[k], alpha=0.45, linewidths=0)
        means[(c, r)] = v.mean()
    m = np.array([means[(c, r)] for r in reps])
    for k, r in enumerate(reps):
        ax.scatter(i + (k - 1) * 0.12, m[k], color=cols[k], zorder=4, s=house.SCATTER["s"] * 1.3, linewidths=0.5, edgecolors="black")
    ax.hlines(m.mean(), i - 0.3, i + 0.3, color="black", lw=LW["main"], zorder=5)
    ax.errorbar(i, m.mean(), yerr=m.std(ddof=1), color="black", lw=LW["errorbar"], capsize=2, zorder=5)
# paired t on replicate means vs control (n = 3 replicates)
def paired_t(a, b):
    d = np.asarray(b) - np.asarray(a)
    return d.mean() / (d.std(ddof=1) / np.sqrt(d.size))
ctrl = [means[("Control", r)] for r in reps]
top = df.speed.quantile(0.995)
for i, c in enumerate(conditions[1:], start=1):
    t = paired_t(ctrl, [means[(c, r)] for r in reps])
    ax.plot([0, 0, i, i], [top + i * 5.0 - 0.8, top + i * 5.0, top + i * 5.0, top + i * 5.0 - 0.8], color="black", lw=0.5)
    ax.text(i / 2, top + i * 5.0 + 0.4, f"t = {t:.1f}", ha="center", va="bottom", fontsize=6.5)
ax.set_xticks(range(len(conditions)), conditions); ax.set_xlim(-0.6, len(conditions) - 0.4)
ax.set_ylim(df.speed.min() - 1, top + 5.0 * len(conditions) + 1.5)
ax.set_ylabel(y_label)
for k, r in enumerate(reps):
    ax.text(0.015 + 0.1 * k, 0.96, f"rep {r}", transform=ax.transAxes, ha="left", va="top", fontsize=6.5, color=cols[k])
ax.set_ylim(df.speed.min() - 7, top + 5.0 * len(conditions) + 1.5)
ax.text(0.99, 0.03, "Simulated data; paired t test (two-sided) on n = 3 replicate means, no multiplicity correction", transform=ax.transAxes, ha="right", fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
