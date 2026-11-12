"""Mendelian randomisation scatter: SNP effects with error bars and IVW / MR-Egger slopes; house style, 2x2."""
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
x_label, y_label = "SNP effect on exposure", "SNP effect on outcome"
# ----

df = pd.read_csv(HERE / "data.csv")
bx, by, sy, sx = df.beta_exposure.values, df.beta_outcome.values, df.se_outcome.values, df.se_exposure.values
w = 1 / sy ** 2
ivw = np.sum(w * bx * by) / np.sum(w * bx ** 2)                       # IVW through the origin
ivw_se = np.sqrt(1 / np.sum(w * bx ** 2))
X = np.c_[np.ones_like(bx), bx]; W = np.diag(w)                        # MR-Egger: weighted regression with intercept
beta = np.linalg.solve(X.T @ W @ X, X.T @ W @ by)
fig, ax = house.house_figure(cells="2x2")
ax.errorbar(bx, by, xerr=1.96 * sx, yerr=1.96 * sy, fmt="none", ecolor=GREY["ci"], lw=0.5, zorder=1)
ax.scatter(bx, by, color=PAL[0], zorder=3, **house.SCATTER)
xx = np.linspace(0, bx.max() * 1.08, 50)
ax.plot(xx, ivw * xx, color=PAL[1], lw=LW["main"])
ax.plot(xx, beta[0] + beta[1] * xx, color=PAL[2], lw=LW["main"], ls=(0, (3, 1.5)))
ax.axhline(0, color=GREY["ref"], lw=LW["ref"])
ax.set_xlim(0, bx.max() * 1.1); ax.set_xlabel(x_label); ax.set_ylabel(y_label)
ax.text(0.04, 0.95, f"IVW slope {ivw:.2f} (95% CI {ivw - 1.96 * ivw_se:.2f} to {ivw + 1.96 * ivw_se:.2f})", transform=ax.transAxes, va="top", color=PAL[1], fontsize=7)
ax.text(0.04, 0.88, f"MR-Egger slope {beta[1]:.2f}, intercept {beta[0]:.3f}", transform=ax.transAxes, va="top", color=PAL[2], fontsize=7)
ax.text(0.96, 0.04, f"{len(df)} instruments; bars = 95% CI; simulated data", transform=ax.transAxes, ha="right", fontsize=6.5, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
