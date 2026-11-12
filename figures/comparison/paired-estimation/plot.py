"""Paired estimation plot (paired Gardner-Altman form): each subject's Before
and After values joined by a line in the left panel, and the paired mean
difference with its bootstrap distribution and 95% CI in the right panel, on a
difference axis whose zero is aligned to the Before mean. Only complete pairs
are used; n, means and the CI are computed from data.csv. No P value is
printed. Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np
from scipy.stats import gaussian_kde

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "2x2"
n_boot = 5000
rng_seed = 20261126
conds = ("Before", "After")
y_label = "Response (a.u.)"
d_label = "Paired mean difference (a.u.)"
TEXT = "#1A1A1A"

rows = list(csv.DictReader(Path(__file__).with_name("data.csv").open()))
vals = {}
for r in rows:
    vals.setdefault(r["subject"], {})[r["condition"]] = float(r["value"])
subj = [s for s in vals if all(c in vals[s] for c in conds)]
b = np.array([vals[s][conds[0]] for s in subj])
a = np.array([vals[s][conds[1]] for s in subj])
n = len(subj)
d = a - b
md = d.mean()
rng = np.random.default_rng(rng_seed)
boot = np.array([rng.choice(d, n).mean() for _ in range(n_boot)])
lo, hi = np.percentile(boot, [2.5, 97.5])
mb = b.mean()

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
cb, ca = hp[0], hp[1]

house.apply_house_style()
fig, (ax, axd) = house.house_figure(cells=cells, ncols=2, gridspec_kw={"width_ratios": [1.7, 1.0]})

allv = np.concatenate([b, a])
rngv = allv.max() - allv.min()
ylo = allv.min() - 0.06 * rngv
yhi = allv.max() + 0.30 * rngv   # headroom for the footnote
for yb, ya in zip(b, a):
    ax.plot([0, 1], [yb, ya], color=grey["ci"], lw=0.6, zorder=1, gid="pairline")
ax.plot(np.zeros(n), b, ls="none", color=cb, zorder=3, **house.POINT)
ax.plot(np.ones(n), a, ls="none", color=ca, zorder=3, **house.POINT)
for xc, m in ((0, mb), (1, a.mean())):
    ax.plot([xc + 0.12 if xc == 0 else xc + 0.12, 1.45], [m, m], color=grey["ref"], lw=0.5,
            ls=(0, (2, 2)), gid="nocheck", zorder=0)
ax.set_xlim(-0.45, 1.45)
ax.set_ylim(ylo, yhi)
ax.set_xticks([0, 1])
ax.set_xticklabels([f"{conds[0]}\nn = {n}", f"{conds[1]}\nn = {n}"])
ax.set_ylabel(y_label)
ax.text(0.03, 0.975, f"Simulated data; {n} complete pairs\nGrey lines: one subject\n"
        f"Dashed lines: condition means\n95% CI: percentile bootstrap of the\nmean paired difference, {n_boot} resamples",
        transform=ax.transAxes, ha="left", va="top", fontsize=6, color=grey["mid"], linespacing=1.15)

axd.set_ylim(ylo - mb, yhi - mb)
axd.set_xlim(-0.5, 1.0)
axd.yaxis.tick_right()
axd.yaxis.set_label_position("right")
axd.set_ylabel(d_label)
axd.axhline(0, color=grey["ref"], lw=0.5, ls=(0, (2, 2)), gid="nocheck", zorder=0)
axd.axhline(md, color=grey["ref"], lw=0.5, ls=(0, (2, 2)), gid="nocheck", zorder=0)
kde = gaussian_kde(boot)
yy = np.linspace(boot.min(), boot.max(), 200)
dens = kde(yy)
axd.fill_betweenx(yy, 0.0, 0.55 * dens / dens.max(), color=ca, alpha=0.45, lw=0)
axd.plot([0, 0], [lo, hi], color="#000000", lw=1.0, solid_capstyle="butt")
axd.plot(0, md, "o", color="#000000", markersize=6.0, markeredgewidth=0)
axd.set_xticks([0.25])
axd.set_xticklabels([f"{conds[1]}\nminus {conds[0]}"])
axd.tick_params(axis="x", length=0)
sign = "+" if md >= 0 else "-"
axd.text(0.5, 0.975, f"Paired mean\ndifference {sign}{abs(md):.2f}\n95% CI [{lo:.2f}, {hi:.2f}]",
         transform=axd.transAxes, ha="center", va="top", fontsize=6.5, color=TEXT, linespacing=1.15)

house.save_house(fig, "figure")
print(f"wrote figure.pdf, figure.png, preview.png; n={n} md={md:.3f} CI=[{lo:.3f}, {hi:.3f}]")
