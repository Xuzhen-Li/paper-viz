import csv
import os
import sys
from pathlib import Path

import numpy as np

os.environ.setdefault("SOURCE_DATE_EPOCH", "0")  # reproducible PDF metadata
HERE = Path(__file__).resolve().parent


def _house_dir():
    """styles/python: parents[3] first (future figures/<cat>/<slug>/ layout), then the known checkouts."""
    here = Path(__file__).resolve()
    cands = [here.parents[3] / "styles" / "python"] if len(here.parents) > 3 else []
    for c in cands:
        if (c / "house.py").is_file():
            return c
    raise FileNotFoundError("styles/python/house.py not found; tried " + ", ".join(map(str, cands)))


sys.path.insert(0, str(_house_dir()))
import house  # noqa: E402


def lum(h):
    import matplotlib.colors as mc
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = mc.to_rgb(h)
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(a, b="#FFFFFF"):
    x, y = sorted([lum(a), lum(b)], reverse=True)
    return (x + 0.05) / (y + 0.05)


def text_col(c, bg="#FFFFFF", need=4.5):
    """Use the data colour for a label if it reaches `need`:1 (default 4.5) on `bg`, else near-black."""
    return c if contrast(c, bg) >= need else "#1A1A1A"
"""--- cumming-estimation: multi-group estimation plot with a SHARED control (Cumming
layout). Upper axes: every observation (swarm) with a gapped mean +/- s.d. line beside
each group. Lower axes: mean difference of each test group minus the same control, with
its bootstrap distribution (half violin) and percentile bootstrap CI. Groups are
independent; n per group counted from data.csv. No P value is computed."""
from collections import defaultdict

# Parameters ---------------------------------------------------------------------------
cells = "2x2"                        # 89 x 89 mm, two data axes (no +2 pt bump)
control = "Control"                  # shared control (first group if absent)
ci_level = 0.95
n_boot = 5000
boot_seed = 20261321
y_label = "Response (a.u.)"
d_label = "Mean difference\nvs control (a.u.)"

rows = list(csv.DictReader((HERE / "data.csv").open()))
groups = list(dict.fromkeys(r["group"] for r in rows))
if control not in groups:
    control = groups[0]
groups = [control] + [g for g in groups if g != control]
vals = defaultdict(list)
for r in rows:
    vals[r["group"]].append(float(r["value"]))
vals = {g: np.array(v) for g, v in vals.items()}
rng = np.random.default_rng(boot_seed)
a = (1 - ci_level) / 2
eff = {}
for g in groups[1:]:
    x, c = vals[g], vals[control]
    bx = rng.choice(x, (n_boot, len(x))).mean(1)
    bc = rng.choice(c, (n_boot, len(c))).mean(1)
    boot = bx - bc
    eff[g] = (x.mean() - c.mean(), *np.quantile(boot, [a, 1 - a]), boot)
pct = int(round(ci_level * 100))


def dark(c, need=4.5):
    """Darken a fill colour toward black until it reaches `need`:1 on white (for text)."""
    import matplotlib.colors as mc
    rgb = np.array(mc.to_rgb(c))
    for f in np.linspace(0, 1, 41):
        h = mc.to_hex(rgb * (1 - f))
        if contrast(h) >= need:
            return h
    return "#000000"


house.apply_house_style()
import matplotlib.pyplot as plt  # noqa: E402
from scipy.stats import gaussian_kde  # noqa: E402

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
fills = dict(zip(groups, ["#BFBFBF", hp[0], hp[1], hp[2], hp[4], hp[3]]))
tcol = {g: dark(fills[g]) for g in groups}
plt.rcParams["figure.constrained_layout.h_pad"] = 1.0 * house.MM
fig, (ax, bx) = house.house_figure(cells=cells, nrows=2, ncols=1, sharex=True,
                                   gridspec_kw={"height_ratios": [1.25, 1]})
xs = np.arange(len(groups))
allv = np.concatenate(list(vals.values()))
lo_y, hi_y = allv.min(), allv.max()
ax.set_ylim(lo_y - 0.06 * (hi_y - lo_y), hi_y + 0.27 * (hi_y - lo_y))
ax.set_xlim(-0.6, len(groups) - 0.4)
fig.canvas.draw()
bb = ax.get_window_extent()
mm_x = bb.width / fig.dpi * 25.4 / np.diff(ax.get_xlim())[0]     # mm per x unit
mm_y = bb.height / fig.dpi * 25.4 / np.diff(ax.get_ylim())[0]
d_mm = 1.45                                                      # point diameter + gap (mm)


def swarm(v):
    """Beeswarm x offsets (data units) so that points of diameter d_mm do not overlap."""
    order = np.argsort(v)
    placed, off = [], np.zeros(len(v))
    for i in order:
        y = v[i] * mm_y
        for k in range(0, 60):
            for s in ((0,) if k == 0 else (k, -k)):
                x = s * d_mm * 0.5
                if all((x - px) ** 2 + (y - py) ** 2 >= d_mm ** 2 for px, py in placed):
                    break
            else:
                continue
            break
        placed.append((x, y))
        off[i] = x / mm_x
    return off


for i, g in enumerate(groups):
    v = vals[g]
    ax.scatter(i - 0.08 + swarm(v), v, s=house.SCATTER["s"] * 0.55, facecolors=fills[g],
               edgecolors="#333333", linewidths=0.3, zorder=3)
    m, s = v.mean(), v.std(ddof=1)
    gx = i + 0.30
    gap = 0.22 * s                   # the gap marks the mean (Cumming / DABEST style)
    ax.plot([gx, gx], [m - s, m - gap], color="#1A1A1A", lw=1.0, solid_capstyle="butt")
    ax.plot([gx, gx], [m + gap, m + s], color="#1A1A1A", lw=1.0, solid_capstyle="butt")
    ax.text(i, hi_y + 0.25 * (hi_y - lo_y), f"{g}\nn = {len(v)}", fontsize=7, ha="center", va="top",
            color=tcol[g], linespacing=1.1)
ax.set_ylabel(y_label)
ax.tick_params(axis="x", length=0, labelbottom=False)
house.add_house_tag(ax, "a")

# lower: effects vs the shared control
bx.axhline(0, color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=0, gid="ignore")
for i, g in enumerate(groups[1:], start=1):
    md, clo, chi, boot = eff[g]
    kde = gaussian_kde(boot)
    yy = np.linspace(boot.min(), boot.max(), 200)
    dens = kde(yy)
    bx.fill_betweenx(yy, i, i + 0.34 * dens / dens.max(), color=fills[g], alpha=0.55, lw=0)
    bx.plot([i, i], [clo, chi], color="#1A1A1A", lw=house.LW_PT["errorbar"] * 1.2, solid_capstyle="butt")
    bx.plot([i], [md], ls="none", marker="o", ms=3.4, mfc=fills[g], mec="#1A1A1A", mew=0.4, zorder=4)
allb = np.concatenate([[e[1], e[2], e[3].min(), e[3].max(), 0] for e in eff.values()])
rng_b = allb.max() - allb.min()
pad = 0.08 * rng_b
bx.set_ylim(allb.min() - 0.30 * rng_b, allb.max() + pad)
for i, g in enumerate(groups[1:], start=1):      # value labels under each bootstrap distribution
    md, clo, chi, boot = eff[g]
    bx.text(i, boot.min() - 0.03 * rng_b, f"{md:+.2f}\n[{clo:+.2f}, {chi:+.2f}]", fontsize=6.5,
            ha="center", va="top", color=tcol[g], linespacing=1.1)
bx.set_xticks(xs)
bx.set_xticklabels(["Shared\ncontrol"] + [f"{g}\nminus control" for g in groups[1:]], fontsize=7)
bx.tick_params(axis="x", length=0)
bx.set_ylabel(d_label)
bx.text(0.02, 0.97, f"Simulated data\nUpper: gap = mean, line = 1 s.d.\nLower: {pct}% percentile\nbootstrap CI, {n_boot} resamples",
        transform=bx.transAxes, fontsize=6, color=grey["mid"], ha="left", va="top", linespacing=1.15)
house.add_house_tag(bx, "b")
house.save_house(fig, HERE / "figure")
for g in groups:
    print(f"{g}: n = {len(vals[g])}, mean {vals[g].mean():.3f}, s.d. {vals[g].std(ddof=1):.3f}")
for g, (md, clo, chi, _) in eff.items():
    print(f"{g} minus {control}: {md:+.3f} ({pct}% percentile bootstrap CI {clo:+.3f} to {chi:+.3f}; {n_boot} resamples, seed {boot_seed})")
print("wrote figure.pdf, figure.png, preview.png")
