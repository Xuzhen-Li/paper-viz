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
models = {"risk_a": ("Model A", PAL[0]), "risk_b": ("Model B", PAL[1])}
thresholds = np.arange(0.01, 0.61, 0.01)
# ----

df = pd.read_csv(HERE / "data.csv")
y = df.outcome.values; n = len(y); prev = y.mean()


def net_benefit(risk, pt):
    t = risk >= pt
    tp = np.sum(t & (y == 1)) / n; fp = np.sum(t & (y == 0)) / n
    return tp - fp * pt / (1 - pt)


fig, ax = house.house_figure(cells="2x2")
nb_all = prev - (1 - prev) * thresholds / (1 - thresholds)
ax.plot(thresholds, nb_all, color=GREY["mid"], lw=LW["minor"])
ax.axhline(0, color="black", lw=LW["minor"])
curves = {}
for col, (lab, c) in models.items():
    nb = np.array([net_benefit(df[col].values, p) for p in thresholds]); curves[col] = nb
    ax.plot(thresholds, nb, color=c, lw=LW["main"])
ax.set_ylim(-0.05, prev * 1.15); ax.set_xlim(0, thresholds.max())
ax.set_xlabel("Threshold probability"); ax.set_ylabel("Net benefit")
# direct labels at the right end of each curve
ax.text(0.31, curves["risk_a"][30] + 0.012, "Model A", color=PAL[0], fontsize=7)
ax.text(0.145, curves["risk_b"][14] - 0.016, "Model B", color=PAL[1], fontsize=7, ha="right", va="top")
ax.text(0.268, -0.04, "Treat all", color=GREY["mid"], fontsize=7, va="center")
ax.text(0.5, 0.004, "Treat none", color="black", fontsize=7, va="bottom")
useful = thresholds[(curves["risk_a"] > np.maximum(nb_all, 0) + 0.005) & (curves["risk_a"] > curves["risk_b"])]
ax.axvspan(useful.min(), useful.max(), color=GREY["bg"], lw=0, zorder=0)
ax.text(0.97, 0.97, f"n = {n}, prevalence = {prev:.2f}\nA best for thresholds\n{useful.min():.2f} to {useful.max():.2f} (grey band)\nsimulated data",
        transform=ax.transAxes, ha="right", va="top", fontsize=6.5)
ax.text(0.97, 0.66, "net benefit = TP/n - FP/n x pt / (1 - pt)", transform=ax.transAxes, ha="right", fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
