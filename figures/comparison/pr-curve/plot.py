"""Classic precision-recall curves for several classifiers on the same items, with the
random-classifier baseline (precision = positive-class prevalence) and average precision
labelled in the model colour. n_pos and n_neg are counted from data.csv. Single 2x2 panel:
house text +2 pt is applied up front (apply_house_style(single_panel=True)), labels are placed
at printed size and save_house adds nothing more. Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "2x2"
x_label = "Recall"
y_label = "Precision"
footnote = "Simulated data"


def lum(h):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def text_col(c, bg="#FFFFFF", need=3.0):
    a, b = sorted([lum(c), lum(bg)], reverse=True)
    return c if (a + 0.05) / (b + 0.05) >= need else "#1A1A1A"


def pr_and_ap(y, scores):
    """Precision-recall curve and average precision (sum of P at each new recall)."""
    y = np.asarray(y, int)
    scores = np.asarray(scores, float)
    n_pos = int(y.sum())
    n_neg = int(len(y) - n_pos)
    if n_pos == 0:
        raise SystemExit("no positive labels in a model slice of data.csv")
    order = np.argsort(-scores, kind="mergesort")
    y_s = y[order]
    tp = np.cumsum(y_s)
    fp = np.cumsum(1 - y_s)
    recall = tp / n_pos
    precision = tp / np.maximum(tp + fp, 1)
    r = np.concatenate([[0.0], recall])
    p = np.concatenate([[1.0], precision])
    ap = 0.0
    prev_r = 0.0
    for i in range(len(y_s)):
        if y_s[i] == 1:
            ap += (recall[i] - prev_r) * precision[i]
            prev_r = recall[i]
    return r, p, float(ap), n_pos, n_neg


rows = list(csv.DictReader(Path(__file__).with_name("data.csv").open()))
models = list(dict.fromkeys(r["model"] for r in rows))
hp = house.pv_palette("house")
cols = [hp[0], hp[3], hp[2]]
grey = house.pv_palette("house_grey")

curves = []
for m in models:
    sl = [r for r in rows if r["model"] == m]
    y = np.array([int(r["label"]) for r in sl])
    s = np.array([float(r["score"]) for r in sl])
    r, p, ap, n_pos, n_neg = pr_and_ap(y, s)
    curves.append((m, r, p, ap, n_pos, n_neg))

n_pos0, n_neg0 = curves[0][4], curves[0][5]
if len({(cv[4], cv[5]) for cv in curves}) != 1:
    raise SystemExit("models must be scored on the same items (same n_pos / n_neg)")
prev = n_pos0 / (n_pos0 + n_neg0)

house.apply_house_style(single_panel=True)
import matplotlib.pyplot as plt  # noqa: E402
plt.rcParams["figure.constrained_layout.w_pad"] = 1.5 * house.MM  # keep the y-axis title on the page
fig, ax = house.house_figure(cells=cells)
ax.axhline(prev, color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=1)

for (m, r, p, ap, n_pos, n_neg), c in zip(curves, cols):
    ax.plot(r, p, color=c, lw=house.LW_PT["main"], zorder=2)

# AP labels sit in the open lower-left region, above the footnote and baseline
# best model first so the label order matches the curve order from top to bottom
order = sorted(range(len(curves)), key=lambda i: -curves[i][3])
ax.text(0.03, 0.40, "Average precision", transform=ax.transAxes, color=grey["mid"],
        fontsize=7.5, ha="left", va="top")
for k, i in enumerate(order):
    m, r, p, ap, n_pos, n_neg = curves[i]
    ax.text(0.03, 0.335 - 0.065 * k, f"{m}  {ap:.2f}",
            transform=ax.transAxes, color=text_col(cols[i]), fontsize=8.5, ha="left", va="top")

ax.text(0.03, prev - 0.015, f"Random classifier: precision = prevalence = {prev:.2f}",
        color=grey["mid"], fontsize=7.5, ha="left", va="top",
        transform=ax.get_yaxis_transform())

ax.set_xlim(0, 1.0)
ax.set_ylim(0, 1.02)
ax.set_xticks([0, 0.25, 0.50, 0.75, 1.00])
ax.set_yticks([0, 0.25, 0.50, 0.75, 1.00])
ax.set_xlabel(x_label)
ax.set_ylabel(y_label)
ax.text(
    0.03, 0.03,
    f"{footnote}; n = {n_pos0} positive, {n_neg0} negative items",
    transform=ax.transAxes, color=grey["mid"], fontsize=7, ha="left", va="bottom", linespacing=1.2,
)

house.save_house(fig, "figure", bump=0)
print("wrote figure.pdf, figure.png, preview.png")
