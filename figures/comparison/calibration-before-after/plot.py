"""Reliability diagrams before and after temperature scaling (house style), one simulated
10-class classifier, all from data.csv:
a  raw softmax (T = 1) on the test split; b  same logits divided by the temperature T fitted on
   the val split (minimum mean negative log-likelihood); bars = accuracy per equal-width
   confidence bin, red = gap to the bin's mean confidence, dashed = perfect calibration;
   ECE = sum over bins of (n_bin / n) * |accuracy - mean confidence|, printed in each panel;
c  test examples per confidence bin before and after; d  val negative log-likelihood vs T.
Temperature scaling does not change the predicted class, so accuracy is the same in a and b.
Simulated data. Run from this directory: python3 plot.py
v2: only the panel-d "T = 1 / NLL" label position changed (now fully inside the axes)."""
import csv
import sys
from pathlib import Path

import matplotlib as mpl
import numpy as np
from matplotlib.patches import Patch
from scipy.optimize import minimize_scalar

HERE = Path(__file__).resolve().parent
STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

# Parameters ---------------------------------------------------------------------------
cells = "4x2"                         # 183 x 89 mm
n_bins = 10                           # equal-width confidence bins on [0, 1]
ece_decimals = 3
small_n = 30                          # bins with fewer test examples get their n printed
t_bounds = (0.25, 10.0)               # search range for the temperature
footnote = "Simulated data"
pal = house.pv_palette("house")
grey = house.pv_palette("house_grey")
acc_col, gap_col = pal[0], pal[3]     # house blue bars, house red gap
before_col, after_col = pal[1], pal[0]
before_text, after_text = "#B95E0E", "#1F72AE"   # text-safe darks on white


def lum(c):
    f = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = mpl.colors.to_rgb(c)
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(a, b="#FFFFFF"):
    x, y = sorted([lum(a), lum(b)], reverse=True)
    return (x + 0.05) / (y + 0.05)


def tint(c, a):
    r, g, b = mpl.colors.to_rgb(c)
    return mpl.colors.to_hex((1 - a + a * r, 1 - a + a * g, 1 - a + a * b))


def softmax(z, T):
    z = z / T
    z = z - z.max(axis=1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=1, keepdims=True)


def nll(z, y, T):
    return float(-np.log(softmax(z, T)[np.arange(len(y)), y]).mean())


edges = np.linspace(0, 1, n_bins + 1)


def reliability(z, y, T):
    p = softmax(z, T)
    conf = p.max(axis=1)
    correct = (p.argmax(axis=1) == y).astype(float)
    idx = np.clip(np.digitize(conf, edges) - 1, 0, n_bins - 1)
    n = np.bincount(idx, minlength=n_bins)
    acc = np.array([correct[idx == j].mean() if n[j] else np.nan for j in range(n_bins)])
    mconf = np.array([conf[idx == j].mean() if n[j] else np.nan for j in range(n_bins)])
    ece = float(np.nansum(n / n.sum() * np.abs(acc - mconf)))
    return dict(n=n, acc=acc, mconf=mconf, ece=ece, accuracy=correct.mean(), conf=conf.mean(), N=int(n.sum()))


# Data ---------------------------------------------------------------------------------
with open(HERE / "data.csv", newline="") as fh:
    rows = list(csv.DictReader(fh))
logit_cols = [c for c in rows[0] if c.startswith("logit_")]


def split(s):
    rr = [r for r in rows if r["split"] == s]
    return np.array([[float(r[c]) for c in logit_cols] for r in rr]), np.array([int(r["label"]) for r in rr])


z_val, y_val = split("val")
z_test, y_test = split("test")
fit = minimize_scalar(lambda T: nll(z_val, y_val, T), bounds=t_bounds, method="bounded", options={"xatol": 1e-6})
T_fit = float(fit.x)
R = {"before": reliability(z_test, y_test, 1.0), "after": reliability(z_test, y_test, T_fit)}
assert R["before"]["N"] == R["after"]["N"] == len(y_test)
assert abs(R["before"]["accuracy"] - R["after"]["accuracy"]) < 1e-12

# Figure -------------------------------------------------------------------------------
house.apply_house_style()
fig, ax0 = house.house_figure(cells=cells)
ax0.remove()
axd = fig.subplot_mosaic([["a", "b", "c"], ["a", "b", "d"]], width_ratios=[1, 1, 0.82])
w = edges[1] - edges[0]
mid = edges[:-1] + w / 2
titles = {"before": "Uncalibrated (T = 1)", "after": f"Temperature scaled (T = {T_fit:.2f})"}
for key, letter in (("before", "a"), ("after", "b")):
    ax, r = axd[letter], R[key]
    ok = r["n"] > 0
    ax.bar(mid[ok], r["acc"][ok], width=w * 0.94, color=tint(acc_col, 0.85), edgecolor=acc_col, lw=0.5, zorder=2)
    lo = np.minimum(r["acc"], r["mconf"])[ok]
    hi = np.maximum(r["acc"], r["mconf"])[ok]
    ax.bar(mid[ok], hi - lo, bottom=lo, width=w * 0.94, color=tint(gap_col, 0.35), edgecolor=gap_col, lw=0.5,
           hatch="////", zorder=3)
    for j in np.flatnonzero(ok & (r["n"] < small_n)):
        ax.text(mid[j], hi[np.flatnonzero(ok) == j][0] + 0.015, f"n={r['n'][j]}", ha="center", va="bottom",
                fontsize=6, color="#000000", zorder=6)
    ax.plot([0, 1], [0, 1], color=grey["dark"], lw=house.LW_PT["ref"], ls=(0, (3, 2)), zorder=4)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_xlabel("Confidence (max softmax)")
    ax.set_title(titles[key], fontsize=7, loc="left", pad=2)
    ax.text(0.04, 0.96, f"ECE = {r['ece']:.{ece_decimals}f}\n({n_bins} bins, test n = {r['N']})\n"
            f"Accuracy = {r['accuracy']:.3f}\nMean confidence = {r['conf']:.3f}",
            transform=ax.transAxes, ha="left", va="top", fontsize=6.5, linespacing=1.15, zorder=6)
    house.add_house_tag(ax, letter)
axd["a"].set_ylabel("Accuracy in bin")
axd["b"].set_yticklabels([])
axd["b"].legend(handles=[Patch(facecolor=tint(acc_col, 0.85), edgecolor=acc_col, lw=0.5, label="Accuracy"),
                         Patch(facecolor=tint(gap_col, 0.35), edgecolor=gap_col, lw=0.5, hatch="////",
                               label="Gap to mean\nconfidence"),
                         mpl.lines.Line2D([], [], color=grey["dark"], lw=house.LW_PT["ref"], ls=(0, (3, 2)),
                                          label="Perfect calibration")],
                loc="upper left", bbox_to_anchor=(0.0, 0.72), fontsize=6, handlelength=1.4, handleheight=1.0,
                labelspacing=0.3, borderaxespad=0.4)
axd["a"].text(0.04, 0.70, f"{footnote}; T fitted on\nval split (n = {len(y_val)}) by\nminimum NLL",
              transform=axd["a"].transAxes, ha="left", va="top", fontsize=6, color=grey["mid"], zorder=6,
              linespacing=1.15)

# c  n per bin
ax = axd["c"]
ax.bar(mid - w * 0.22, R["before"]["n"], width=w * 0.42, color=before_col, edgecolor="#000000", lw=0.3, label="T = 1")
ax.bar(mid + w * 0.22, R["after"]["n"], width=w * 0.42, color=after_col, edgecolor="#000000", lw=0.3,
       label=f"T = {T_fit:.2f}")
ax.set_xlim(0, 1)
ax.set_ylim(0, max(R["before"]["n"].max(), R["after"]["n"].max()) * 1.18)
ax.set_xlabel("Confidence bin")
ax.set_ylabel("Test examples")
ax.legend(loc="upper left", fontsize=6, handlelength=1.0, labelspacing=0.25, borderaxespad=0.3)
house.add_house_tag(ax, "c")

# d  val NLL vs T
ax = axd["d"]
Ts = np.linspace(0.6, 3.0, 121)
ax.plot(Ts, [nll(z_val, y_val, t) for t in Ts], color="#000000", lw=house.LW_PT["minor"])
n1, nf = nll(z_val, y_val, 1.0), nll(z_val, y_val, T_fit)
ax.plot([1.0], [n1], ls="none", marker="o", ms=house.POINT["markersize"], mew=house.POINT["markeredgewidth"],
        mec="#000000", mfc=before_col, zorder=3)
ax.plot([T_fit], [nf], ls="none", marker="o", ms=house.POINT["markersize"], mew=house.POINT["markeredgewidth"],
        mec="#000000", mfc=after_col, zorder=3)
# v2: label sits up and to the right of the T = 1 point, fully inside the axes (v1 crossed the left spine)
ax.annotate(f"T = 1\nNLL {n1:.3f}", (1.0, n1), xytext=(4, 3), textcoords="offset points", ha="left", va="bottom",
            fontsize=6, color=before_text)
ax.annotate(f"fit T = {T_fit:.2f}\nNLL {nf:.3f}", (T_fit, nf), xytext=(6, -3), textcoords="offset points",
            ha="left", va="top", fontsize=6, color=after_text)
ax.set_xlabel("Temperature T")
ax.set_ylabel("Val NLL")
ax.text(0.97, 0.95, f"val n = {len(y_val)}", transform=ax.transAxes, ha="right", va="top", fontsize=6,
        color=grey["mid"])
lo_, hi_ = ax.get_ylim()
ax.set_ylim(lo_ - (hi_ - lo_) * 0.35, hi_ + (hi_ - lo_) * 0.2)
house.add_house_tag(ax, "d")

house.save_house(fig, HERE / "figure", bump=0)

# Report -------------------------------------------------------------------------------
print(f"T fit {T_fit:.6f}; val n {len(y_val)}; test n {len(y_test)}; classes {len(logit_cols)}")
for k in ("before", "after"):
    r = R[k]
    print(k, f"ECE {r['ece']:.6f} -> printed {r['ece']:.{ece_decimals}f}", "acc", round(r["accuracy"], 6),
          "conf", round(r["conf"], 6), "n/bin", r["n"].tolist())
for c in sorted({before_text, after_text, grey["mid"], "#000000"}):
    print("text contrast on white", c, round(contrast(c), 2))
