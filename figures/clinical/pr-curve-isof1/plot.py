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
models = {"score_a": ("Model A", PAL[0]), "score_b": ("Model B", PAL[1])}
iso_f1 = [0.2, 0.4, 0.6, 0.8]
# ----

df = pd.read_csv(HERE / "data.csv")
y = df.label.values; prev = y.mean()


def pr(score):
    o = np.argsort(-score); t = y[o]
    tp = np.cumsum(t); fp = np.cumsum(1 - t)
    prec = tp / (tp + fp); rec = tp / t.sum()
    ap = np.sum(np.diff(np.r_[0, rec]) * prec)
    return rec, prec, ap


fig, ax = house.house_figure(cells="2x2")
r = np.linspace(0.01, 1, 400)
for f1 in iso_f1:
    p = f1 * r / (2 * r - f1); ok = (p > 0) & (p <= 1.06)
    ax.plot(r[ok], p[ok], color=GREY["ci"], lw=LW["ref"], ls=(0, (1.5, 1.5)))
    pt = 1.06; ax.text(f1 * pt / (2 * pt - f1), pt, f"{f1}", color=GREY["mid"], fontsize=6, ha="center", va="center",
            bbox=dict(facecolor="white", edgecolor="none", pad=0.3))
ax.axhline(prev, color=GREY["mid"], lw=LW["ref"], ls=(0, (3, 2)))
ax.text(0.02, prev - 0.015, f"random (prevalence = {prev:.2f})", color=GREY["mid"], fontsize=6.5, va="top")
txt = []
for col, (lab, c) in models.items():
    rec, prec, ap = pr(df[col].values)
    ax.plot(rec, prec, color=c, lw=LW["main"])
    txt.append((lab, c, ap, rec, prec))
for (lab, c, ap, rec, prec), (x, yy) in zip(txt, [(0.5, 0.9), (0.17, 0.6)]):
    ax.text(x, yy, f"{lab}, AP = {ap:.2f}", color=c, fontsize=7, va="bottom")
ax.text(0.73, 1.06, "iso-F1 curves", color=GREY["mid"], fontsize=6, va="center")
ax.set_xlim(0, 1); ax.set_ylim(0, 1.1); ax.set_yticks([0, 0.2, 0.4, 0.6, 0.8, 1.0])
ax.set_xlabel("Recall"); ax.set_ylabel("Precision")
ax.text(0.02, 0.03, f"simulated data, n = {len(df)}", transform=ax.transAxes, fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
