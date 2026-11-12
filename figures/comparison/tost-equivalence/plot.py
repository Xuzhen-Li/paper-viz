"""TOST equivalence plot: mean difference with its (1 - 2 alpha) Welch CI against the
pre-specified equivalence bounds -Delta and +Delta, with both one-sided Welch t-tests
printed inside the frame. House style. Reads data.csv only. Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np
from scipy.stats import t as tdist

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent

# Parameters ---------------------------------------------------------------------------
delta = 0.50          # pre-specified equivalence margin (same units as score)
alpha = 0.05          # level of EACH one-sided test
cells = "3x1"
unit = "a.u."
band_top = 0.45       # bounds band / reference lines drawn below this axes fraction


def fmt_p(p):
    return "P < 0.001" if p < 0.001 else f"P = {p:.3f}"


def sgn(x):
    return f"{x:+.2f}".replace("+-", "-")


rows = list(csv.DictReader((HERE / "data.csv").open()))
groups = list(dict.fromkeys(r["group"] for r in rows))
if len(groups) != 2:
    raise ValueError(f"expected 2 groups, got {groups!r}")
g0, g1 = groups
a = np.array([float(r["score"]) for r in rows if r["group"] == g0])
b = np.array([float(r["score"]) for r in rows if r["group"] == g1])
n0, n1 = int(a.size), int(b.size)
v0, v1 = a.var(ddof=1), b.var(ddof=1)
diff = float(b.mean() - a.mean())
se = float(np.sqrt(v0 / n0 + v1 / n1))
df = float((v0 / n0 + v1 / n1) ** 2 / ((v0 / n0) ** 2 / (n0 - 1) + (v1 / n1) ** 2 / (n1 - 1)))
t_crit = float(tdist.ppf(1.0 - alpha, df))
lo, hi = diff - t_crit * se, diff + t_crit * se
p_lower = float(tdist.sf((diff + delta) / se, df))   # H0: diff <= -delta
p_upper = float(tdist.cdf((diff - delta) / se, df))  # H0: diff >= +delta
equiv = max(p_lower, p_upper) < alpha
ci_pct = int(round((1.0 - 2.0 * alpha) * 100))

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
c = hp[0]
TEXT = "#1A1A1A"

house.apply_house_style()
fig, ax = house.house_figure(cells=cells)

span = max(delta, abs(lo), abs(hi)) * 1.45
ax.set_xlim(-span, span)
ax.set_ylim(0, 1)
yb = band_top
ax.fill_between([-delta, delta], 0, yb, color=house.pv_palette("house_div")[3], lw=0, zorder=0)
for x, ls, col in [(-delta, (0, (2, 2)), grey["dark"]), (delta, (0, (2, 2)), grey["dark"]), (0.0, (0, (1, 1.5)), grey["ref"])]:
    ax.plot([x, x], [0, yb], color=col, lw=house.LW_PT["ref"], ls=ls, zorder=1)
ax.text(-delta - 0.02 * span, 0.05, f"-\u0394 = {-delta:.2f}", color=TEXT, fontsize=7, ha="right", va="bottom")
ax.text(delta + 0.02 * span, 0.05, f"+\u0394 = +{delta:.2f}", color=TEXT, fontsize=7, ha="left", va="bottom")

y0 = 0.25
ax.plot([lo, hi], [y0, y0], color=c, lw=house.LW_PT["errorbar"] * 1.5, solid_capstyle="butt", zorder=3)
for x in (lo, hi):
    ax.plot([x, x], [y0 - 0.05, y0 + 0.05], color=c, lw=house.LW_PT["errorbar"], zorder=3)
ax.plot([diff], [y0], ls="none", color=c, markerfacecolor=c, zorder=4, **house.POINT)

note = (
    f"TOST: two one-sided Welch t-tests\nalpha = {alpha:.2f} for each test, no multiplicity correction\n"
    f"Lower test, H0: diff <= -{delta:.2f}, one-sided: {fmt_p(p_lower)}\n"
    f"Upper test, H0: diff >= +{delta:.2f}, one-sided: {fmt_p(p_upper)}"
)
ax.text(0.012, 0.97, note, transform=ax.transAxes, fontsize=6.5, color=TEXT, ha="left", va="top", linespacing=1.25)
verdict = "equivalent (both P < alpha)" if equiv else "not shown equivalent"
ax.text(0.012, 0.585, f"Mean difference {sgn(diff)}, {ci_pct}% CI [{lo:.2f}, {hi:.2f}]: {verdict}",
        transform=ax.transAxes, fontsize=7, color=c, ha="left", va="top")
ax.text(
    0.988, 0.97,
    f"Simulated data\nn = {n0} ({g0}), {n1} ({g1})\n"
    f"Point: mean difference\nBar: {ci_pct}% Welch CI\nBand: equivalence bounds",
    transform=ax.transAxes, fontsize=6, color=grey["mid"], ha="right", va="top", linespacing=1.2,
)
ax.set_yticks([])
ax.set_xlabel(f"Mean difference, {g1} - {g0} ({unit})")

house.save_house(fig, HERE / "figure")
print("wrote figure.pdf, figure.png, preview.png")
