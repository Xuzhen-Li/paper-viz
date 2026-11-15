"""Specification curve: ranked estimates with CIs over an indicator grid of analysis choices; house style, 2x2."""
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
choice_cols = ["outcome", "covariates", "sample", "model"]
# ----

df = pd.read_csv(HERE / "data.csv").sort_values("estimate").reset_index(drop=True)
x = np.arange(len(df)); lo, hi = df.estimate - 1.96 * df.se, df.estimate + 1.96 * df.se
sig = lo > 0
levels = [(c, l) for c in choice_cols for l in dict.fromkeys(df[c])]
fig, (a, b) = house.house_figure(cells="2x2", nrows=2, sharex=True, gridspec_kw={"height_ratios": [1, 1.25]})
a.vlines(x, lo, hi, color=np.where(sig, PAL[0], GREY["ci"]), lw=0.6)
a.scatter(x, df.estimate, c=np.where(sig, PAL[0], GREY["mid"]), s=6, linewidths=0, zorder=3)
a.axhline(0, color=GREY["ref"], lw=LW["ref"], ls=(0, (2, 1.5)))
a.axhline(df.estimate.median(), color=PAL[3], lw=LW["minor"])
a.set_ylabel("Effect estimate")
a.text(0.03, 0.94, f"median = {df.estimate.median():.2f}; {sig.sum()}/{len(df)} with CI above 0",
       transform=a.transAxes, va="top", fontsize=6.5)
a.text(0.97, 0.06, "blue = CI excludes 0", transform=a.transAxes, ha="right", fontsize=6.5, color=PAL[0])
house.add_house_tag(a, "a")
for j, (c, l) in enumerate(levels):
    on = df[c] == l
    b.scatter(x[on], np.full(on.sum(), j), s=4, color=np.where(sig[on], PAL[0], GREY["mid"]), linewidths=0)
b.set_yticks(range(len(levels)), [l for _, l in levels], fontsize=6)
b.set_ylim(len(levels) - 0.5, -0.5)
bounds = np.cumsum([df[c].nunique() for c in choice_cols])[:-1] - 0.5
for y in bounds: b.axhline(y, color=GREY["light"], lw=0.5)
b.set_xlabel("Specification (ranked by estimate)")
b.set_xlim(-1, len(df))
house.add_house_tag(b, "b")
a.text(0.03, 0.06, "Simulated data", transform=a.transAxes, fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure", bump=0)
