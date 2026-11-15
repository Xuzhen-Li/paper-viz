"""Win-rate matrix with marginals (house style), all from the battle table data.csv:
b  cell (row, column) = share of decided battles (ties excluded) the row model won against the
   column model, on a blue-red scale centred at 50%, numerals in each cell;
a  (top) average win rate of each model = unweighted mean of its row in b, aligned with columns;
c  (right) battles per model, split into decided battles and ties, aligned with rows;
d  pooled share of all decided battles each model won, with a 95% Wilson score interval.
Rows and columns sorted by the average win rate. No tests or P values. Simulated data.
Run from this directory: python3 plot.py"""
import csv
import sys
from pathlib import Path

import matplotlib as mpl
import numpy as np
from matplotlib.patches import Rectangle
from scipy import stats

HERE = Path(__file__).resolve().parent
STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

# Parameters ---------------------------------------------------------------------------
cells = "4x2"                  # 183 x 89 mm
span = 30                      # colour limits 50 +/- span (%); values beyond are clamped
conf_level = 0.95
footnote = "Simulated data"
pal = house.pv_palette("house")
grey = house.pv_palette("house_grey")
cmap = house.house_cmap("house_div")   # red = row model wins more, blue = loses more
bar_col, tie_col = pal[0], grey["ci"]


def lum(c):
    f = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = mpl.colors.to_rgb(c)
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(a, b="#FFFFFF"):
    x, y = sorted([lum(a), lum(b)], reverse=True)
    return (x + 0.05) / (y + 0.05)


ink_log = []


def ink(fill):
    best = max(["#000000", "#FFFFFF"], key=lambda t: contrast(t, fill))
    ink_log.append((fill, best, contrast(best, fill)))
    assert contrast(best, fill) >= 4.5, fill
    return best


def wilson(k, n, level):
    z = stats.norm.ppf(0.5 + level / 2)
    p = k / n
    d = 1 + z**2 / n
    c = (p + z**2 / (2 * n)) / d
    h = z * np.sqrt(p * (1 - p) / n + z**2 / (4 * n**2)) / d
    return c - h, c + h


# Data ---------------------------------------------------------------------------------
with open(HERE / "data.csv", newline="") as fh:
    rows = list(csv.DictReader(fh))
models = sorted({r["model_a"] for r in rows} | {r["model_b"] for r in rows})
k = len(models)
ix = {m: i for i, m in enumerate(models)}
W = np.zeros((k, k), int)      # W[i, j] = battles i won against j
T = np.zeros((k, k), int)      # ties between i and j (symmetric)
for r in rows:
    a, b = ix[r["model_a"]], ix[r["model_b"]]
    if r["winner"] == "model_a":
        W[a, b] += 1
    elif r["winner"] == "model_b":
        W[b, a] += 1
    else:
        assert r["winner"] == "tie", r
        T[a, b] += 1
        T[b, a] += 1
D = W + W.T                    # decided battles per pair
with np.errstate(invalid="ignore", divide="ignore"):
    WR = np.where(D > 0, 100 * W / D, np.nan)
np.fill_diagonal(WR, np.nan)
avg = np.nanmean(WR, axis=1)
n_decided = D.sum(axis=1)
n_ties = T.sum(axis=1)
n_battles = n_decided + n_ties
wins = W.sum(axis=1)
assert n_battles.sum() == 2 * len(rows)          # every battle counted for both models
o = np.argsort(-avg)
models = [models[i] for i in o]
WR, avg, n_decided, n_ties, n_battles, wins = WR[np.ix_(o, o)], avg[o], n_decided[o], n_ties[o], n_battles[o], wins[o]
pooled = 100 * wins / n_decided
ci = np.array([wilson(w_, n_, conf_level) for w_, n_ in zip(wins, n_decided)]) * 100

# Figure -------------------------------------------------------------------------------
house.apply_house_style()
fig, ax0 = house.house_figure(cells=cells)
ax0.remove()
gs = fig.add_gridspec(2, 3, height_ratios=[0.3, 1], width_ratios=[1, 0.45, 0.62])
ax_m = fig.add_subplot(gs[1, 0])
ax_t = fig.add_subplot(gs[0, 0], sharex=ax_m)
ax_r = fig.add_subplot(gs[1, 1], sharey=ax_m)
ax_d = fig.add_subplot(gs[:, 2])

# b  matrix
for i in range(k):
    for j in range(k):
        if i == j or np.isnan(WR[i, j]):
            ax_m.add_patch(Rectangle((j - 0.5, i - 0.5), 1, 1, facecolor=grey["bg"], edgecolor="white", lw=0.4))
            continue
        t = np.clip((WR[i, j] - (50 - span)) / (2 * span), 0, 1)
        fill = mpl.colors.to_hex(cmap(t))
        ax_m.add_patch(Rectangle((j - 0.5, i - 0.5), 1, 1, facecolor=fill, edgecolor="white", lw=0.4))
        ax_m.text(j, i, f"{WR[i, j]:.0f}", ha="center", va="center", fontsize=6.5, color=ink(fill))
ax_m.set_xlim(-0.5, k - 0.5)
ax_m.set_ylim(k - 0.5, -0.5)
ax_m.set_xticks(range(k))
ax_m.set_xticklabels([m.replace("Model ", "") for m in models])
ax_m.set_yticks(range(k))
ax_m.set_yticklabels(models)
ax_m.tick_params(length=0)
ax_m.set_xlabel("Opponent (column model)")
ax_m.set_ylabel("Row model")
house.add_house_tag(ax_m, "b")

# a  top: average win rate per model, aligned with columns
xx = np.arange(k)
ax_t.bar(xx, avg - 50, bottom=50, width=0.7, color=[mpl.colors.to_hex(cmap(np.clip((v - 50 + span) / (2 * span), 0, 1))) for v in avg],
         edgecolor="#000000", lw=0.3)
ax_t.axhline(50, color=grey["dark"], lw=house.LW_PT["ref"], ls=(0, (3, 2)))
for x_, v in zip(xx, avg):
    ax_t.text(x_, v + (2 if v >= 50 else -2), f"{v:.0f}", ha="center", va="bottom" if v >= 50 else "top", fontsize=6)
lo, hi = np.nanmin(avg), np.nanmax(avg)
ax_t.set_ylim(min(lo, 50) - 12, max(hi, 50) + 12)
ax_t.set_ylabel("Avg win\nrate (%)")
ax_t.text(0.995, 0.95, "Dashed: 50%", transform=ax_t.transAxes, ha="right", va="top", fontsize=6, color=grey["mid"])
ax_t.tick_params(axis="x", labelbottom=False, length=0)
house.add_house_tag(ax_t, "a")

# c  right: battles per model (decided + ties)
yy = np.arange(k)
ax_r.barh(yy, n_decided, height=0.7, color=bar_col, edgecolor="#000000", lw=0.3, label="Decided")
ax_r.barh(yy, n_ties, left=n_decided, height=0.7, color=tie_col, edgecolor="#000000", lw=0.3, label="Tie")
for y_, v in zip(yy, n_battles):
    ax_r.text(v + n_battles.max() * 0.03, y_, f"{v}", va="center", ha="left", fontsize=6)
ax_r.set_xlim(0, n_battles.max() * 1.45)
ax_r.tick_params(axis="y", labelleft=False, length=0)
ax_r.set_xlabel("Battles per model")
ax_r.legend(loc="lower right", fontsize=6, handlelength=1.0, labelspacing=0.25, borderaxespad=0.3)
house.add_house_tag(ax_r, "c")

# d  pooled share with Wilson CI
for i in range(k):
    ax_d.plot(ci[i], [i, i], color="#000000", lw=house.LW_PT["errorbar"] * 1.4, solid_capstyle="butt")
    ax_d.plot(pooled[i], i, ls="none", marker="o", ms=house.POINT["markersize"], mew=house.POINT["markeredgewidth"],
              mec="#000000", mfc=bar_col)
ax_d.axvline(50, color=grey["dark"], lw=house.LW_PT["ref"], ls=(0, (3, 2)))
ax_d.set_yticks(yy)
ax_d.set_yticklabels(models)
ax_d.set_ylim(k - 0.5, -0.5)
ax_d.tick_params(axis="y", length=0)
ax_d.set_xlim(min(ci[:, 0].min(), 50) - 4, max(ci[:, 1].max(), 50) + 26)
ax_d.set_xlabel("Decided battles won (%)")
ax_d.text(0.97, 0.98, f"Pooled over\nopponents\nDot: share won\nLine: {int(conf_level*100)}%\nWilson score\ninterval\n"
          f"n decided per\nmodel: {n_decided.min()}\nto {n_decided.max()}\n\nb: ties excluded;\nred: row model\nwins more\n\n"
          f"{footnote};\n{len(rows)} battles,\n{k} models",
          transform=ax_d.transAxes, ha="right", va="top", fontsize=6, color=grey["mid"], linespacing=1.15)
house.add_house_tag(ax_d, "d")

house.save_house(fig, HERE / "figure", bump=0)

# Report -------------------------------------------------------------------------------
print("battles", len(rows), "models", k, "pairs with no decided battle", int((D == 0).sum() - k))
for m, a_, nb, nd, nt, p_, c_ in zip(models, avg, n_battles, n_decided, n_ties, pooled, ci):
    print(f"  {m}: avg {a_:.2f}  battles {nb} (decided {nd}, ties {nt})  pooled {p_:.2f} [{c_[0]:.2f}, {c_[1]:.2f}]")
cs = [c for _, _, c in ink_log]
print("cell numeral contrast vs fill: min", round(min(cs), 2), "max", round(max(cs), 2), "cells", len(cs))
worst = min(ink_log, key=lambda t: t[2])
print("worst cell:", worst)
for c in sorted({grey["mid"], "#000000"}):
    print("text contrast on white", c, round(contrast(c), 2))
