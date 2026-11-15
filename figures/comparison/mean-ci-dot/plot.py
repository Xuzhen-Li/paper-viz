"""Means with 95% bootstrap CIs as dots and intervals (not a dynamite bar
chart). n is counted from data.csv. Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "2x1"
n_boot = 5000
rng_seed = 20261123
y_label = "Response (a.u.)"
footnote = "Simulated data; lines: 95% bootstrap CI (percentile, 5000 resamples)"


def lum(h):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def text_col(c, bg="#FFFFFF", need=3.0):
    a, b = sorted([lum(c), lum(bg)], reverse=True)
    return c if (a + 0.05) / (b + 0.05) >= need else "#1A1A1A"


def boot_mean_ci(x, n_boot, rng):
    means = np.array([rng.choice(x, len(x), replace=True).mean() for _ in range(n_boot)])
    lo, hi = np.percentile(means, [2.5, 97.5])
    return float(x.mean()), float(lo), float(hi)


rows = list(csv.DictReader(Path(__file__).with_name("data.csv").open()))
conditions = list(dict.fromkeys(r["condition"] for r in rows))
rng = np.random.default_rng(rng_seed)
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")

house.apply_house_style()
fig, ax = house.house_figure(cells=cells)

los, his = [], []
for i, name in enumerate(conditions):
    x = np.array([float(r["value"]) for r in rows if r["condition"] == name])
    m, lo, hi = boot_mean_ci(x, n_boot, rng)
    n = int(len(x))
    los.append(lo)
    his.append(hi)
    c = hp[i % len(hp)]
    ax.plot([i, i], [lo, hi], color=c, lw=1.0, solid_capstyle="butt", zorder=2)
    ax.plot(i, m, "o", color=c, markersize=6.0, markeredgecolor="#000000",
            markeredgewidth=house.POINT["markeredgewidth"], zorder=3)
    # n label 2 pt above the upper CI end (clear of the line)
    ax.annotate(f"n = {n}", xy=(i, hi), xytext=(0, 2.0), textcoords="offset points",
                color=text_col(c), ha="center", va="bottom", fontsize=6.5)

ax.set_xticks(range(len(conditions)))
ax.set_xticklabels(conditions)
ax.set_ylabel(y_label)
ax.set_xlim(-0.6, len(conditions) - 0.4)
span = max(his) - min(los)
# headroom for the n labels on top, footroom for the in-frame footnote
ax.set_ylim(min(los) - 0.30 * span, max(his) + 0.20 * span)
ax.text(0.015, 0.035, footnote, transform=ax.transAxes, color=grey["mid"],
        fontsize=6, ha="left", va="bottom")

house.save_house(fig, "figure")
print("wrote figure.pdf, figure.png, preview.png")
