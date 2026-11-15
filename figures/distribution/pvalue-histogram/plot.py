"""Distribution-only p-value histograms for simulated Uniform(0,1) draws and a mixture
with excess near zero. One panel per set (shared y scale). Colour identifies the SET,
not significance: no individual p-value thresholds, stars, or p-based colouring.
The dashed line is the theoretical Uniform(0,1) density; pi0 = share of p > lambda divided
by (1 - lambda), a descriptive estimate of the null fraction (Storey), no test. Reads data.csv only.
Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent
# Parameters ---------------------------------------------------------------------------
bin_width = 0.05
cells = "3x1"
lam = 0.5          # Storey lambda for the descriptive pi0 estimate

rows = list(csv.DictReader((HERE / "data.csv").open()))
sets = list(dict.fromkeys(r["set"] for r in rows))
values = {s: np.array([float(r["p_value"]) for r in rows if r["set"] == s]) for s in sets}
edges = np.arange(0, 1 + bin_width * 0.5, bin_width)
dens = {s: np.histogram(v, bins=edges, density=True)[0] for s, v in values.items()}
ymax = float(max(max(x) for x in dens.values())) * 1.18

hp = house.pv_palette("house")
cols = [hp[0], hp[4]]  # set identity only (blue, purple)
grey = house.pv_palette("house_grey")

house.apply_house_style()
plt.rcParams["figure.constrained_layout.w_pad"] = 1.4 * house.MM
plt.rcParams["figure.constrained_layout.h_pad"] = 1.5 * house.MM
fig, axes = house.house_figure(cells=cells, nrows=1, ncols=len(sets), sharey=True)
for k, (ax, s, c) in enumerate(zip(np.atleast_1d(axes), sets, cols)):
    v = values[s]
    # Neutral fixed colours by set; all bins in a panel have the same colour.
    ax.hist(v, bins=edges, density=True, histtype="stepfilled", color=c, alpha=0.18, lw=0, zorder=2)
    ax.hist(v, bins=edges, density=True, histtype="step", color=c, lw=house.LW_PT["main"], zorder=3)
    ax.axhline(1.0, color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=4)
    ax.text(0.97, 0.97, s, color=c, fontsize=8, transform=ax.transAxes, ha="right", va="top")
    pi0 = min(1.0, float(np.mean(v > lam)) / (1.0 - lam))
    ax.text(0.97, 0.86, f"n = {len(v)} p-values\n\u03c00 estimate = {pi0:.2f} (Storey, \u03bb = {lam:.1f})",
            color=c, fontsize=7, transform=ax.transAxes, ha="right", va="top", linespacing=1.25)
    ax.text(0.97, 0.62, f"Simulated data; bin width = {bin_width:.2f}\nDashed: Uniform(0,1) density = 1",
            color=grey["mid"], fontsize=6.5, transform=ax.transAxes, ha="right", va="top", linespacing=1.25)
    ax.set_xlim(0, 1); ax.set_ylim(0, ymax)
    ax.set_xticks([0, 0.25, 0.5, 0.75, 1.0]); ax.set_xlabel("P-value")
    house.add_house_tag(ax, chr(ord("a") + k))
np.atleast_1d(axes)[0].set_ylabel("Density")
house.save_house(fig, HERE / "figure")
print("wrote figure.pdf, figure.png, preview.png")
