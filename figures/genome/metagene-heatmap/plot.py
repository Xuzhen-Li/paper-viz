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
clusters = {"active": PAL[3], "low": PAL[0]}
vmax_q = 0.98          # colour scale tops out at this quantile
# ----

df = pd.read_csv(HERE / "data.csv")
bins = np.sort(df.bin_mid.unique())
W = df.pivot(index="gene", columns="bin_mid", values="signal")
cl = df.drop_duplicates("gene").set_index("gene").cluster.loc[W.index]
order = []
for c in clusters:
    g = W[cl == c]; order += list(g.mean(axis=1).sort_values(ascending=False).index)
W = W.loc[order]; cl = cl.loc[order]
fig, (a1, a2) = house.house_figure(cells="2x3", nrows=2, ncols=1, gridspec_kw={"height_ratios": [1, 2.6]})
for c, col in clusters.items():
    m = W[cl == c].mean(axis=0)
    a1.plot(bins, m, color=col, lw=LW["main"])
    i = int(np.argmax(m.values))
    a1.text(bins[i] + (350 if c == "active" else 1300), m.values[i] + (0 if c == "active" else 1.0), f"{c} (n = {(cl == c).sum()})", color=col, fontsize=7, va="center")
a1.set_xlim(bins[0] - 75, bins[-1] + 75); a1.set_ylabel("Mean signal"); a1.set_xticks([-3000, 0, 3000]); a1.set_xticklabels([])
a1.axvline(0, color=GREY["mid"], lw=LW["ref"], ls=(0, (2, 1.5)))
a1.text(0.02, 0.95, "simulated data", transform=a1.transAxes, fontsize=6, color=GREY["mid"], va="top")
cmap = mpl.colors.LinearSegmentedColormap.from_list("w2r", ["#FFFFFF", "#F6DEDE", "#E19193", "#C4454B", "#7A1416"])
vmax = float(np.quantile(W.values, vmax_q))
im = a2.imshow(W.values, aspect="auto", cmap=cmap, vmin=0, vmax=vmax, interpolation="nearest",
               extent=[bins[0] - 75, bins[-1] + 75, len(W), 0])
n1 = (cl == list(clusters)[0]).sum()
a2.axhline(n1, color="black", lw=LW["frame"])
for c, (y0, y1) in zip(clusters, [(0, n1), (n1, len(W))]):
    a2.text(bins[0] - 75 + 120, (y0 + y1) / 2, c, rotation=90, va="center", ha="left", fontsize=7, color=clusters[c], fontweight="bold")
a2.set_yticks([]); a2.set_xticks([-3000, 0, 3000]); a2.set_xticklabels(["-3 kb", "TSS", "+3 kb"])
a2.set_ylabel(f"Genes (n = {len(W)}), sorted by mean signal")
cax = a2.inset_axes([0.72, 0.06, 0.24, 0.025])
cb = fig.colorbar(im, cax=cax, orientation="horizontal", ticks=[0, int(vmax)]); cb.outline.set_linewidth(0.4)
cb.ax.tick_params(labelsize=6, length=1.5); cax.set_title("signal", fontsize=6, pad=1.5)
house.save_house(fig, HERE / "figure")
