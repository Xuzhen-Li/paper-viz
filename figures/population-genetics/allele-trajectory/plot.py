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
loci = {"LCT-like": PAL[1], "SLC-like": PAL[0], "Neutral": GREY["mid"]}
gen_years = 29
# ----

df = pd.read_csv(HERE / "data.csv")


def fit(d):
    """Grid MLE of a logistic trajectory p(t) = 1 / (1 + exp(-s (t0 - t) / g)); s = 0 means constant p."""
    t, n, k = d.years_bp.values, d.n_chrom.values, d.n_derived.values
    best = (-np.inf, 0, 0, k.sum() / n.sum())
    for s in np.linspace(0.002, 0.08, 80):
        for t0 in np.linspace(-2000, 14000, 161):
            p = np.clip(1 / (1 + np.exp(-s * (t0 - t) / gen_years)), 1e-6, 1 - 1e-6)
            ll = np.sum(k * np.log(p) + (n - k) * np.log(1 - p))
            if ll > best[0]:
                best = (ll, s, t0, None)
    p0 = k.sum() / n.sum(); ll0 = np.sum(k * np.log(p0) + (n - k) * np.log(1 - p0))
    return best[1], best[2], 2 * (best[0] - ll0)


def wilson(k, n, z=1.96):
    p = k / n; d = 1 + z ** 2 / n
    c = (p + z ** 2 / (2 * n)) / d; h = z * np.sqrt(p * (1 - p) / n + z ** 2 / (4 * n ** 2)) / d
    return c - h, c + h


fig, ax = house.house_figure(cells="3x2")
tt = np.linspace(11000, 0, 300); lines = []
for name, col in loci.items():
    d = df[df.locus == name]; p = d.n_derived / d.n_chrom
    lo, hi = wilson(d.n_derived.values, d.n_chrom.values)
    ax.vlines(d.years_bp, lo, hi, color=col, lw=LW["errorbar"], alpha=0.6)
    ax.scatter(d.years_bp, p, s=d.n_chrom / 3, color=col, edgecolors="black", linewidths=0.3, zorder=3)
    s, t0, lr = fit(d)
    if lr > 3.84:
        ax.plot(tt, 1 / (1 + np.exp(-s * (t0 - tt) / gen_years)), color=col, lw=LW["main"])
        lines.append((f"{name}: s = {s:.3f} per generation", col))
    else:
        lines.append((f"{name}: no fit (LR < 3.84)", col))
ax.set_xlim(11000, -300); ax.set_ylim(-0.03, 1.03)
ax.set_xlabel("Years before present"); ax.set_ylabel("Derived allele frequency")
for k, (t_, col) in enumerate(lines):
    ax.text(0.02, 0.97 - k * 0.055, t_, transform=ax.transAxes, va="top", fontsize=7, color=col)
ax.text(0.02, 0.97 - len(lines) * 0.055, "logistic MLE; curve drawn if LR > 3.84\n(1 df, 5% level, no correction)\nbars: Wilson 95% CI; size = chromosomes\nsimulated data",
        transform=ax.transAxes, va="top", fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
