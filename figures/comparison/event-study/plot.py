"""Event-study plot: dynamic coefficients by time relative to an event, from a
unit fixed-effects OLS on event-time dummies (period -1 omitted as the reference,
fixed at 0), with 95% CIs from unit-clustered standard errors. Simulated data;
not a causal claim.
House style, single 2x2 panel: the +2 pt bump is applied up front (9 pt ticks,
10 pt axis titles), labels are placed at printed size, then save_house(bump=0).
Reads data.csv only. Run from this directory: python3 plot.py"""
import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import t as t_dist

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

REF = -1                # omitted reference period
LEVEL = 0.95            # CI level drawn as whiskers
CELLS = (2, 2)
FS_LABEL = 8
FS_NOTE = 7

rows = list(csv.DictReader(open("data.csv")))
unit = np.array([int(r["unit_id"]) for r in rows])
time = np.array([int(r["time"]) for r in rows])
y = np.array([float(r["y"]) for r in rows])
units = np.unique(unit)
n_units, n_obs = int(units.size), int(y.size)
times = np.array(sorted(np.unique(time)))
if REF not in times:
    raise ValueError(f"reference period {REF} not in data")
ev = times[times != REF]

# within (unit-demeaned) OLS on event-time dummies
D = np.column_stack([(time == t).astype(float) for t in ev])
y_w, D_w = y.copy(), D.copy()
for u in units:
    m = unit == u
    y_w[m] -= y[m].mean()
    D_w[m] -= D[m].mean(axis=0)
xtx_inv = np.linalg.inv(D_w.T @ D_w)
beta = xtx_inv @ D_w.T @ y_w
resid = y_w - D_w @ beta
meat = np.zeros((ev.size, ev.size))
for u in units:
    m = unit == u
    s = D_w[m].T @ resid[m]
    meat += np.outer(s, s)
G = n_units
dof_adj = G / (G - 1)                       # small-sample cluster adjustment
se = np.sqrt(np.diag(dof_adj * xtx_inv @ meat @ xtx_inv))
crit = float(t_dist.ppf(0.5 + LEVEL / 2, G - 1))

est = dict(zip(ev.tolist(), beta.tolist()))
half = dict(zip(ev.tolist(), (crit * se).tolist()))
est[REF], half[REF] = 0.0, 0.0
xx = times.astype(float)
yy = np.array([est[t] for t in times])
hh = np.array([half[t] for t in times])
pre = times < 0

hp = house.pv_palette("house")
c_post, c_pre = hp[0], "#595959"
grey = house.pv_palette("house_grey")
ink = "#1A1A1A"

house.apply_house_style(single_panel=True)
fig, ax = house.house_figure(cells=CELLS)

x0, x1 = float(times.min()) - 0.6, float(times.max()) + 0.6
ax.axvspan(x0, -0.5, color=grey["bg"], lw=0, zorder=0, gid="ignore")
ax.axhline(0.0, color=grey["ref"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=1)
ax.axvline(-0.5, color=grey["mid"], lw=house.LW_PT["ref"], ls=(0, (2, 2)), zorder=1)
ax.plot(xx, yy, color=grey["ci"], lw=house.LW_PT["minor"], zorder=2)
for mask, col in ((pre, c_pre), (~pre, c_post)):
    ax.errorbar(xx[mask], yy[mask], yerr=hh[mask], fmt="o", color=col, ecolor=col,
                elinewidth=house.LW_PT["errorbar"], capsize=1.8, capthick=house.LW_PT["errorbar"],
                markerfacecolor=col, markeredgecolor="#000000",
                markeredgewidth=house.POINT["markeredgewidth"], markersize=house.POINT["markersize"],
                zorder=3)
# reference period: open marker, no interval
ax.plot([REF], [0.0], ls="none", marker="o", markersize=house.POINT["markersize"],
        markerfacecolor="white", markeredgecolor="#000000", markeredgewidth=0.6, zorder=4)

ax.set_xticks(list(times))
ax.set_xticklabels([str(t) for t in times])
ax.set_xlabel("Periods relative to event")
ax.set_ylabel("Effect on outcome (a.u.)")
ax.set_xlim(x0, x1)
lo, hi = float((yy - hh).min()), float((yy + hh).max())
span = hi - lo
ax.set_ylim(lo - 0.50 * span, hi + 0.14 * span)
step = 0.5 if span > 0.8 else 0.25
ax.set_yticks(np.arange(np.ceil((lo - 0.45 * span) / step) * step, hi + 0.1 * span, step))
top = ax.get_ylim()[1]

ax.text((x0 + -0.5) / 2, top - 0.03 * span, "Pre-event", color="#333333", fontsize=FS_LABEL,
        ha="center", va="top")
ax.text(-0.3, top - 0.03 * span, "Post-event", color=c_post, fontsize=FS_LABEL, ha="left", va="top")

note = (f"Simulated data; not a causal claim.\n"
        f"n = {n_units} units x {times.size} periods\n"
        f"({n_obs} obs). Unit fixed-effects OLS;\n"
        f"open circle: period {REF} = 0 (reference).\n"
        f"Whiskers: {LEVEL:.0%} CI, unit-clustered SE.")
ax.text(0.985, 0.025, note, transform=ax.transAxes, color=ink, fontsize=FS_NOTE,
        ha="right", va="bottom", linespacing=1.15)

house.save_house(fig, "figure", cells=CELLS, bump=0)
print("wrote figure.pdf, figure.png, preview.png")
