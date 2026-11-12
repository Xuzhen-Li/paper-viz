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
"""--- raincloud-paired: repeated-measures raincloud for two conditions. Outward half
violins (clouds), narrow boxes and subject points ("rain"), with a line joining each
subject's two values. Only subjects with both conditions are paired (lines, change
statistics); n is counted from data.csv. No P value is computed."""
from collections import defaultdict

from scipy.stats import gaussian_kde
from scipy.stats import t as tdist

# Parameters ---------------------------------------------------------------------------
cells = "2x2"
y_label = "Score (a.u.)"
ci_level = 0.95
jitter = 0.045
jitter_seed = 20261329

rows = list(csv.DictReader((HERE / "data.csv").open()))
conds = list(dict.fromkeys(r["condition"] for r in rows))
if len(conds) != 2:
    raise ValueError(f"expected 2 conditions, got {conds!r}")
vals = defaultdict(dict)
for r in rows:
    vals[r["subject"]][r["condition"]] = float(r["value"])
per_cond = {c: np.array([v[c] for v in vals.values() if c in v]) for c in conds}
paired = np.array([[v[c] for c in conds] for v in vals.values() if all(c in v for c in conds)])
n_pairs = len(paired)
d = paired[:, 1] - paired[:, 0]
md = d.mean()
h = tdist.ppf(0.5 + ci_level / 2, n_pairs - 1) * d.std(ddof=1) / np.sqrt(n_pairs)
n_up = int(np.sum(d > 0))
pct = int(round(ci_level * 100))


def dark(c, need=4.5):
    import matplotlib.colors as mc
    rgb = np.array(mc.to_rgb(c))
    for f in np.linspace(0, 1, 41):
        hx = mc.to_hex(rgb * (1 - f))
        if contrast(hx) >= need:
            return hx
    return "#000000"


house.apply_house_style(single_panel=True)   # one 2x2 panel: 9 pt ticks, 10 pt axis title
import matplotlib.pyplot as plt  # noqa: E402

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
cols = dict(zip(conds, [hp[0], hp[1]]))
fig, ax = house.house_figure(cells=cells)
rng = np.random.default_rng(jitter_seed)
subj = list(vals)
jx = {s: rng.uniform(-jitter, jitter) for s in subj}
allv = np.concatenate(list(per_cond.values()))
lo, hi = allv.min(), allv.max()
span = hi - lo
# pairing lines (drawn first, under the points)
for s in subj:
    v = vals[s]
    if all(c in v for c in conds):
        ax.plot([0 + jx[s], 1 + jx[s]], [v[conds[0]], v[conds[1]]], color=grey["ci"], lw=0.6, zorder=1)
for k, c in enumerate(conds):
    v = per_cond[c]
    side = -1 if k == 0 else 1                 # clouds face outward
    xs = np.array([k + jx[s] for s in subj if c in vals[s]])
    ax.scatter(xs, [vals[s][c] for s in subj if c in vals[s]], s=house.SCATTER["s"] * 0.6,
               facecolors=cols[c], edgecolors="#333333", linewidths=0.3, zorder=3)
    # narrow box: median, IQR, whiskers to the most extreme point within 1.5 IQR
    bxp = k + side * 0.17
    q1, med, q3 = np.percentile(v, [25, 50, 75])
    iqr = q3 - q1
    wlo, whi = v[v >= q1 - 1.5 * iqr].min(), v[v <= q3 + 1.5 * iqr].max()
    w = 0.06
    ax.add_patch(plt.Rectangle((bxp - w / 2, q1), w, iqr, facecolor=cols[c], alpha=0.6,
                               edgecolor="#1A1A1A", lw=0.5, zorder=2))
    ax.plot([bxp - w / 2, bxp + w / 2], [med, med], color="#1A1A1A", lw=0.8, zorder=3)
    ax.plot([bxp, bxp], [wlo, q1], color="#1A1A1A", lw=0.5, zorder=2)
    ax.plot([bxp, bxp], [q3, whi], color="#1A1A1A", lw=0.5, zorder=2)
    # half violin, clipped to this condition's observed min/max (no combined-span extension)
    kde = gaussian_kde(v)
    yy = np.linspace(v.min(), v.max(), 300)
    yy = yy[kde(yy) >= 0.01 * kde(yy).max()]   # drop negligible density inside the observed range
    dd = kde(yy)
    x0 = k + side * 0.25
    ax.fill_betweenx(yy, x0, x0 + side * 0.42 * dd / dd.max(), color=cols[c], alpha=0.6, lw=0, zorder=1)
ax.set_xticks([0, 1])
ax.set_xticklabels([f"{c}\nn = {len(per_cond[c])}" for c in conds])
ax.tick_params(axis="x", length=0)
ax.set_xlim(-0.78, 1.78)
ax.set_ylim(lo - 0.34 * span, hi + 0.34 * span)
ax.set_ylabel(y_label)
ax.text(0.5, 0.975, f"Paired n = {n_pairs}; {n_up} of {n_pairs} increased\nMean change (Condition 2 − Condition 1) {md:+.1f}\n({pct}% t CI {md - h:+.1f} to {md + h:+.1f})",
        transform=ax.transAxes, fontsize=8, ha="center", va="top", color="#1A1A1A", linespacing=1.2)
n_unpaired = len(subj) - n_pairs
ax.text(0.5, 0.02, "Simulated data. Grey lines join each subject's two values"
        + (f"\n{n_unpaired} subject(s) without a second value: point, no line" if n_unpaired else "")
        + "\nBox: median, IQR; whiskers to 1.5 IQR",
        transform=ax.transAxes, fontsize=7, ha="center", va="bottom", color=grey["mid"], linespacing=1.2)
house.save_house(fig, HERE / "figure", bump=0)
print({c: len(v) for c, v in per_cond.items()}, "pairs:", n_pairs, "increased:", n_up)
print(f"mean change {md:+.3f}; {pct}% t CI {md - h:+.3f} to {md + h:+.3f}")
print("wrote figure.pdf, figure.png, preview.png")
