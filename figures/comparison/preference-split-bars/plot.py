"""Preference split bars + multi-dimension scores (house style).
a: for each task, the share of raters preferring System A, tie, or System B as a 100 % split
bar, with the counts written at the right; sorted by the share preferring A.
b: per dimension, each rater's mean score over tasks (dots) and the across-rater mean with a
95 % t confidence interval (n = raters), for both systems. Direct coloured labels, everything
inside the frames. No tests are run, so no P values. Reads data.csv only. Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np

def _find_styles():
    here = Path(__file__).resolve()
    cands = []
    if len(here.parents) > 3:
        cands.append(here.parents[3] / "styles" / "python")   # future figures/<cat>/<slug>/ layout
    for c in cands:
        if (c / "house.py").is_file():
            return c
    raise FileNotFoundError("styles/python/house.py not found; tried " + ", ".join(map(str, cands)))


sys.path.insert(0, str(_find_styles()))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent
CELLS = (4, 2)                    # 183 x 89 mm, two panels, no +2 pt bump
FS_VAL = 6.5
FS_NOTE = 6.5
# T975 is keyed by degrees of freedom (df = n - 1). Lookup is T975[n - 1].
T975 = {1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571, 6: 2.447, 7: 2.365, 8: 2.306, 9: 2.262,
        10: 2.228, 11: 2.201, 12: 2.179, 13: 2.160, 14: 2.145, 15: 2.131, 19: 2.093, 24: 2.064, 29: 2.045}

rows = list(csv.DictReader(open(HERE / "data.csv")))
pref = [r for r in rows if r["record"] == "preference"]
score = [r for r in rows if r["record"] == "score"]
systems = list(dict.fromkeys(r["system"] for r in score))
dims = list(dict.fromkeys(r["dimension"] for r in score))
tasks = list(dict.fromkeys(r["task"] for r in pref))
raters = sorted({r["rater"] for r in rows})
n_raters, n_tasks = len(raters), len(tasks)
cats = [systems[0], "Tie", systems[1]]
cnt = {t: {c: sum(1 for r in pref if r["task"] == t and r["system"] == c) for c in cats} for t in tasks}
tot = {t: sum(cnt[t].values()) for t in tasks}
order = sorted(tasks, key=lambda t: (cnt[t][cats[0]] / tot[t], -cnt[t][cats[2]] / tot[t]))   # bottom -> top
n_judg = sum(tot.values())
n_a = sum(cnt[t][cats[0]] for t in tasks)
n_b = sum(cnt[t][cats[2]] for t in tasks)
n_tie = n_judg - n_a - n_b

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
fill = {cats[0]: hp[0], "Tie": grey["ci"], cats[2]: hp[3]}        # blue / #BFBFBF / red fills
txtc = {cats[0]: hp[0], "Tie": grey["mid"], cats[2]: hp[3]}       # text >= 4.5:1 on white
ink = "#1A1A1A"

house.apply_house_style()
fig, (ax, bx) = house.house_figure(cells=CELLS, ncols=2, gridspec_kw={"width_ratios": [1.3, 1.0]})

# a: split bars ---------------------------------------------------------------------------
y = np.arange(n_tasks)
for yi, t in zip(y, order):
    left = 0.0
    for c in cats:
        w = 100 * cnt[t][c] / tot[t]
        if w > 0:
            ax.barh(yi, w, left=left, height=0.66, color=fill[c], edgecolor="white", linewidth=0.3, zorder=2)
        left += w
    ax.text(103, yi, f"{cnt[t][cats[0]]} / {cnt[t]['Tie']} / {cnt[t][cats[2]]}", color=ink, fontsize=FS_VAL,
            ha="left", va="center")
ax.plot([50, 50], [-0.5, n_tasks - 0.5], color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (3, 2)), zorder=3)
top = n_tasks - 0.4
ax.text(0, top, f"Prefer {cats[0]}", color=txtc[cats[0]], fontsize=7, ha="left", va="bottom")
ax.text(50, top, "Tie (grey)", color=txtc["Tie"], fontsize=7, ha="center", va="bottom")
ax.text(100, top, f"Prefer {cats[2]}", color=txtc[cats[2]], fontsize=7, ha="right", va="bottom")
ax.text(103, top, "A / tie / B", color=ink, fontsize=FS_VAL, ha="left", va="bottom")
ax.text(0, -1.05, f"{cats[0]} preferred in {n_a}/{n_judg} judgements, tie {n_tie}, {cats[2]} {n_b}",
        color=ink, fontsize=FS_NOTE, ha="left", va="center")
ax.set_yticks(y)
ax.set_yticklabels(order)
ax.set_ylim(-1.6, n_tasks + 0.55)
ax.set_xlim(0, 124)
ax.set_xticks([0, 25, 50, 75, 100])
ax.set_xlabel(f"Raters preferring each answer (%, n = {n_raters} per task)")
house.add_house_tag(ax, "a")

# b: scores per dimension -------------------------------------------------------------------
rng = np.random.default_rng(1)          # jitter only
off = {systems[0]: -0.17, systems[1]: +0.17}
means = {}
for j, d in enumerate(dims):
    for s in systems:
        rm = np.array([np.mean([float(r["score"]) for r in score if r["rater"] == q and r["system"] == s
                                and r["dimension"] == d]) for q in raters])
        n = len(rm)
        m, se = rm.mean(), rm.std(ddof=1) / np.sqrt(n)
        if (n - 1) not in T975:
            raise ValueError(
                f"no t critical value in T975 for df = {n - 1} (n = {n}); "
                "refusing a 1.96 fallback while the figure is labelled a 95% t CI"
            )
        h = T975[n - 1] * se
        means[(d, s)] = (m, h)
        xx = j + off[s]
        bx.scatter(xx + rng.uniform(-0.06, 0.06, n), rm, s=6, color=fill[s], alpha=0.55, linewidths=0, zorder=2)
        bx.errorbar(xx, m, yerr=h, fmt="none", ecolor=ink, elinewidth=house.LW_PT["errorbar"], capsize=0, zorder=3)
        bx.plot([xx], [m], ls="none", color=fill[s], markerfacecolor=fill[s], zorder=4, **house.POINT)
        tx = xx + (-0.11 if s == systems[0] else 0.11)
        bx.text(tx, m, f"{m:.1f}", color=txtc[s], fontsize=FS_VAL, ha="right" if s == systems[0] else "left", va="center")
bx.set_xticks(range(len(dims)))
bx.set_xticklabels(dims)
bx.set_xlim(-0.55, len(dims) - 0.45)
bx.set_ylim(1, 10.6)
bx.set_yticks([2, 4, 6, 8, 10])
bx.set_ylabel("Score (1-10)")
bx.text(0.03, 0.965, systems[0], transform=bx.transAxes, color=txtc[systems[0]], fontsize=7, ha="left", va="top")
bx.text(0.03, 0.905, systems[1], transform=bx.transAxes, color=txtc[systems[1]], fontsize=7, ha="left", va="top")
bx.text(0.97, 0.905, f"Dots: rater means over {n_tasks} tasks", transform=bx.transAxes, color=ink, fontsize=FS_NOTE, ha="right", va="top")
bx.text(0.97, 0.85, f"Large dot: mean; line: 95% t CI, n = {n_raters} raters", transform=bx.transAxes, color=ink, fontsize=FS_NOTE, ha="right", va="top")
bx.text(0.97, 0.965, "Simulated data", transform=bx.transAxes, color=grey["mid"], fontsize=FS_NOTE, ha="right", va="top")
house.add_house_tag(bx, "b")
house.save_house(fig, HERE / "figure")
print(f"raters = {n_raters}; tasks = {n_tasks}; judgements = {n_judg} (A {n_a}, tie {n_tie}, B {n_b})")
for (d, s), (m, h) in means.items():
    print(f"  {d} {s}: mean {m:.2f}, 95% t CI half-width {h:.2f}")
