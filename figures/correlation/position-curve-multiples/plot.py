"""Position-curve small multiples (house style). Simulated data; reads data.csv only.
a-c: accuracy vs position of the answer document, one panel per total number of documents in the
context (shared y axis); d: edge-minus-middle accuracy gap per model against context length.
Bands and error bars: 95% intervals (Wilson for single proportions; Wald for the gap). No P values.
v2: panels a-c y-tick labels now equal their data coordinates (0.4-0.8); data and seed unchanged.
Run from this directory: python plot.py"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "4x2"
Z = 1.959964            # 95% normal quantile
footnote = "Simulated data"

house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
TEXT_DARK = {"#F77E12": "#B95E0E", "#62B4E7": "#437B9E"}

d = pd.read_csv(Path(__file__).with_name("data.csv"))
models = list(dict.fromkeys(d.model))
lengths = sorted(d.total_docs.unique())
col = {m: hp[i] for i, m in enumerate(models)}
tcol = {m: TEXT_DARK.get(c.upper(), c) for m, c in col.items()}
d["acc"] = d.n_correct / d.n_questions
nq = sorted(d.n_questions.unique())
n_label = f"n = {nq[0]} questions per point" if len(nq) == 1 else f"n = {nq[0]}–{nq[-1]} questions per point"
n_total = int(d.n_questions.sum())


def wilson(k, n):
    p = k / n
    den = 1 + Z**2 / n
    c = (p + Z**2 / (2 * n)) / den
    h = Z * np.sqrt(p * (1 - p) / n + Z**2 / (4 * n**2)) / den
    return c - h, c + h


lo, hi = wilson(d.n_correct.to_numpy(), d.n_questions.to_numpy())
d["lo"], d["hi"] = lo, hi

fig, axes = house.house_figure(cells=cells, ncols=4, gridspec_kw={"width_ratios": [1, 1, 1, 0.95]})
ax_curves, ax_d = axes[:3], axes[3]
ymin = np.floor((d.lo.min() - 0.02) * 20) / 20
ymax = np.ceil((d.hi.max() + 0.06) * 20) / 20
for ax, k, tag in zip(ax_curves, lengths, "abc"):
    s = d[d.total_docs == k]
    for m in models:
        r = s[s.model == m].sort_values("position")
        ax.fill_between(r.position, r.lo, r.hi, color=col[m], alpha=0.18, lw=0, zorder=1)
        ax.plot(r.position, r.acc, color=col[m], lw=1.5, zorder=2)
        ax.plot(r.position, r.acc, ls="none", color=col[m], **house.POINT, zorder=3)
    pos = sorted(s.position.unique())
    ax.set_xticks(pos)
    ax.set_xlim(pos[0] - 0.06 * (pos[-1] - pos[0]), pos[-1] + 0.06 * (pos[-1] - pos[0]))
    ax.set_ylim(ymin, ymax)
    ax.text(0.5, 0.97, f"{k} total documents", transform=ax.transAxes, ha="center", va="top", fontsize=7)
    ax.set_xlabel("Position of answer document")
    house.add_house_tag(ax, tag)
for ax in ax_curves[1:]:
    ax.sharey(ax_curves[0])
    ax.tick_params(labelleft=False)
ax_curves[0].set_ylabel("Accuracy")
# v2: ticks built from integers / 10 so each printed label equals its data coordinate
# (v1 printed 0.35, 0.45, ... with .1f, i.e. labels 0.05 too low). ylim unchanged.
yt = [v for v in np.arange(0, 11) / 10.0 if ymin - 1e-9 <= v <= ymax + 1e-9]
ax_curves[0].set_yticks(yt)
ax_curves[0].set_yticklabels([f"{v:.1f}" for v in yt])
for i, m in enumerate(models):   # in-frame key, one row under the panel-a title
    ax_curves[0].text(0.5 + (i - (len(models) - 1) / 2) * 0.31, 0.885, m, transform=ax_curves[0].transAxes,
                      ha="center", va="top", fontsize=7, color=tcol[m])
ax_curves[1].text(0.5, 0.03, f"{footnote}\n{n_label}", transform=ax_curves[1].transAxes, ha="center",
                  va="bottom", fontsize=6, color=grey["mid"], linespacing=1.3)
ax_curves[2].text(0.5, 0.03, "Bands: 95% Wilson interval\nFive positions incl. first, middle, last",
                  transform=ax_curves[2].transAxes, ha="center", va="bottom", fontsize=6, color=grey["mid"],
                  linespacing=1.3)

# d: edge-minus-middle gap (pp) = mean(first, last) - middle, 95% Wald interval
gap = []
for m in models:
    for k in lengths:
        r = d[(d.model == m) & (d.total_docs == k)].sort_values("position")
        first, mid, last = r.iloc[0], r.iloc[len(r) // 2], r.iloc[-1]
        est = (first.acc + last.acc) / 2 - mid.acc
        var = (first.acc * (1 - first.acc) / first.n_questions + last.acc * (1 - last.acc) / last.n_questions) / 4 \
            + mid.acc * (1 - mid.acc) / mid.n_questions
        gap.append(dict(model=m, k=k, est=100 * est, half=100 * Z * np.sqrt(var)))
gap = pd.DataFrame(gap)
dodge = {m: (i - (len(models) - 1) / 2) * 1.8 for i, m in enumerate(models)}
for m in models:
    g = gap[gap.model == m]
    x = g.k + dodge[m]
    ax_d.errorbar(x, g.est, yerr=g.half, fmt="none", ecolor=col[m], elinewidth=house.LW_PT["errorbar"],
                  capsize=0, zorder=2)
    ax_d.plot(x, g.est, color=col[m], lw=1.0, zorder=2)
    ax_d.plot(x, g.est, ls="none", color=col[m], **house.POINT, zorder=3)
ends = sorted(((gap[gap.model == m].est.iloc[-1], m) for m in models))
min_sep = 0.07 * ((gap.est + gap.half).max() - min(0, (gap.est - gap.half).min()))
placed = []
for y, m in ends:                       # simple repel for the end labels
    y = max(y, placed[-1] + min_sep) if placed else y
    placed.append(y)
    ax_d.text(lengths[-1] + dodge[models[-1]] + 1.6, y, m.split()[-1], ha="left", va="center", fontsize=7,
              color=tcol[m])
ax_d.axhline(0, color=grey["ref"], lw=0.5, ls=(0, (3, 2)), zorder=0)
ax_d.set_xticks(lengths)
ax_d.set_xlim(lengths[0] - 5, lengths[-1] + 7)
glo, ghi = (gap.est - gap.half).min(), (gap.est + gap.half).max()
ax_d.set_ylim(min(-2, glo - 0.05 * (ghi - glo)), ghi + 0.32 * (ghi - glo))
ax_d.set_yticks(np.arange(0, ax_d.get_ylim()[1] + 1e-9, 5))
ax_d.set_xlabel("Total documents")
ax_d.set_ylabel("Edge − middle accuracy (pp)")
ax_d.text(0.04, 0.97, "Mean of first and last\nminus middle position;\n95% Wald interval", transform=ax_d.transAxes,
          ha="left", va="top", fontsize=6, color=grey["mid"], linespacing=1.3)
ax_d.text(0.96, 0.03, footnote, transform=ax_d.transAxes, ha="right", va="bottom", fontsize=6, color=grey["mid"])
house.add_house_tag(ax_d, "d")

out = house.save_house(fig, "figure", cells=cells, bump=0)
print("canvas_mm", out["width_mm"], out["height_mm"])
print("models", len(models), "lengths", lengths, n_label, "total_questions", n_total)
print(gap.round(2).to_string())
