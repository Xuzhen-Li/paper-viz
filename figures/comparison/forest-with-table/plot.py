"""Forest plot of a two-group mean difference across studies, with the numeric
estimate, 95% CI and n aligned to each row inside the same frame, plus a fixed-
effect inverse-variance overall row. Every number is computed from data.csv.
Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np
from matplotlib.patches import Polygon

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "3x2"
n_boot = 5000
rng_seed = 20261122
x_label = "Mean difference, Treatment - Control (a.u.)"
TEXT = "#1A1A1A"

rows = list(csv.DictReader(Path(__file__).with_name("data.csv").open()))
studies = list(dict.fromkeys(r["study"] for r in rows))
rng = np.random.default_rng(rng_seed)
recs = []
for s in studies:
    c = np.array([float(r["value"]) for r in rows if r["study"] == s and r["group"] == "Control"])
    t = np.array([float(r["value"]) for r in rows if r["study"] == s and r["group"] == "Treatment"])
    md = t.mean() - c.mean()
    boot = np.array([rng.choice(t, len(t)).mean() - rng.choice(c, len(c)).mean() for _ in range(n_boot)])
    lo, hi = np.percentile(boot, [2.5, 97.5])
    se = np.sqrt(t.var(ddof=1) / len(t) + c.var(ddof=1) / len(c))
    recs.append(dict(name=s, md=md, lo=lo, hi=hi, se=se, nc=len(c), nt=len(t)))
w = np.array([1 / r["se"] ** 2 for r in recs])
md_all = float(np.sum(w * [r["md"] for r in recs]) / w.sum())
se_all = float(1 / np.sqrt(w.sum()))
ov = dict(name="Overall", md=md_all, lo=md_all - 1.96 * se_all, hi=md_all + 1.96 * se_all,
          nc=sum(r["nc"] for r in recs), nt=sum(r["nt"] for r in recs))

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
col = hp[0]

house.apply_house_style()
fig, ax = house.house_figure(cells=cells)

k = len(recs)
y_ov = k + 1.2
y_foot = k + 2.0
lo_x = np.floor(min(r["lo"] for r in recs) * 2) / 2 - 0.3
hi_x = np.ceil(max(r["hi"] for r in recs) * 2) / 2 + 0.3
span = hi_x - lo_x
x_sep = hi_x + 0.05 * span          # table starts here
x_est = x_sep + 0.06 * span
x_n = x_sep + 0.92 * span
x_end = x_sep + 1.0 * span

for i, r in enumerate(recs, start=1):
    ax.plot([r["lo"], r["hi"]], [i, i], color=col, lw=1.0, solid_capstyle="butt")
    ax.plot(r["md"], i, "o", color=col, markersize=5.5, markeredgecolor="#000000",
            markeredgewidth=house.POINT["markeredgewidth"])
dh = 0.32
ax.add_patch(Polygon([[ov["lo"], y_ov], [ov["md"], y_ov - dh], [ov["hi"], y_ov], [ov["md"], y_ov + dh]],
                     closed=True, facecolor=col, edgecolor="#000000", lw=0.3))
ax.plot([0, 0], [0.45, y_ov + 0.55], ls=(0, (2, 2)), color=grey["ref"], lw=house.LW_PT["ref"])
ax.plot([lo_x, x_end], [k + 0.6, k + 0.6], color=grey["light"], lw=0.5, gid="nocheck")
ax.plot([x_sep, x_sep], [-0.6, y_ov + 0.55], color=grey["light"], lw=0.5, gid="nocheck")

def ci_txt(r):
    return f"{r['md']:.2f} [{r['lo']:.2f}, {r['hi']:.2f}]"

hdr_y = -0.05
ax.text(x_est, hdr_y, "Mean diff. [95% CI]", ha="left", va="center", fontsize=7, color=grey["mid"])
ax.text(x_n, hdr_y, "n (C / T)", ha="right", va="center", fontsize=7, color=grey["mid"])
ax.text(0, hdr_y, "No difference", ha="center", va="center", fontsize=6.5, color=grey["mid"])
for i, r in enumerate(recs + [ov], start=1):
    y = i if i <= k else y_ov
    ax.text(x_est, y, ci_txt(r), ha="left", va="center", fontsize=7, color=TEXT)
    ax.text(x_n, y, f"{r['nc']} / {r['nt']}", ha="right", va="center", fontsize=7, color=TEXT)

ax.text(0.008, 0.02,
        "Simulated data. Rows: mean difference, 95% percentile-bootstrap CI (5000 resamples).\n"
        "Overall: fixed-effect inverse-variance mean (Welch SEs), normal-theory 95% CI.",
        transform=ax.transAxes, ha="left", va="bottom", fontsize=6, color=grey["mid"], linespacing=1.15)

ax.set_ylim(y_foot + 0.95, -0.6)
ax.set_yticks(list(range(1, k + 1)) + [y_ov])
ax.set_yticklabels([r["name"] for r in recs] + ["Overall (IV)"])
ax.tick_params(axis="y", left=False)
ax.set_xlim(lo_x, x_end)
ticks = np.arange(np.ceil(lo_x), np.floor(hi_x) + 1, 1.0)
ax.set_xticks(ticks)
ax.set_xticklabels([f"{t:g}" for t in ticks])
ax.set_xlabel(x_label, x=(0.5 * (lo_x + hi_x) - lo_x) / (x_end - lo_x), ha="center")

house.save_house(fig, "figure")
print(f"wrote figure.pdf, figure.png, preview.png; overall {ci_txt(ov)}")
