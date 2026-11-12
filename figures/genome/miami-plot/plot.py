"""Miami plot: two GWAS traits mirrored around the genome axis, shared loci highlighted; house style, 4x2."""
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
traits = {"A": "Trait A (e.g. flowering time)", "B": "Trait B (e.g. berry weight)"}
gw = 5e-8                     # genome-wide line
shared_window = 2e6           # loci within this distance are called shared
# ----

df = pd.read_csv(HERE / "data.csv")
chroms = sorted(df.chrom.unique()); off, x0, ticks = {}, 0.0, []
for c in chroms:
    L = df[df.chrom == c].pos.max(); off[c] = x0; ticks.append(x0 + L / 2); x0 += L + 5e6
df["x"] = (df.pos + df.chrom.map(off)) / 1e6
df["lp"] = -np.log10(df.p)
fig, ax = house.house_figure(cells="4x2")
lead = {}
for t, sign in (("A", 1), ("B", -1)):
    d = df[df.trait == t]
    col = np.where(d.chrom % 2 == 1, PAL[0] if t == "A" else PAL[1], house.pv_palette("house_div")[2] if t == "A" else house.pv_palette("house_warm")[1])
    ax.scatter(d.x, sign * d.lp, s=2.2, c=col, linewidths=0, rasterized=True)
    hits = d[d.p < gw]
    lead[t] = [g.loc[g.lp.idxmax()] for _, g in hits.groupby(["chrom", (hits.pos // 1e7)])]
    ax.axhline(sign * -np.log10(gw), color=GREY["ref"], lw=LW["ref"], ls=(0, (2, 1.5)))
shared = {}
for a in lead["A"]:
    for b in lead["B"]:
        if a.chrom == b.chrom and abs(a.pos - b.pos) < shared_window:
            shared.setdefault((a.chrom, round(a.pos / 1e7)), a)
nshared = len(shared)
for a in shared.values():
    ax.plot(a.x, 0, marker="D", ms=4, color=PAL[3], mec="black", mew=0.4, zorder=5)
    ax.text(a.x + 6, 12.0, f"shared locus, chr{a.chrom}", color=PAL[3], fontsize=6.5, va="center")
ax.axhline(0, color="black", lw=0.5)
ax.set_xticks(np.array(ticks) / 1e6, [str(c) for c in chroms]); ax.set_xlim(-5, x0 / 1e6)
yl = np.ceil(df.lp.max()) + 1
ax.set_ylim(-yl, yl); ax.set_yticks(np.arange(-15, 16, 5), [str(abs(v)) for v in np.arange(-15, 16, 5)])
ax.set_xlabel("Chromosome"); ax.set_ylabel(r"$-$log$_{10}$ P")
ax.text(0.005, 0.97, traits["A"], transform=ax.transAxes, va="top", color=PAL[0], fontsize=7)
ax.text(0.005, 0.03, traits["B"], transform=ax.transAxes, va="bottom", color=PAL[1], fontsize=7)
ax.text(0.995, 0.97, f"dashed: P = 5e-8 (two-sided Wald, no further correction); {nshared} shared locus (diamond); simulated data",
        transform=ax.transAxes, ha="right", va="top", fontsize=6.5, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
