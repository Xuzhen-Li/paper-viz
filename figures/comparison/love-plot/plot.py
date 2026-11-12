"""Love plot: absolute standardized mean differences (|SMD|) of each covariate,
unadjusted vs after inverse-probability weighting, with the conventional
|SMD| = 0.1 reference line. Simulated data.
House style, single 2x2 panel: the +2 pt bump is applied up front (9 pt ticks,
10 pt axis title) and labels are placed at printed size, then save_house(bump=0).
Reads data.csv only. Run from this directory: python3 plot.py"""
import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

SMD_REF = 0.10          # conventional balance threshold drawn on the figure
CELLS = (2, 2)
RESERVED = {"unit_id", "treated", "weight"}
FS_LABEL = 9            # direct labels (printed size)
FS_NOTE = 7             # in-frame footnote (printed size)


def is_binary(x):
    return bool(np.all(np.isin(np.unique(x), [0.0, 1.0])))


def wmean(x, w):
    return float(np.sum(w * x) / np.sum(w))


rows = list(csv.DictReader(open("data.csv")))
covs = [c for c in rows[0].keys() if c not in RESERVED]
treated = np.array([int(r["treated"]) for r in rows])
weight = np.array([float(r["weight"]) for r in rows])
t1, t0 = treated == 1, treated == 0
n_all, n_t, n_c = int(treated.size), int(t1.sum()), int(t0.sum())

records = []
for name in covs:
    x = np.array([float(r[name]) for r in rows])
    if is_binary(x):
        p = x.mean()  # pooled Bernoulli s.d.
        denom = np.sqrt(p * (1 - p)) if 0 < p < 1 else 1.0
    else:
        denom = np.sqrt((x[t1].var(ddof=1) + x[t0].var(ddof=1)) / 2.0) or 1.0
    before = abs(x[t1].mean() - x[t0].mean()) / denom
    after = abs(wmean(x[t1], weight[t1]) - wmean(x[t0], weight[t0])) / denom
    records.append((name, before, after))

records.sort(key=lambda t: t[1])            # largest unadjusted |SMD| at the top
# (key sits in the empty lower-right region: small unadjusted |SMD| rows)
names = [r[0] for r in records]
before = np.array([r[1] for r in records])
after = np.array([r[2] for r in records])
k = len(names)
ypos = np.arange(k) + 3.0                   # rows below BAND reserved for the footnote
BAND = 2.35
n_over_before = int((before > SMD_REF).sum())
n_over_after = int((after > SMD_REF).sum())

hp = house.pv_palette("house")
c_before, c_after = hp[3], hp[0]            # red, blue (both >= 4.5:1 on white)
grey = house.pv_palette("house_grey")
ink = "#1A1A1A"

house.apply_house_style(single_panel=True)  # bump applied up front
fig, ax = house.house_figure(cells=CELLS)

ax.plot([SMD_REF, SMD_REF], [BAND, ypos.max() + 1.4], color=grey["dark"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=1)
for yi, b, a in zip(ypos, before, after):
    ax.plot([a, b], [yi, yi], color=grey["ci"], lw=house.LW_PT["minor"], zorder=2, solid_capstyle="butt")
pt = dict(house.POINT)
ax.plot(before, ypos, ls="none", markerfacecolor=c_before, zorder=3, **pt)
ax.plot(after, ypos, ls="none", markerfacecolor=c_after, zorder=4, **pt)

ax.set_yticks(ypos)
ax.set_yticklabels(names)
ax.tick_params(axis="y", length=0)
ax.set_xlabel("Absolute standardized mean difference")
xmax = max(0.25, float(before.max()) * 1.08)
ax.set_xlim(-0.02 * xmax, xmax)
ax.set_ylim(0.0, ypos.max() + 1.4)
ax.set_xticks(np.arange(0, xmax + 1e-9, 0.1 if xmax <= 0.6 else 0.2))

# threshold label above the top row, right of the dashed line
ax.text(SMD_REF + 0.012 * xmax, ypos.max() + 0.75, f"|SMD| = {SMD_REF:g}", color=grey["dark"],
        fontsize=FS_LABEL - 1, ha="left", va="center")

# in-frame key with counts, placed by the plot over the lower-right rows
key_y = [ypos[2], ypos[1]]
for (lab, col, cnt), yk in zip(
        [("Unadjusted", c_before, n_over_before), ("Weighted", c_after, n_over_after)], key_y):
    xk = 0.50 * xmax
    ax.plot([xk], [yk], ls="none", markerfacecolor=col, **pt)
    ax.text(xk + 0.035 * xmax, yk, f"{lab}: {cnt}/{k} > {SMD_REF:g}", color=col,
            fontsize=FS_LABEL - 1, ha="left", va="center")

note = (f"Simulated data. n = {n_all} units ({n_t} treated, {n_c} control).\n"
        "|SMD| = |mean difference| / pooled unweighted s.d.;\n"
        "Weighted: stabilized inverse-probability weights.")
ax.text(0.015, 0.012, note, transform=ax.transAxes, color=ink, fontsize=FS_NOTE,
        ha="left", va="bottom", linespacing=1.15)
ax.axhline(BAND, color=grey["light"], lw=house.LW_PT["ref"], zorder=0)

house.save_house(fig, "figure", cells=CELLS, bump=0)
print("wrote figure.pdf, figure.png, preview.png")
