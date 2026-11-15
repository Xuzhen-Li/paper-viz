"""Gardner-Altman estimation plot for two unpaired groups: raw observations
(swarm) in the left panel, and the mean difference with its bootstrap
distribution and 95% CI in the right panel, on a difference axis whose zero is
aligned to the Control mean. n, means and the CI are computed from data.csv.
No P value is printed. Run: python3 plot.py"""
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
rng_seed = 20261125
y_label = "Response (a.u.)"
d_label = "Mean difference (a.u.)"
TEXT = "#1A1A1A"


def swarm_offsets(yp, dmin):
    """Beeswarm x offsets (points) for y positions (points), min distance dmin."""
    order = np.argsort(yp)
    placed = []
    xo = np.zeros(len(yp))
    cand = [0.0] + [s * k * dmin * 0.5 for k in range(1, 40) for s in (1, -1)]
    for i in order:
        for c in cand:
            if all((c - x) ** 2 + (yp[i] - y) ** 2 >= dmin ** 2 for x, y in placed):
                xo[i] = c
                placed.append((c, yp[i]))
                break
    return xo


rows = list(csv.DictReader(Path(__file__).with_name("data.csv").open()))
groups = list(dict.fromkeys(r["group"] for r in rows))
assert len(groups) == 2, "Gardner-Altman needs exactly two groups"
g0, g1 = groups
x0 = np.array([float(r["value"]) for r in rows if r["group"] == g0])
x1 = np.array([float(r["value"]) for r in rows if r["group"] == g1])
m0, m1 = x0.mean(), x1.mean()
diff = m1 - m0
rng = np.random.default_rng(rng_seed)
boot = np.array([rng.choice(x1, len(x1)).mean() - rng.choice(x0, len(x0)).mean() for _ in range(n_boot)])
lo, hi = np.percentile(boot, [2.5, 97.5])

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
c0, c1 = hp[0], hp[1]

house.apply_house_style()
fig, (ax, axd) = house.house_figure(cells=cells, ncols=2, gridspec_kw={"width_ratios": [1.7, 1.0]})

allv = np.concatenate([x0, x1])
pad = 0.06 * (allv.max() - allv.min())
ylo = allv.min() - pad
yhi = allv.max() + 0.30 * (allv.max() - allv.min())   # headroom for the footnote
ax.set_ylim(ylo, yhi)
ax.set_xlim(-0.6, 1.6)
fig.canvas.draw()
# swarm in display points
pt_per_y = ax.transData.transform([(0, 1)])[0][1] - ax.transData.transform([(0, 0)])[0][1]
pt_per_x = ax.transData.transform([(1, 0)])[0][0] - ax.transData.transform([(0, 0)])[0][0]
dmin = house.POINT["markersize"] * fig.dpi / 72 * 1.08
for xc, vals, c in ((0, x0, c0), (1, x1, c1)):
    xo = swarm_offsets(vals * pt_per_y, dmin) / pt_per_x
    ax.plot(xc + xo, vals, ls="none", color=c, **house.POINT)
# group means: short black ticks beside each swarm, and dashed lines to the difference panel
for xc, m in ((0, m0), (1, m1)):
    ax.plot([xc + 0.30, 1.6], [m, m], color=grey["ref"], lw=0.5, ls=(0, (2, 2)), gid="nocheck", zorder=0)
ax.set_xticks([0, 1])
ax.set_xticklabels([f"{g0}\nn = {len(x0)}", f"{g1}\nn = {len(x1)}"])
ax.set_ylabel(y_label)
ax.text(0.03, 0.975, f"Simulated data\nDashed lines: group means\n95% CI: percentile bootstrap,\n{n_boot} resamples",
        transform=ax.transAxes, ha="left", va="top", fontsize=6, color=grey["mid"], linespacing=1.15)

# difference panel: same scale, zero at the Control mean
axd.set_ylim(ylo - m0, yhi - m0)
axd.set_xlim(-0.5, 1.0)
axd.yaxis.tick_right()
axd.yaxis.set_label_position("right")
axd.set_ylabel(d_label)
axd.axhline(0, color=grey["ref"], lw=0.5, ls=(0, (2, 2)), gid="nocheck", zorder=0)
axd.axhline(diff, color=grey["ref"], lw=0.5, ls=(0, (2, 2)), gid="nocheck", zorder=0)
kde = gaussian_kde(boot)
yy = np.linspace(boot.min(), boot.max(), 200)
dens = kde(yy)
axd.fill_betweenx(yy, 0.0, 0.55 * dens / dens.max(), color=c1, alpha=0.45, lw=0)
axd.plot([0, 0], [lo, hi], color="#000000", lw=1.0, solid_capstyle="butt")
axd.plot(0, diff, "o", color="#000000", markersize=6.0, markeredgewidth=0)
axd.set_xticks([0.25])
axd.set_xticklabels([f"{g1}\nminus {g0}"])
axd.tick_params(axis="x", length=0)
sign = "+" if diff >= 0 else "-"
axd.text(0.5, 0.975, f"Mean difference\n{sign}{abs(diff):.2f}\n95% CI [{lo:.2f}, {hi:.2f}]",
         transform=axd.transAxes, ha="center", va="top", fontsize=6.5, color=TEXT, linespacing=1.15)

# no panel letters: the two panels read as one Gardner-Altman figure
house.save_house(fig, "figure")
print(f"wrote figure.pdf, figure.png, preview.png; diff={diff:.3f} CI=[{lo:.3f}, {hi:.3f}]")
