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
alpha = 0.05
n_label = 4
# ----

df = pd.read_csv(HERE / "data.csv")
cats = list(dict.fromkeys(df.category))
cols = house.pv_palette("house")
df["x"] = np.arange(len(df)); df["lp"] = -np.log10(df.p)
bonf = -np.log10(alpha / len(df))
fig, ax = house.house_figure(cells="4x2")
mids = []
for i, c in enumerate(cats):
    d = df[df.category == c]
    col = cols[i % len(cols)]
    for up, mk in ((True, "^"), (False, "v")):
        s = d[(d.beta >= 0) == up]
        ax.scatter(s.x, s.lp, marker=mk, s=11, color=col, edgecolors="black", linewidths=0.25, zorder=3)
    mids.append(d.x.mean())
ax.axhline(bonf, color=PAL[3], lw=LW["ref"], ls=(0, (3, 2)))
ax.text(df.x.max(), bonf + 0.25, f"Bonferroni, 0.05 / {len(df)}", color=PAL[3], fontsize=6.5, ha="right", va="bottom")
for _, r in df.nsmallest(n_label, "p").iterrows():
    ax.annotate(f"{r.phenotype} ({'+' if r.beta > 0 else '-'})", (r.x, r.lp), xytext=(5, 2), textcoords="offset points", fontsize=6.5, va="center")
ax.set_xticks(mids); ax.set_xticklabels(cats, rotation=40, ha="right")
ax.set_xlim(-10, len(df) + 10); ax.set_ylim(0, df.lp.max() * 1.1)
ax.set_ylabel(r"$-\log_{10}P$")
ax.text(0.99, 0.97, "triangle up: risk increased; triangle down: risk decreased\nsimulated data; logistic regression per phecode, two-sided Wald P", transform=ax.transAxes, ha="right", va="top", fontsize=6.5, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
