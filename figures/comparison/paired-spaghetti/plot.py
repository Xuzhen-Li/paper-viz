"""Paired before/after spaghetti plot: one thin line per subject joining its two
conditions, one panel per group, with the condition mean and 95% t CI beside each end
and the mean within-subject change (95% t CI) printed in the panel. Only subjects with
both conditions are drawn; n is counted from data.csv. House style. Run: python3 plot.py"""
import csv
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np
from scipy.stats import t as tdist

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent
# Parameters ---------------------------------------------------------------------------
cells = "2x2"
y_label = "Response (a.u.)"
ci_level = 0.95
mean_offset = 0.16      # mean +/- CI drawn this far outside each condition


def lum(h):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def text_col(c, bg="#FFFFFF", need=3.0):
    a, b = sorted([lum(c), lum(bg)], reverse=True)
    return c if (a + 0.05) / (b + 0.05) >= need else "#1A1A1A"


def t_ci(x, level):
    m = float(np.mean(x))
    h = float(tdist.ppf(0.5 + level / 2, len(x) - 1) * np.std(x, ddof=1) / np.sqrt(len(x)))
    return m, m - h, m + h


rows = list(csv.DictReader((HERE / "data.csv").open()))
conds = list(dict.fromkeys(r["condition"] for r in rows))
if len(conds) != 2:
    raise ValueError(f"expected 2 conditions, got {conds!r}")
groups = list(dict.fromkeys(r["group"] for r in rows))
vals = defaultdict(dict)
grp = {}
for r in rows:
    vals[r["subject"]][r["condition"]] = float(r["value"])
    grp[r["subject"]] = r["group"]
pairs = {g: np.array([[v[c] for c in conds] for s, v in vals.items() if grp[s] == g and all(c in v for c in conds)])
         for g in groups}

hp = house.pv_palette("house")
cols = dict(zip(groups, [hp[4], hp[0], hp[2], hp[3]]))
grey = house.pv_palette("house_grey")
TEXT = "#1A1A1A"
allv = np.concatenate([p.ravel() for p in pairs.values()])
span = allv.max() - allv.min()
ylim = (allv.min() - 0.16 * span, allv.max() + 0.30 * span)
pct = int(round(ci_level * 100))

house.apply_house_style()
import matplotlib.pyplot as plt  # noqa: E402
plt.rcParams["figure.constrained_layout.w_pad"] = 1.5 * house.MM  # keep the y-axis title on the page
plt.rcParams["figure.constrained_layout.h_pad"] = 1.5 * house.MM
fig, axes = house.house_figure(cells=cells, nrows=1, ncols=len(groups), sharey=True)
for k, (ax, g) in enumerate(zip(np.atleast_1d(axes), groups)):
    c = cols[g]
    P = pairs[g]
    n = len(P)
    for a, b in P:
        ax.plot([0, 1], [a, b], color=c, lw=house.LW_PT["minor"], alpha=0.45, zorder=1, solid_capstyle="round")
    ax.plot(np.zeros(n), P[:, 0], ls="none", marker="o", ms=2.6, mfc=c, mec="none", alpha=0.6, zorder=2)
    ax.plot(np.ones(n), P[:, 1], ls="none", marker="o", ms=2.6, mfc=c, mec="none", alpha=0.6, zorder=2)
    for j, x in enumerate((-mean_offset, 1 + mean_offset)):
        m, lo, hi = t_ci(P[:, j], ci_level)
        ax.plot([x, x], [lo, hi], color=c, lw=house.LW_PT["errorbar"] * 1.3, zorder=3)
        ax.plot([x], [m], ls="none", color=c, markerfacecolor=c, zorder=4, **house.POINT)
    d = P[:, 1] - P[:, 0]
    md, dlo, dhi = t_ci(d, ci_level)
    up = int(np.sum(d > 0))
    tc = text_col(c)
    ax.text(0.5, 0.975, g, transform=ax.transAxes, color=tc, fontsize=8, ha="center", va="top")
    ax.text(0.5, 0.905,
            f"n = {n} pairs; {up} of {n} increased\nMean change {md:+.2f}\n{pct}% CI {dlo:+.2f} to {dhi:+.2f}",
            transform=ax.transAxes, color=tc, fontsize=6.5, ha="center", va="top", linespacing=1.2)
    ax.set_xticks([0, 1]); ax.set_xticklabels(conds)
    ax.set_xlim(-0.42, 1.42)
    ax.set_ylim(*ylim)
    house.add_house_tag(ax, chr(ord("a") + k))
np.atleast_1d(axes)[0].set_ylabel(y_label)
np.atleast_1d(axes)[0].text(
    0.04, 0.025, f"Simulated data\nThin lines: subjects\nPoint, bar: mean, {pct}% t CI",
    transform=np.atleast_1d(axes)[0].transAxes, color=grey["mid"], fontsize=6, ha="left", va="bottom", linespacing=1.2)
house.save_house(fig, HERE / "figure")
print("wrote figure.pdf, figure.png, preview.png")
