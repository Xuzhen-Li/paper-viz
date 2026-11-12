"""Funnel plot with pseudo 95% limits, fixed-effect estimate and Egger test; house style, 2x2."""
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
from math import erf, sqrt

# ---- parameters
x_label = "Log odds ratio"
# ----

df = pd.read_csv(HERE / "data.csv")
y, se = df.log_or.values, df.se.values
w = 1 / se ** 2; fe = np.sum(w * y) / np.sum(w)
# Egger regression: standardised effect on precision; intercept tests asymmetry
X = np.c_[np.ones_like(se), 1 / se]; z = y / se
coef, res, *_ = np.linalg.lstsq(X, z, rcond=None)
resid = z - X @ coef; s2 = resid @ resid / (len(z) - 2)
se_b0 = np.sqrt(s2 * np.linalg.inv(X.T @ X)[0, 0]); t0 = coef[0] / se_b0
p_norm = 2 * (1 - 0.5 * (1 + erf(abs(t0) / sqrt(2))))          # normal approximation to the t test
fig, ax = house.house_figure(cells="2x2")
ss = np.linspace(0, se.max() * 1.08, 50)
ax.fill_betweenx(ss, fe - 1.96 * ss, fe + 1.96 * ss, color=GREY["bg"], lw=0)
ax.plot(fe - 1.96 * ss, ss, color=GREY["mid"], lw=LW["ref"], ls=(0, (2, 1.5))); ax.plot(fe + 1.96 * ss, ss, color=GREY["mid"], lw=LW["ref"], ls=(0, (2, 1.5)))
top = se.max() * 1.08
ax.plot([fe, fe], [0, top], color=PAL[1], lw=LW["minor"]); ax.plot([0, 0], [0, top], color="black", lw=0.5)
ax.scatter(y, se, color=PAL[0], zorder=3, **house.SCATTER)
ax.set_ylim(se.max() * 1.08, -0.2); ax.set_ylabel("Standard error"); ax.set_xlabel(x_label)
ax.text(0.03, 0.98, f"fixed effect = {fe:.2f} (orange)\nEgger intercept = {coef[0]:.2f}\nP = {p_norm:.2f} (two-sided, normal approx.)",
        transform=ax.transAxes, va="top", fontsize=6.5)
ax.set_xlim(fe - 1.96 * top * 1.05, fe + 1.96 * top * 1.05)
ax.set_yticks([0, 0.1, 0.2, 0.3, 0.4, 0.5])
ax.text(0.97, 0.98, f"{len(df)} studies\ngrey: 95% limits\nsimulated data", transform=ax.transAxes, ha="right", va="top", fontsize=6.5, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
