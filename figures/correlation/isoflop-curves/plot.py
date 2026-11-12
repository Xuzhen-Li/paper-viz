"""Isoflop curves (a) and compute-optimal model size (b). Layout idea only.
Simulated data from a Chinchilla-style parametric loss plus noise.
Reads data.csv only. Run from this directory: python3 plot.py
v4 (2026-11-13): placement only. The panel-a key (fit lines / diamonds) is merged
into the upper-right footnote block, and the panel-b slope label moves to the
lower-right corner. Data, canvas (3x1), ranges, colours and labels as v3."""
import csv
import sys
from pathlib import Path

import numpy as np
from matplotlib.ticker import FuncFormatter, NullFormatter

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

x_label_a = "Parameters"
y_label_a = "Final training loss"
x_label_b = "Training FLOPs"
y_label_b = "Optimal parameters"
# Short lines so the block fits in panel a's empty upper-right (about 1e11-4e12, y 3.0-4.2);
# top at 4.20 and tight line spacing keep the last line clear of the 6e20 label.
# v4: the fit/diamond key joins this block (wrapped to the block width) instead of
# sitting on the 6e18 curve.
footnote = "\n".join([
    "Simulated data",
    "Chinchilla-style form",
    "L = E + A/N^a + B/D^b",
    "Hoffmann et al. 2022",
    "arXiv:2203.15556",
    "Lines: quadratic fit",
    "in log N",
    "Diamonds: fitted",
    "minimum",
])
cells = "3x1"


def lum(h):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def text_col(c, bg="#FFFFFF", need=3.0):
    a, b = sorted([lum(c), lum(bg)], reverse=True)
    return c if (a + 0.05) / (b + 0.05) >= need else "#1A1A1A"


def plain_log_tick(x, _pos=None):
    """Plain-text scientific tick, e.g. 1e19, so no mathtext exponent."""
    if x <= 0:
        return ""
    exp = int(np.floor(np.log10(x) + 1e-12))
    coef = x / (10.0 ** exp)
    if abs(coef - 1.0) < 1e-8:
        return f"1e{exp}"
    rounded = int(np.round(coef))
    if abs(coef - rounded) < 1e-6 and 1 <= rounded <= 9:
        return f"{rounded}e{exp}"
    return f"{x:.0e}".replace("e+0", "e").replace("e+", "e").replace("e-0", "e-")


def apply_plain_log(axis):
    axis.set_major_formatter(FuncFormatter(plain_log_tick))
    axis.set_minor_formatter(NullFormatter())


def tag_inside(ax, letter):
    """10 pt bold panel letter inside the frame (a 3x1 canvas clips add_house_tag)."""
    ax.text(
        0.015, 0.97, letter.lower(), transform=ax.transAxes,
        fontsize=10, fontweight="bold", ha="left", va="top", color="#000000",
    )


rows = list(csv.DictReader(Path(__file__).with_name("data.csv").open()))
pal = house.pv_palette("house")
cols = [pal[i] for i in (4, 0, 2, 1, 3)]
grey = house.pv_palette("house_grey")

house.apply_house_style()
fig, (ax, bx) = house.house_figure(
    cells=cells, ncols=2, gridspec_kw={"width_ratios": [1.9, 1.0]},
)

budgets = sorted({float(r["compute_flops"]) for r in rows})
optN, optL = [], []
for C, c in zip(budgets, cols):
    sub = [r for r in rows if float(r["compute_flops"]) == C]
    N = np.array([float(r["params"]) for r in sub])
    L = np.array([float(r["loss"]) for r in sub])
    o = np.argsort(N)
    N, L = N[o], L[o]
    p = np.polyfit(np.log10(N), L, 2)
    xs = np.linspace(np.log10(N).min(), np.log10(N).max(), 100)
    ax.plot(10 ** xs, np.polyval(p, xs), color=c, lw=house.LW_PT["main"], zorder=2)
    ax.scatter(N, L, color=c, zorder=3, **house.SCATTER)
    xm = -p[1] / (2 * p[0])
    optN.append(10 ** xm)
    optL.append(np.polyval(p, xm))
    label = f"{C:.0e}".replace("e+", "e") + (" FLOPs" if C == budgets[0] else "")
    ax.text(
        N[-1] * 1.35, L[-1], label,
        color=text_col(c), fontsize=7, va="center", ha="left",
    )
ax.scatter(optN, optL, marker="D", s=12, color="#000000", zorder=4, linewidths=0)
ax.set_xscale("log")
apply_plain_log(ax.xaxis)
ax.set_xticks([1e8, 1e9, 1e10, 1e11, 1e12])
# Extra decade on the right so the compact footnote and end labels stay inside.
ax.set_xlim(5e7, 4e12)
ax.set_ylim(2.15, 4.22)
ax.set_xlabel(x_label_a)
ax.set_ylabel(y_label_a)
# Footnote in the empty upper-right of panel a, inside the frame.
ax.text(
    1.2e11, 4.20, footnote,
    fontsize=6, color=grey["mid"], ha="left", va="top", linespacing=1.05,
)

lc, ln = np.log10(budgets), np.log10(optN)
k, b0 = np.polyfit(lc, ln, 1)
bx.scatter(budgets, optN, color=pal[0], zorder=3, **house.SCATTER)
xx = np.linspace(lc.min() - 0.3, lc.max() + 0.3, 50)
bx.plot(10 ** xx, 10 ** (k * xx + b0), color=pal[0], lw=house.LW_PT["main"], zorder=2)
bx.set_xscale("log")
bx.set_yscale("log")
apply_plain_log(bx.xaxis)
bx.set_xticks([1e19, 1e20, 1e21])
bx.set_yticks([2e8, 5e8, 1e9, 2e9])
bx.set_yticklabels(["0.2B", "0.5B", "1B", "2B"])
bx.yaxis.set_minor_formatter(NullFormatter())
bx.set_xlabel(x_label_b)
bx.set_ylabel(y_label_b)
# v4: lower-right empty corner, clear of the fit line and points.
bx.text(
    0.95, 0.06, f"log-log slope = {k:.2f}",
    transform=bx.transAxes, color=text_col(pal[0]), fontsize=7,
    ha="right", va="bottom",
)

tag_inside(ax, "a")
tag_inside(bx, "b")
house.save_house(fig, "figure", cells=cells)
print("wrote figure.pdf, figure.png, preview.png")
