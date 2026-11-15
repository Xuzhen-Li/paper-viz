"""Rainfall plot: inter-mutation distance along the genome, coloured by substitution class; house style, 4x1."""
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
classes = ["C>A", "C>G", "C>T", "T>A", "T>C", "T>G"]
kataegis_max_bp = 2000        # cluster rule: >= 6 consecutive gaps below this
# ----

df = pd.read_csv(HERE / "data.csv")
chroms = list(dict.fromkeys(df.chrom)); off, x0, ticks = {}, 0.0, []
for c in chroms:
    L = df[df.chrom == c].pos.max(); off[c] = x0; ticks.append(x0 + L / 2); x0 += L + 8e6
fig, ax = house.house_figure(cells="4x1")
nclu = 0
for c in chroms:
    d = df[df.chrom == c].sort_values("pos")
    gap = np.diff(d.pos.values); x = (d.pos.values[1:] + off[c]) / 1e6; sub = d.substitution.values[1:]
    for k, s in enumerate(classes):
        m = sub == s
        ax.scatter(x[m], np.log10(gap[m] + 1), s=3, color=PAL[k], linewidths=0)
    small = gap < kataegis_max_bp
    run, last = 0, -1e9
    for i, sm in enumerate(small):
        run = run + 1 if sm else 0
        if run >= 6 and x[i] - last > 5:       # one label per cluster
            last = x[i]
            nclu += 1
            ax.annotate("kataegis", (x[i], 1.4), xytext=(0, -1), textcoords="offset points", ha="center", va="top", fontsize=6.5, color=PAL[3])
for c in chroms[1:]:
    ax.axvline(off[c] / 1e6 - 4, color=GREY["light"], lw=0.5)
ax.set_xticks(np.array(ticks) / 1e6, chroms); ax.set_xlim(-5, x0 / 1e6)
ax.set_ylim(0.2, 7.8); ax.set_ylabel(r"log$_{10}$ distance (bp)")
for k, s in enumerate(classes):
    ax.text(0.005 + 0.045 * k, 0.95, s, transform=ax.transAxes, color=PAL[k], va="top", fontsize=6.5)
ax.text(0.995, 0.95, f"{len(df):,} SNVs; {nclu} clusters; simulated data", transform=ax.transAxes, ha="right", va="top", fontsize=6.5, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
