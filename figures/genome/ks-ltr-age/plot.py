"""Ks distribution and LTR insertion age (house style), two panels side by side.
a: Ks of paralogous and orthologous gene pairs (histogram + density), peaks labelled.
b: insertion age of intact LTR retrotransposons, T = K / (2r), by superfamily, medians labelled.
Reads data.csv only (panel = ks / ltr). Run: python3 plot.py"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

# 可调参数 -----------------------------------------------------------------
mu = 1.3e-8                            # substitutions per site per year for T = K / (2 mu)
ks_max, ks_bin = 3.0, 0.05
peak_windows = {"Paralogs (species A)": [(0.05, 0.5), (1.1, 2.4)], "Orthologs (A vs B)": [(0.5, 1.1)]}
peak_side = {"Paralogs (species A)": ["up", "up"], "Orthologs (A vs B)": ["up"]}
display_ks = {
    "Paralogs (species A)": "Paralogs, species A",
    "Orthologs (A vs B)": "Orthologs, A vs B",
}
age_max, age_bin = 2.5, 0.1            # Mya
footnote = "Simulated data"
cells = "4x1"

house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
ks_cols = {"Paralogs (species A)": hp[0], "Orthologs (A vs B)": hp[3]}
ltr_cols = {"Gypsy": hp[2], "Copia": hp[4]}


def kde(x, grid, bw=None):
    x = np.asarray(x)
    bw = bw or 1.06 * x.std() * len(x) ** -0.2
    return np.exp(-0.5 * ((grid[:, None] - x[None, :]) / bw) ** 2).sum(1) / (len(x) * bw * np.sqrt(2 * np.pi))


def tag_inside(ax, letter):
    """10 pt bold panel letter inside the frame (a 4x1 canvas clips add_house_tag)."""
    ax.text(
        0.015, 0.97, letter.lower(), transform=ax.transAxes,
        fontsize=10, fontweight="bold", ha="left", va="top", color="#000000",
    )


d = pd.read_csv(Path(__file__).with_name("data.csv"))
fig, (a, b) = house.house_figure(cells=cells, ncols=2)

# a: Ks
bins = np.arange(0, ks_max + ks_bin, ks_bin)
grid = np.linspace(0.005, ks_max, 600)
ytop = 0
for g, c in ks_cols.items():
    x = d.value[(d.panel == "ks") & (d.group == g)]
    n = int(len(x))
    cnt, _, _ = a.hist(x, bins=bins, color=c, alpha=0.30, edgecolor="white", linewidth=0.3)
    dens = kde(x, grid, bw=0.045) * len(x) * ks_bin
    a.plot(grid, dens, color=c, lw=house.LW_PT["main"])
    for (lo, hi), side in zip(peak_windows[g], peak_side[g]):
        m = (grid >= lo) & (grid <= hi)
        k = np.argmax(np.where(m, dens, -1))
        off, ha = {"left": ((-4, 0), "right"), "right": ((4, 0), "left"), "up": ((0, 3), "center")}[side]
        j = int(grid[k] // ks_bin)
        ylab = max(dens[k], cnt[max(j - 1, 0):j + 2].max())
        a.annotate(
            f"Ks = {grid[k]:.2f}", (grid[k], ylab), xytext=off, textcoords="offset points",
            ha=ha, va="bottom" if side == "up" else "center", fontsize=7, color=c,
        )
        ytop = max(ytop, ylab)
    a.text(
        0.98, 0.92 - 0.11 * list(ks_cols).index(g),
        f"{display_ks[g]} (n = {n})",
        transform=a.transAxes, ha="right", va="top", fontsize=7, color=c,
    )
a.set_xlim(0, ks_max)
a.set_ylim(0, ytop * 1.3)
a.set_xlabel("Synonymous substitutions per site (Ks)")
a.set_ylabel("Gene pairs")

# b: LTR insertion age
bins = np.arange(0, age_max + age_bin, age_bin)
for i, (g, c) in enumerate(ltr_cols.items()):
    t = d.value[(d.panel == "ltr") & (d.group == g)] / (2 * mu) / 1e6
    n = int(len(t))
    b.hist(t, bins=bins, histtype="step", color=c, lw=house.LW_PT["main"])
    b.hist(t, bins=bins, color=c, alpha=0.20, lw=0)
    med = np.median(t)
    b.axvline(med, color=c, ls=(0, (3, 2)), lw=house.LW_PT["errorbar"])
    b.text(
        0.98, 0.92 - 0.11 * i,
        f"{g}: median {med:.2f} Mya (n = {n})",
        transform=b.transAxes, ha="right", va="top", fontsize=7, color=c,
    )
# Plain text (no mathtext superscripts): every glyph stays at the parent size.
b.text(
    0.98, 0.92 - 0.11 * 2,
    "T = K / 2r, r = 1.3e-8\nsubstitutions/site/year",
    transform=b.transAxes, ha="right", va="top", fontsize=7, color="#1A1A1A",
)
a.text(0.98, 0.04, footnote, transform=a.transAxes, ha="right", va="bottom",
       fontsize=6, color=grey["mid"])
b.set_xlim(0, age_max)
b.set_xlabel("Insertion time (Mya)")
b.set_ylabel("Intact LTR-RTs")
tag_inside(a, "a")
tag_inside(b, "b")
house.save_house(fig, "figure", cells=cells)
print("wrote figure.pdf, figure.png, preview.png")
