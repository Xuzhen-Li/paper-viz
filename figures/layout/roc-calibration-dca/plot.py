"""Three-panel composite for risk models: (a) ROC with AUROC, (b) binned calibration curve
with ECE, (c) decision curve (net benefit against threshold probability) with treat-all and
treat-none references. All labels, the simulated-data note and the method notes sit inside
the frames. House style (styles/python/house.py). Reads data.csv only. Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent

# Parameters ---------------------------------------------------------------------------
cells = "3x2"
n_bins = 10                                # equal-width calibration bins
pt_grid = np.linspace(0.01, 0.60, 60)      # decision-curve threshold probabilities
label_pt = 0.45                            # where the model names sit on the decision curves


def lum(h):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def text_col(c, bg="#FFFFFF", need=3.0):
    a, b = sorted([lum(c), lum(bg)], reverse=True)
    return c if (a + 0.05) / (b + 0.05) >= need else "#1A1A1A"


def roc_xy(y, p):
    order = np.argsort(-p, kind="mergesort")
    ys = y[order]
    tp, fp = np.cumsum(ys), np.cumsum(1 - ys)
    tpr = np.concatenate(([0.0], tp / tp[-1]))
    fpr = np.concatenate(([0.0], fp / fp[-1]))
    return fpr, tpr, float(np.trapezoid(tpr, fpr))


def reliability(y, p, n_bins):
    edges = np.linspace(0.0, 1.0, n_bins + 1)
    idx = np.clip(np.digitize(p, edges) - 1, 0, n_bins - 1)
    mp, my, cnt = [], [], []
    for b in range(n_bins):
        m = idx == b
        if m.any():
            mp.append(p[m].mean()); my.append(y[m].mean()); cnt.append(int(m.sum()))
    mp, my, cnt = map(np.array, (mp, my, cnt))
    return mp, my, cnt, float(np.sum(cnt * np.abs(my - mp)) / cnt.sum())


def net_benefit(y, p, pt):
    pred = p >= pt
    n = len(y)
    return np.sum(pred & (y == 1)) / n - np.sum(pred & (y == 0)) / n * pt / (1.0 - pt)


rows = list(csv.DictReader((HERE / "data.csv").open()))
models = list(dict.fromkeys(r["model"] for r in rows))
data = {}
for m in models:
    sub = [r for r in rows if r["model"] == m]
    data[m] = (np.array([int(r["outcome"]) for r in sub]), np.array([float(r["predicted_risk"]) for r in sub]))
n_cases = len({r["case_id"] for r in rows})
y0 = data[models[0]][0]
prev = float(y0.mean())

hp = house.pv_palette("house")
cols = dict(zip(models, [hp[0], hp[3], hp[2], hp[4]]))  # blue, red: both >= 3:1 on white
grey = house.pv_palette("house_grey")
TEXT = "#1A1A1A"
ref = dict(color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=1)

house.apply_house_style()
import matplotlib.pyplot as plt  # noqa: E402
plt.rcParams["figure.constrained_layout.w_pad"] = 1.5 * house.MM
plt.rcParams["figure.constrained_layout.h_pad"] = 1.5 * house.MM
fig, ax0 = house.house_figure(cells=cells)
ax0.remove()
axd = fig.subplot_mosaic([["roc", "cal"], ["dca", "dca"]], height_ratios=[1.0, 0.85])
ax_roc, ax_cal, ax_dca = axd["roc"], axd["cal"], axd["dca"]

# a ROC ---------------------------------------------------------------------------------
ax_roc.plot([0, 1], [0, 1], **ref)
for k, m in enumerate(models):
    y, p = data[m]
    fpr, tpr, auc = roc_xy(y, p)
    ax_roc.plot(fpr, tpr, color=cols[m], lw=house.LW_PT["main"], zorder=2)
    ax_roc.text(0.97, 0.04 + 0.085 * (len(models) - k), f"{m}  AUROC = {auc:.2f}", transform=ax_roc.transAxes,
                color=text_col(cols[m]), fontsize=7, ha="right", va="bottom")
ax_roc.text(0.97, 0.04, "Dashed: chance", transform=ax_roc.transAxes, color=grey["mid"], fontsize=6.5,
            ha="right", va="bottom")
ax_roc.set_xlabel("False positive rate")
ax_roc.set_ylabel("True positive rate")
ax_roc.set_title("ROC", fontsize=8, loc="left", pad=2)

# b calibration ------------------------------------------------------------------------
ax_cal.plot([0, 1], [0, 1], **ref)
for k, m in enumerate(models):
    y, p = data[m]
    mp, my, cnt, ece = reliability(y, p, n_bins)
    ax_cal.plot(mp, my, color=cols[m], lw=house.LW_PT["main"], zorder=2)
    ax_cal.plot(mp, my, ls="none", color=cols[m], markerfacecolor=cols[m], zorder=3, **house.POINT)
    ax_cal.text(0.03, 0.96 - 0.085 * k, f"{m}  ECE = {ece:.3f}", transform=ax_cal.transAxes,
                color=text_col(cols[m]), fontsize=7, ha="left", va="top")
ax_cal.text(0.03, 0.96 - 0.085 * len(models), "Dashed: perfect calibration", transform=ax_cal.transAxes,
            color=grey["mid"], fontsize=6.5, ha="left", va="top")
ax_cal.set_xlabel("Mean predicted risk")
ax_cal.set_ylabel("Observed event rate")
ax_cal.set_title("Calibration", fontsize=8, loc="left", pad=2)

for ax in (ax_roc, ax_cal):
    ax.set_xlim(0, 1); ax.set_ylim(0, 1)
    ax.set_xticks([0, 0.25, 0.5, 0.75, 1.0]); ax.set_yticks([0, 0.25, 0.5, 0.75, 1.0])

# c decision curve ---------------------------------------------------------------------
nb_all = np.array([prev - (1 - prev) * pt / (1 - pt) for pt in pt_grid])
ax_dca.plot(pt_grid, nb_all, color=grey["dark"], lw=house.LW_PT["minor"], ls=(0, (2, 2)), zorder=1)
ax_dca.axhline(0.0, color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (1, 1)), zorder=1)
nb_at = {}
for m in models:
    y, p = data[m]
    nb = np.array([net_benefit(y, p, pt) for pt in pt_grid])
    ax_dca.plot(pt_grid, nb, color=cols[m], lw=house.LW_PT["main"], zorder=3)
    nb_at[m] = float(np.interp(label_pt, pt_grid, nb))
hi_first = sorted(models, key=lambda m: -nb_at[m])
for k, m in enumerate(hi_first):
    up = k == 0
    ax_dca.annotate(m, (label_pt, nb_at[m]), xytext=(0, 4.5 if up else -4.5), textcoords="offset points",
                    color=text_col(cols[m]), fontsize=7, ha="center", va="bottom" if up else "top")
x_all0 = prev  # treat-all crosses zero at pt = prevalence
ax_dca.text(x_all0 - 0.012, -0.012, "Treat all", color=grey["dark"], fontsize=6.5, ha="right", va="top")
ax_dca.text(0.015, -0.008, "Treat none", color=grey["mid"], fontsize=6.5, ha="left", va="top")
ax_dca.text(
    0.99, 0.95,
    f"Simulated data; n = {n_cases} cases, event rate = {prev:.2f}\n"
    f"Calibration: {n_bins} equal-width bins; ECE = count-weighted mean |observed - predicted|\n"
    "Net benefit = TP/n - (FP/n) x pt/(1 - pt), pt = threshold probability",
    transform=ax_dca.transAxes, color=grey["mid"], fontsize=6, ha="right", va="top", linespacing=1.25,
)
ymax = float(max(nb_all.max(), max(nb_at.values()))) * 1.12
ax_dca.set_xlim(0, pt_grid[-1])
ax_dca.set_ylim(-0.06, ymax)
ax_dca.set_xlabel("Threshold probability")
ax_dca.set_ylabel("Net benefit")
ax_dca.set_title("Decision curve", fontsize=8, loc="left", pad=2)

for ax, letter in ((ax_roc, "a"), (ax_cal, "b"), (ax_dca, "c")):
    house.add_house_tag(ax, letter)
house.save_house(fig, HERE / "figure")
print("wrote figure.pdf, figure.png, preview.png")
