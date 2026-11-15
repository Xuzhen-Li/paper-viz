"""Reliability diagrams (house style), v2: one panel per model; bars = observed accuracy in each
equal-width confidence bin, dashed diagonal = perfect calibration, expected calibration error (ECE)
and n computed from data.csv. v2 (layout review 1-6, 1-7, 2-5): imports only styles/python/house.py
(no redraws/_lib helper), on-figure "Simulated data" footnote, panel-b label in a dark orange with
>= 3:1 contrast on white. Run from this directory: python3 plot.py"""
import csv
import sys
from pathlib import Path

import matplotlib as mpl
import numpy as np

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

# Parameters ---------------------------------------------------------------------------
cells = "2x1"
bins = np.linspace(0, 1, 11)               # 10 equal-width confidence bins
x_label = "Confidence"
y_label = "Accuracy"
footnote = "Simulated data"
pal = house.pv_palette("house")
colours = [pal[0], pal[1]]                 # bar colours: house blue, house orange
grey = house.pv_palette("house_grey")


def lum(c):
    f = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = mpl.colors.to_rgb(c)
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(c, bg="#FFFFFF"):
    a, b = sorted([lum(c), lum(bg)], reverse=True)
    return (a + 0.05) / (b + 0.05)


def text_col(c, need=3.0):
    """Darken a colour in small steps until it has >= need:1 contrast on white (keeps the hue)."""
    r, g, b = mpl.colors.to_rgb(c)
    k = 1.0
    while contrast((r * k, g * k, b * k)) < need:
        k -= 0.02
    return mpl.colors.to_hex((r * k, g * k, b * k))


def tint(c, a):
    r, g, b = mpl.colors.to_rgb(c)
    return (1 - a + a * r, 1 - a + a * g, 1 - a + a * b)


def reliability(p, y):
    idx = np.clip(np.digitize(p, bins) - 1, 0, len(bins) - 2)
    k = len(bins) - 1
    n = np.bincount(idx, minlength=k)
    acc = np.array([y[idx == j].mean() if n[j] else np.nan for j in range(k)])
    conf = np.array([p[idx == j].mean() if n[j] else np.nan for j in range(k)])
    ece = np.nansum(n / n.sum() * np.abs(acc - conf))
    return acc, ece, int(n.sum())


with open("data.csv", newline="") as fh:
    rows = list(csv.DictReader(fh))
models = list(dict.fromkeys(r["model"] for r in rows))

house.apply_house_style()
fig, axs = house.house_figure(cells=cells, ncols=2, sharey=True)
ns = []
for j, (ax, m) in enumerate(zip(axs, models)):
    p = np.array([float(r["confidence"]) for r in rows if r["model"] == m])
    y = np.array([int(r["correct"]) for r in rows if r["model"] == m])
    acc, ece, n = reliability(p, y)
    ns.append(n)
    c = colours[j]
    w = bins[1] - bins[0]
    ax.bar(bins[:-1] + w / 2, acc, width=w * 0.92, color=tint(c, 0.55), edgecolor=c, lw=0.5, zorder=2)
    ax.plot([0, 1], [0, 1], color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (3, 2)), zorder=3)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_xlabel(x_label)
    ax.text(0.04, 0.95, f"{m}\nECE = {ece:.3f}", transform=ax.transAxes, va="top", fontsize=7, color=text_col(c))
    house.add_house_tag(ax, "ab"[j])
axs[0].set_ylabel(y_label)
axs[0].text(0.04, 0.60, "Dashed: perfect\ncalibration", transform=axs[0].transAxes, ha="left", fontsize=6.5, color=grey["mid"])
n_txt = f"n = {ns[0]} each" if len(set(ns)) == 1 else "n = " + " / ".join(str(v) for v in ns)
note = axs[1].text(0.04, 0.74, f"{footnote};\n{n_txt}", transform=axs[1].transAxes,
                   ha="left", va="top", fontsize=6, color=grey["mid"], linespacing=1.1)
house.save_house(fig, "figure")
# the footnote must stay above the dashed identity line (its lower-right corner lies above y = x)
bb = note.get_window_extent(fig.canvas.get_renderer()).transformed(axs[1].transData.inverted())
assert bb.y0 > bb.x1 + 0.02 and bb.y1 < 1, ("footnote touches the identity line or frame", bb)
print(f"footnote box (data units): x {bb.x0:.2f}-{bb.x1:.2f}, y {bb.y0:.2f}-{bb.y1:.2f}")
print("label colours:", [text_col(c) for c in colours], "contrast:", [round(contrast(text_col(c)), 2) for c in colours])
print("n per model:", ns)
print("wrote figure.pdf, figure.png, preview.png")
