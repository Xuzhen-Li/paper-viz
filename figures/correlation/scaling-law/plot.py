"""Scaling law (house style), v2: validation loss against model size on log-log axes, one colour per
training-token budget, each group fitted with L = E + A * N^(-alpha). Reads data.csv only.
v2 (layout review 1-1, 2-1): the footnote and the group labels are plain text (no mathtext), so every
glyph is set at the body size (8 pt after the 2x2 +2 pt bump; no 0.7x superscripts); x ticks only
at decades that hold data, so no tick sits in the label region on the right.
Run from this directory: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np
from matplotlib.ticker import FixedLocator, NullLocator, LogFormatterMathtext

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

# Parameters ---------------------------------------------------------------------------
x_label = "Parameters (non-embedding)"
y_label = "Validation loss (nats per token)"
y_ticks = [2.0, 2.5, 3.0, 3.5, 4.0]
group_label = "{:.0f}B tokens"          # tokens / 1e9
footnote = "Simulated data; fit: L = E + A N^(-\u03b1)"   # plain text, no mathtext
cells = "2x2"


def lum(h):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def text_col(c, bg="#FFFFFF", need=3.0):
    """Keep the data colour for a label when it has >= need:1 contrast, else near-black."""
    a, b = sorted([lum(c), lum(bg)], reverse=True)
    return c if (a + 0.05) / (b + 0.05) >= need else "#1A1A1A"


def fit_reducible(n, loss):
    """Grid search over the floor E; log-linear fit of (loss - E) on n. Returns E, A, alpha."""
    best = None
    for e in np.arange(0, loss.min() - 0.01, 0.002):
        slope, icpt = np.polyfit(np.log(n), np.log(loss - e), 1)
        sse = np.sum((e + np.exp(icpt) * n**slope - loss) ** 2)
        if best is None or sse < best[0]:
            best = (sse, e, np.exp(icpt), -slope)
    return best[1:]


rows = list(csv.DictReader(open("data.csv")))
n = np.array([float(r["params"]) for r in rows])
d = np.array([float(r["tokens"]) for r in rows])
loss = np.array([float(r["loss"]) for r in rows])
budgets = sorted(set(d))
cols = [house.pv_palette("house")[i] for i in (0, 2, 3)]   # blue, green, red: >= 3:1 on white

house.apply_house_style()
fig, ax = house.house_figure(cells=cells)
xs = np.logspace(np.log10(n.min()), np.log10(n.max()), 200)
for k, (b, c) in enumerate(zip(budgets, cols)):
    m = d == b
    e, a, alpha = fit_reducible(n[m], loss[m])
    ax.plot(xs, e + a * xs**-alpha, color=c, lw=house.LW_PT["main"], zorder=2)
    ax.plot(n[m], loss[m], ls="none", color=c, markerfacecolor=c, zorder=3, **house.POINT)
    yend = loss[m][np.argmax(n[m])]
    ax.text(n.max() * 1.35, yend, group_label.format(b / 1e9) + "\n" + f"\u03b1 = {alpha:.2f}",
            color=text_col(c), va="center", ha="left", linespacing=0.95)

ax.set_xscale("log")
ax.set_yscale("log")
# decades inside the data range only (2-1): nothing is ticked in the label region on the right
decades = [10.0**k for k in range(int(np.ceil(np.log10(n.min()))), int(np.floor(np.log10(n.max()))) + 1)]
ax.xaxis.set_major_locator(FixedLocator(decades))
ax.xaxis.set_major_formatter(LogFormatterMathtext())   # 9 pt ticks -> exponents 6.3 pt (checked in the PDF)
ax.xaxis.set_minor_locator(NullLocator())
ax.yaxis.set_major_locator(FixedLocator(y_ticks))
ax.yaxis.set_minor_locator(NullLocator())
ax.set_yticklabels([f"{t:.1f}" for t in y_ticks])
ax.set_xlim(n.min() / 1.6, n.max() * 22)
ax.set_ylim(min(loss) * 0.95, max(loss) * 1.04)
ax.set_xlabel(x_label)
ax.set_ylabel(y_label)
ax.text(0.03, 0.03, footnote, transform=ax.transAxes,
        color=house.pv_palette("house_grey")["mid"], fontsize=6, ha="left", va="bottom")
house.save_house(fig, "figure")
print("wrote figure.pdf, figure.png, preview.png")
