"""Caterpillar plot of random-intercept estimates (BLUPs) with 95% intervals,
ordered by the estimate.
Variance components by method of moments (one-way random-effects ANOVA).
House style (2x3 cells, single axes, no bump). Reads data.csv only.
Run from this directory: python3 plot.py"""
import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import norm

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

LEVEL = 0.95
CELLS = (2, 3)
BAND = 4.6              # rows below this y are the in-frame key + footnote band
FS_NOTE = 6.5

rows = list(csv.DictReader(open("data.csv")))
groups = list(dict.fromkeys(r["group"] for r in rows))
vals = {g: np.array([float(r["y"]) for r in rows if r["group"] == g]) for g in groups}
n_j = np.array([vals[g].size for g in groups], dtype=float)
ybar = np.array([vals[g].mean() for g in groups])
N, J = int(n_j.sum()), len(groups)
grand = float(np.concatenate([vals[g] for g in groups]).mean())
sigma2 = sum(float(np.sum((vals[g] - vals[g].mean()) ** 2)) for g in groups) / (N - J)
msb = float(np.sum(n_j * (ybar - grand) ** 2)) / (J - 1)
n0 = (N - float(np.sum(n_j ** 2)) / N) / (J - 1)
tau2 = max(0.0, (msb - sigma2) / n0)
lam = n_j * tau2 / (n_j * tau2 + sigma2)
blup = lam * (ybar - grand)
se = np.sqrt(tau2 * sigma2 / (n_j * tau2 + sigma2))
z = float(norm.ppf(0.5 + LEVEL / 2))

o = np.argsort(blup)
names = [groups[i] for i in o]
est, half, raw = blup[o], z * se[o], (ybar - grand)[o]
ypos = np.arange(J) + BAND + 0.8

hp = house.pv_palette("house")
c = hp[0]
grey = house.pv_palette("house_grey")
ink = "#1A1A1A"

house.apply_house_style()
fig, ax = house.house_figure(cells=CELLS)

top = ypos.max() + 0.9
ax.plot([0, 0], [BAND, top], color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=1)
ax.errorbar(est, ypos, xerr=half, fmt="none", ecolor=c, elinewidth=house.LW_PT["minor"], capsize=0, zorder=2)
ax.plot(est, ypos, ls="none", markerfacecolor=c, zorder=4, **house.POINT)

ax.set_yticks(ypos)
ax.set_yticklabels(names)
ax.tick_params(axis="y", length=0)
ax.set_xlabel("Random intercept (deviation from grand mean, a.u.)")
lo = float((est - half).min())
hi = float((est + half).max())
pad = 0.06 * (hi - lo)
ax.set_xlim(lo - pad, hi + pad)
ax.set_ylim(0, top)
ax.axhline(BAND, color=grey["light"], lw=house.LW_PT["ref"], zorder=0)

# in-frame key (top line of the band)
x_k = 0.04
yk = BAND - 0.7
xr = ax.get_xlim()
def fx(f):
    return xr[0] + f * (xr[1] - xr[0])
ax.plot([fx(x_k - 0.025), fx(x_k + 0.025)], [yk, yk], color=c, lw=house.LW_PT["minor"])
ax.plot([fx(x_k)], [yk], ls="none", markerfacecolor=c, **house.POINT)
ax.text(fx(x_k + 0.045), yk, f"BLUP with {LEVEL:.0%} interval", color=c, fontsize=7, ha="left",
        va="center", in_layout=False)

note = (f"Simulated data. J = {J} groups, N = {N} observations\n"
        f"({int(n_j.min())}-{int(n_j.max())} per group). Random-intercept model;\n"
        f"method-of-moments tau = {np.sqrt(tau2):.2f}, sigma = {np.sqrt(sigma2):.2f}.\n"
        f"Interval: BLUP +/- {z:.2f} x conditional SE\n"
        f"(variance components treated as known).")
ax.text(0.015, 0.008, note, transform=ax.transAxes, color=ink, fontsize=FS_NOTE,
        ha="left", va="bottom", linespacing=1.2, in_layout=False)

house.save_house(fig, "figure", cells=CELLS)
print("wrote figure.pdf, figure.png, preview.png")
