"""Critical-difference (CD) diagram: average ranks of k methods over n datasets
(rank 1 = best = highest score; ties get average ranks), a Friedman omnibus test,
and the Nemenyi critical difference at alpha = 0.05. Methods whose average ranks
differ by less than the CD are joined by a thick bar.
House style (3x2 cells, one framed axes, no bump). Reads data.csv only.
Run from this directory: python3 plot.py"""
import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import friedmanchisquare, rankdata, studentized_range

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

ALPHA = 0.05
CELLS = (3, 2)
FS_TICK, FS_LABEL, FS_NOTE = 7, 7.5, 6.5


def fmt_p(p):
    if p < 0.001:
        return "P < 0.001"
    return f"P = {p:.3f}" if p >= 0.01 else f"P = {p:.2g}"


rows = list(csv.DictReader(open("data.csv")))
methods = list(dict.fromkeys(r["method"] for r in rows))
datasets = list(dict.fromkeys(r["dataset"] for r in rows))
k, n = len(methods), len(datasets)
M = np.full((n, k), np.nan)
for r in rows:
    M[datasets.index(r["dataset"]), methods.index(r["method"])] = float(r["score"])
if np.isnan(M).any():
    raise ValueError("every dataset needs one score per method")

ranks = np.vstack([rankdata(-M[i], method="average") for i in range(n)])
avg = ranks.mean(axis=0)
chi2, p_fried = friedmanchisquare(*[M[:, j] for j in range(k)])
q_alpha = float(studentized_range.ppf(1 - ALPHA, k, np.inf) / np.sqrt(2))
cd = q_alpha * np.sqrt(k * (k + 1) / (6.0 * n))

order = np.argsort(avg)
avg_o, names_o = avg[order], [methods[i] for i in order]
# maximal cliques of consecutive methods closer than the CD
cliques = []
for a in range(k):
    b = a
    while b + 1 < k and avg_o[b + 1] - avg_o[a] < cd:
        b += 1
    if b > a and not any(c <= a and b <= d for c, d in cliques):
        cliques.append((a, b))

ink = "#000000"
hp = house.pv_palette("house")
c_bar = hp[0]

house.apply_house_style()
fig, ax = house.house_figure(cells=CELLS)
ax.set_xticks([])
ax.set_yticks([])
ax.set_xlim(-0.75, k + 1.75)
ax.set_ylim(0, 1)

Y_AX = 0.80                                  # rank scale
ax.plot([1, k], [Y_AX, Y_AX], color=ink, lw=house.LW_PT["frame"] * 1.6)
for t in range(1, k + 1):
    ax.plot([t, t], [Y_AX, Y_AX + 0.025], color=ink, lw=house.LW_PT["tick"])
    ax.text(t, Y_AX + 0.035, str(t), fontsize=FS_TICK, ha="center", va="bottom")
for t in np.arange(1.5, k, 1.0):
    ax.plot([t, t], [Y_AX, Y_AX + 0.013], color=ink, lw=house.LW_PT["tick"])
ax.text(1, Y_AX + 0.105, "Average rank (1 = best)", fontsize=8, ha="left", va="bottom")

# CD scale bar, upper right, in rank units
cd_x1 = float(k)
ax.plot([cd_x1 - cd, cd_x1], [0.955, 0.955], color=ink, lw=1.2, solid_capstyle="butt")
for xx in (cd_x1 - cd, cd_x1):
    ax.plot([xx, xx], [0.94, 0.97], color=ink, lw=house.LW_PT["tick"])
ax.text(cd_x1 - cd - 0.08, 0.955, f"CD = {cd:.2f}", fontsize=FS_LABEL, ha="right", va="center")

# leader lines and labels: better half to the left, worse half to the right
half = (k + 1) // 2
row_y = [0.55 - 0.105 * i for i in range(max(half, k - half))]
for i, (nm, r) in enumerate(zip(names_o, avg_o)):
    if i < half:
        yl = row_y[i]
        xe = 0.55
        ax.plot([r, r, xe], [Y_AX, yl, yl], color=ink, lw=0.6, solid_joinstyle="miter")
        ax.text(xe - 0.06, yl, f"{nm} ({r:.2f})", fontsize=FS_LABEL, ha="right", va="center")
    else:
        yl = row_y[k - 1 - i]
        xe = k + 0.45
        ax.plot([r, r, xe], [Y_AX, yl, yl], color=ink, lw=0.6, solid_joinstyle="miter")
        ax.text(xe + 0.06, yl, f"({r:.2f}) {nm}", fontsize=FS_LABEL, ha="left", va="center")

# clique bars just below the scale
for j, (a, b) in enumerate(cliques):
    yb = Y_AX - 0.065 - 0.055 * j
    ax.plot([avg_o[a] - 0.03, avg_o[b] + 0.03], [yb, yb], color=c_bar, lw=3.0,
            solid_capstyle="butt", zorder=5)

note = (f"Simulated data. n = {n} datasets, k = {k} methods; score: higher is better; ties get average ranks.\n"
        f"Friedman test (omnibus, chi-square with {k - 1} d.f., upper tail; single test, no correction): "
        f"chi-square = {chi2:.1f}, {fmt_p(p_fried)}.\n"
        f"Nemenyi post-hoc, two-sided, family-wise alpha = {ALPHA:g} (studentized range, all pairs):\n"
        f"CD = q x sqrt(k(k+1) / 6n), q = {q_alpha:.3f}. Blue bars join methods whose average ranks differ by < CD.")
ax.text(0.012, 0.02, note, transform=ax.transAxes, fontsize=FS_NOTE, color="#1A1A1A",
        ha="left", va="bottom", linespacing=1.25)

house.save_house(fig, "figure", cells=CELLS)
print("wrote figure.pdf, figure.png, preview.png")
