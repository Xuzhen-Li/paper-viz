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
cond_cols = {"Control": PAL[0], "Knockdown": PAL[1]}
# ----

df = pd.read_csv(HERE / "data.csv")
conds = [c for c in dict.fromkeys(df.condition) if c != "gene"]
fig, axes = house.house_figure(cells="4x2", nrows=len(conds) + 1, ncols=1, sharex=True,
                               gridspec_kw={"height_ratios": [1] * len(conds) + [0.28]})
for ax, c in zip(axes, conds):
    ex_ = df[df.type == "exon"].sort_values("start"); ex1, ex3 = ex_.end.iloc[0], ex_.start.iloc[-1]
    d = df[df.condition == c]; cv = d[d.type == "coverage"]; col = cond_cols[c]
    ax.bar(cv.start, cv.value, width=10, align="edge", color=col, lw=0)
    ymax = cv.value.max()
    jn = d[d.type == "junction"]
    for k, (_, r) in enumerate(jn.iterrows()):
        mid = (r.start + r.end) / 2; half = (r.end - r.start) / 2
        t = np.linspace(0, np.pi, 60)
        up = not (r.start == ex1 and r.end == ex3)
        h = ymax * (0.45 if up else -0.42)
        base = ymax * 0.82 if up else 0
        ax.plot(mid - half * np.cos(t), base + h * np.sin(t), color=col, lw=0.4 + r.value / 40)
        ax.text(mid, base + h + (ymax * 0.05 if up else -ymax * 0.05), str(int(r.value)), ha="center", va="bottom" if up else "top", fontsize=6.5)
    sk = (jn.start == ex1) & (jn.end == ex3); inc = jn[~sk].value.mean(); skp = jn[sk].value.sum()
    psi = inc / (inc + skp)
    ax.text(0.01, 0.95, c, transform=ax.transAxes, color=col, fontsize=7, fontweight="bold", va="top")
    ax.text(0.99, 0.95, f"exon 2 PSI = {psi:.2f}", transform=ax.transAxes, ha="right", va="top", fontsize=6.5)
    ax.set_ylim(-ymax * 0.62, ymax * 1.55); ax.set_yticks([0, round(ymax, -1)]); ax.set_ylabel("Reads")
    ax.spines["bottom"].set_visible(False); ax.tick_params(axis="x", length=0)
g = axes[-1]; ex = df[df.type == "exon"]
g.plot([ex.start.min(), ex.end.max()], [0, 0], color="black", lw=0.6)
for _, r in ex.iterrows():
    g.add_patch(plt.Rectangle((r.start, -0.4), r.end - r.start, 0.8, color=GREY["dark"], lw=0))
g.set_ylim(-1, 1); g.set_yticks([]); g.spines["left"].set_visible(False)
g.set_xlabel("Position (bp, simulated locus)")
g.set_xlim(ex.start.min() - 150, ex.end.max() + 150)
g.text(1.0, 1.0, "simulated data; arc numbers are junction reads; PSI = inclusion / (inclusion + skipping)", transform=g.transAxes, ha="right", va="bottom", fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
