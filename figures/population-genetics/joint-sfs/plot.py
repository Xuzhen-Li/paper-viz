# Joint site frequency spectrum of two populations (house style): log10 SNP count per cell of
# derived-allele counts (pop 1 x pop 2), empty cells white, with each population's marginal SFS
# as bars on the top and right edges and Hudson's Fst computed from the spectrum.
# Reads data.csv only. Run: python3 plot.py
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.colors import LogNorm
from matplotlib.ticker import FuncFormatter, NullLocator

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent

# Parameters ---------------------------------------------------------------------------
pop1, pop2 = "Pop 1", "Pop 2"
footnote = "Simulated data"
cells = "2x2"


def plain_pow10(x, _pos=None):
    """Log-axis tick as plain text (no mathtext exponents)."""
    if x <= 0:
        return ""
    exp = int(round(np.log10(x)))
    if not np.isclose(x, 10.0 ** exp, rtol=1e-6, atol=0):
        return ""
    if exp == 0:
        return "1"
    if exp == 1:
        return "10"
    return f"10^{exp}"


house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
c1, c2 = hp[0], hp[4]
cmap = house.house_cmap("house_warm")
cmap.set_bad("white")
TEXT = "#1A1A1A"

d = pd.read_csv(HERE / "data.csv")
n1, n2 = int(d.d1.max()), int(d.d2.max())
J = np.zeros((n1 + 1, n2 + 1))
J[d.d1, d.d2] = d["count"]
S = J.sum()
i, j = np.meshgrid(np.arange(n1 + 1), np.arange(n2 + 1), indexing="ij")
p1, p2 = i / n1, j / n2
num = (p1 - p2) ** 2 - p1 * (1 - p1) / (n1 - 1) - p2 * (1 - p2) / (n2 - 1)
den = p1 * (1 - p2) + p2 * (1 - p1)
fst = (J * num).sum() / (J * den).sum()

fig = house.house_figure(cells=cells)[0]
fig.clf()
gs = fig.add_gridspec(2, 2, width_ratios=[4, 1], height_ratios=[1, 4])
ax = fig.add_subplot(gs[1, 0])
at = fig.add_subplot(gs[0, 0], sharex=ax)
ar = fig.add_subplot(gs[1, 1], sharey=ax)
# keep the upper-right slot empty (no colour bar, no footnote)
slot = fig.add_subplot(gs[0, 1])
slot.axis("off")

M = np.ma.masked_where(J.T == 0, J.T)
mesh = ax.pcolormesh(
    np.arange(n1 + 2) - 0.5, np.arange(n2 + 2) - 0.5, M, cmap=cmap,
    norm=LogNorm(vmin=1, vmax=J.max()), edgecolors="white", linewidth=0.3,
)
ax.plot([-0.5, n1 + 0.5], [-0.5, n2 + 0.5], ls=(0, (3, 2)), color=grey["ref"], lw=house.LW_PT["ref"])
ax.set_xlabel(f"Derived allele count, {pop1} (n = {n1})", color=c1)
ax.set_ylabel(f"Derived allele count, {pop2} (n = {n2})", color=c2)
ax.set_xticks(range(0, n1 + 1, 5))
ax.set_yticks(range(0, n2 + 1, 4))
ax.set_xlim(-0.5, n1 + 0.5)
ax.set_ylim(-0.5, n2 + 0.5)

# Colour bar in the empty upper-left cells of the MAIN heatmap (column d1 = 0,
# rows d2 = 13-16 are empty). 2 mm wide, length <= 60% of the panel.
fig.canvas.draw()
pos = ax.get_position()
ax_w_mm = pos.width * house.house_canvas(cells)["width_mm"]
w_frac = 2.0 / ax_w_mm
x0, x1 = ax.get_xlim()
y0, y1 = ax.get_ylim()
# stay over d1 ~ 0 (cell -0.5..0.5); vertical span d2 13.2-16.35
left = (0.02 - x0) / (x1 - x0)  # slightly inside cell 0
bottom = (13.25 - y0) / (y1 - y0)
height = (16.35 - 13.25) / (y1 - y0)
# if 2 mm is wider than cell 0, shift left so the bar does not cover d1 = 1 tiles
if left + w_frac > (0.48 - x0) / (x1 - x0):
    left = (0.48 - x0) / (x1 - x0) - w_frac
    left = max(left, 0.005)
cax = ax.inset_axes([left, bottom, w_frac, min(height, 0.60)])
cb = fig.colorbar(mesh, cax=cax)
cb.outline.set_linewidth(house.LW_PT["frame"])
cax.minorticks_off()
cax.tick_params(labelsize=7, length=2)
# Colour-bar title INSIDE the main heatmap frame, in the empty cells d1 = 1-3,
# d2 = 15, just right of the bar; centred between the top tick label and the d2 = 14 tiles.
cb_title = ax.annotate(
    "SNPs", xy=(left + w_frac, 14.965), xycoords=("axes fraction", "data"),
    xytext=(4.0, 0.0), textcoords="offset points", ha="left", va="center",
    fontsize=7, color=TEXT,
)
cb.set_ticks([1, J.max() if J.max() < 100 else 1000])
cax.yaxis.set_major_formatter(FuncFormatter(plain_pow10))
cax.yaxis.set_minor_locator(NullLocator())

# Fst and footnote inside the main heatmap frame (lower right, light tiles)
ax.text(
    0.97, 0.05,
    f"S = {int(S):,}\nHudson Fst = {fst:.3f}\n{footnote}",
    transform=ax.transAxes, ha="right", va="bottom", fontsize=7, color=TEXT,
)

m1 = J.sum(1)
m2 = J.sum(0)
at.bar(np.arange(n1 + 1), m1, width=0.75, color=c1, lw=0)
ar.barh(np.arange(n2 + 1), m2, height=0.75, color=c2, lw=0)
at.set_yscale("log")
ar.set_xscale("log")
at.tick_params(labelbottom=False)
ar.tick_params(labelleft=False)
at.set_ylabel("SNPs")
ar.set_xlabel("SNPs")
at.minorticks_off()
ar.minorticks_off()
at.yaxis.set_minor_locator(NullLocator())
ar.xaxis.set_minor_locator(NullLocator())
at.yaxis.set_major_formatter(FuncFormatter(plain_pow10))
ar.xaxis.set_major_formatter(FuncFormatter(plain_pow10))
house.save_house(fig, HERE / "figure", cells=cells)
print("wrote figure.pdf, figure.png, preview.png")
print(f"colorbar_request_mm=2.0 ax_w_mm={ax_w_mm:.2f} w_frac={w_frac:.4f} left={left:.3f} bottom={bottom:.3f} height={height:.3f}")
