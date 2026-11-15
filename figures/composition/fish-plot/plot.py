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
clone_cols = {"C1": GREY["ci"], "C2": PAL[0], "C3": PAL[1], "C4": PAL[3], "C5": PAL[2]}
lead_days = 40          # a clone appears this many days before its first non-zero sample
therapy = (20, 110)     # shaded treatment window (days)
# ----

df = pd.read_csv(HERE / "data.csv")
days = np.sort(df.day.unique()); tl = df.drop_duplicates("day").set_index("day").timepoint
clones = list(dict.fromkeys(df.clone)); parent = df.drop_duplicates("clone").set_index("clone").parent.fillna("")
F = {c: df[df.clone == c].set_index("day").ccf.reindex(days).values for c in clones}
grid = np.linspace(days[0], days[-1], 600)


def smooth(c):
    x = days.astype(float); v = F[c].astype(float)
    first = np.argmax(v > 0)
    if first > 0:
        x = np.r_[x[:first], x[first] - lead_days, x[first:]]; v = np.r_[np.zeros(first), 0, v[first:]]
    out = np.zeros_like(grid)
    for k in range(len(x) - 1):
        m = (grid >= x[k]) & (grid <= x[k + 1])
        u = (grid[m] - x[k]) / (x[k + 1] - x[k]); u = (1 - np.cos(np.pi * u)) / 2
        out[m] = v[k] + (v[k + 1] - v[k]) * u
    return out


S = {c: smooth(c) for c in clones}
kids = {c: [k for k in clones if parent[k] == c] for c in clones}
lo, hi = {}, {}


def place(c, l):
    lo[c] = l; hi[c] = l + S[c]
    ch = kids[c]
    if not ch:
        return
    tot = sum(S[k] for k in ch)
    gap = (S[c] - tot) / (len(ch) + 1)
    pos = l + gap
    for k in ch:
        place(k, pos); pos = pos + S[k] + gap


for c in clones:
    if parent[c] == "":
        place(c, -S[c] / 2)
fig, ax = house.house_figure(cells="4x2")
ax.axvspan(*therapy, color=GREY["bg"], lw=0, zorder=0)
ax.text(np.mean(therapy), 56, "therapy", ha="center", fontsize=6.5, color=GREY["mid"])
for c in clones:
    ax.fill_between(grid, lo[c], hi[c], where=S[c] > 0.05, color=clone_cols[c], lw=0, zorder=2)
for d in days:
    ax.axvline(d, color="black", lw=LW["ref"], ls=(0, (2, 1.5)), zorder=3)
    ax.text(d + (1.5 if d == days[0] else -1.5 if d == days[-1] else 0), 53, tl[d], ha="left" if d == days[0] else "right" if d == days[-1] else "center", va="bottom", fontsize=6.5,
            bbox=dict(facecolor="white", edgecolor="none", pad=0.6))
sel = (grid > grid[0] + 0.06 * np.ptp(grid)) & (grid < grid[-1] - 0.06 * np.ptp(grid))
for c in clones:
    edges = [lo[c]] + [e for k in kids[c] for e in (lo[k], hi[k])] + [hi[c]]
    best = (0, 0, 0)
    for a, b in zip(edges[::2], edges[1::2]):
        w = np.where(sel, b - a, 0); i = int(np.argmax(w))
        if w[i] > best[0]:
            best = (w[i], i, (a[i] + b[i]) / 2)
    ax.text(grid[best[1]], best[2], c, ha="center", va="center", fontsize=7, fontweight="bold", color="black", zorder=4)
ax.set_ylim(-58, 62); ax.set_yticks([]); ax.spines["left"].set_visible(False)
ax.set_xlim(days[0] - 5, days[-1] + 5); ax.set_xlabel("Days since diagnosis")
ax.text(0.995, 0.02, "band height = cancer cell fraction (%); nested bands are subclones; simulated data", transform=ax.transAxes,
        ha="right", va="bottom", fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
