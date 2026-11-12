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
import matplotlib as mpl

# ---- parameters
group_cols = {"Reference": GREY["ci"], "Tumour A": PAL[1], "Tumour B": PAL[2]}
lim = 0.6
# ----

df = pd.read_csv(HERE / "data.csv")
bins = [c for c in df.columns if c.startswith("chr")]
chrom = [b.split("_")[0] for b in bins]
X = df[bins].values
fig, (ag, ax) = house.house_figure(cells="4x2", nrows=1, ncols=2, gridspec_kw={"width_ratios": [0.025, 1], "wspace": 0.01})
im = ax.imshow(X, aspect="auto", cmap=house.house_cmap("house_div"), vmin=-lim, vmax=lim, interpolation="nearest")
gs = df.group.values
for g, c in group_cols.items():
    idx = np.where(gs == g)[0]
    ag.add_patch(plt.Rectangle((0, idx.min() - 0.5), 1, len(idx), color=c, lw=0))
    ax.text(len(bins) - 1, idx.min() + 1, f"{g} (n = {len(idx)})", ha="right", va="top", fontsize=6.5, color="black",
            bbox=dict(facecolor="white", edgecolor="none", pad=0.6, alpha=0.85))
    if idx.min() > 0:
        ax.axhline(idx.min() - 0.5, color="black", lw=LW["frame"])
ag.set_xlim(0, 1); ag.set_ylim(len(df) - 0.5, -0.5); ag.axis("off")
starts = [i for i in range(len(bins)) if i == 0 or chrom[i] != chrom[i - 1]]
for s in starts[1:]:
    ax.axvline(s - 0.5, color="black", lw=LW["ref"])
mids = [(a + b) / 2 - 0.5 for a, b in zip(starts, starts[1:] + [len(bins)])]
ax.set_xticks(mids); ax.set_xticklabels([chrom[s].replace("chr", "") for s in starts]); ax.tick_params(length=0)
ax.set_yticks([]); ax.set_xlabel("Chromosome")
ag.text(-0.4, 0.5, f"Cells (n = {len(df)})", transform=ag.transAxes, rotation=90, ha="right", va="center", fontsize=7)
cax = ax.inset_axes([1.012, 0.3, 0.012, 0.4])
cb = fig.colorbar(im, cax=cax, ticks=[-lim, 0, lim]); cb.outline.set_linewidth(0.4)
cb.ax.tick_params(labelsize=6, length=1.5); cax.set_title("log2\nratio", fontsize=6, pad=2)
ax.set_xlabel("Chromosome   (simulated data; blue = loss, red = gain)")
house.save_house(fig, HERE / "figure")
