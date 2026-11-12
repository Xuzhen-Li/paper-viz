# LD triangle (house style): pairwise r^2 between the SNPs of one region drawn as a rotated
# triangle under a physical-position bar, with thin lines linking each SNP to its position,
# block outlines with mean r^2, and an optional lead SNP. Reads data.csv only. Run: python3 plot.py
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.collections import PolyCollection
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.patches import Polygon

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent

# Parameters ---------------------------------------------------------------------------
lead_snp = "snp27"                     # None to hide the lead SNP marker
blocks = [("snp01", "snp18"), ("snp19", "snp38"), ("snp39", "snp60")]
chrom_label = "Chr05"
footnote = "Simulated data"
cells = "3x2"
# unicode superscript two: single body-size glyph, not a mathtext shrink
R2 = "r\u00b2"

house.apply_house_style()
grey = house.pv_palette("house_grey")
hp = house.pv_palette("house")
TEXT = "#1A1A1A"

d = pd.read_csv(HERE / "data.csv")
snps = pd.concat([d[["snp1", "pos1"]].set_axis(["snp", "pos"], axis=1),
                  d[["snp2", "pos2"]].set_axis(["snp", "pos"], axis=1)]).drop_duplicates("snp")
snps = snps.sort_values("pos").reset_index(drop=True)
idx = {s: i for i, s in enumerate(snps.snp)}
n = len(snps)
d["i"] = d.snp1.map(idx)
d["j"] = d.snp2.map(idx)

cx = (d.i + d.j) / 2.0
cy = -(d.j - d.i) / 2.0
verts = [[(x, y + 0.5), (x + 0.5, y), (x, y - 0.5), (x - 0.5, y)] for x, y in zip(cx, cy)]
cmap = LinearSegmentedColormap.from_list("ld", [house.pv_palette("house_div")[4]] + house.pv_palette("house_warm"))

fig, ax = house.house_figure(cells=cells)
pc = PolyCollection(verts, array=d.r2.to_numpy(), cmap=cmap, clim=(0, 1), edgecolors="none")
ax.add_collection(pc)

top, link = 7.0, 4.0
lo, hi = snps.pos.min(), snps.pos.max()
px = (snps.pos - lo) / (hi - lo) * (n - 1)
ax.plot([0, n - 1], [top, top], color="black", lw=house.LW_PT["frame"], solid_capstyle="butt")
for k in range(n):
    ax.plot([px[k], px[k], k], [top, link, 0.5], color=grey["ref"], lw=0.3)
kb = np.arange(0, (hi - lo) / 1e3 + 1, 50)
for v in kb:
    x = v * 1e3 / (hi - lo) * (n - 1)
    ax.plot([x, x], [top, top + 0.8], color="black", lw=house.LW_PT["tick"])
    ax.text(x, top + 1.2, f"{(lo / 1e3 + v) / 1e3:.2f}", ha="center", va="bottom", fontsize=7)
# axis title 8 pt (v1 used 7 pt)
ax.text(-0.8, top, f"{chrom_label} (Mb)", ha="right", va="center", fontsize=8)

for b, (s0, s1) in enumerate(blocks, start=1):
    a, z = idx[s0], idx[s1]
    tri = [(a - 0.5, 0.5), (z + 0.5, 0.5), ((a + z) / 2, -(z - a) / 2 - 0.5)]
    ax.add_patch(Polygon(
        tri, closed=True, fill=False, edgecolor="black", lw=house.LW_PT["frame"]))
    inside = d[(d.i >= a) & (d.j <= z)]
    ax.text((a + z) / 2, -(z - a) / 2 - 1.6, f"Block {b}\nmean {R2} = {inside.r2.mean():.2f}",
            ha="center", va="top", fontsize=7, color=TEXT, linespacing=1.1)

if lead_snp is not None:
    k = idx[lead_snp]
    ax.plot(px[k], top + 0.0, marker="v", ms=4.5, mfc=hp[3], mec="black", mew=0.3, clip_on=False, zorder=5)
    ax.text(px[k] + 0.8, top - 0.6, f"lead {lead_snp}", ha="left", va="top", fontsize=7, color=hp[3])

ax.set_xlim(-9, n + 1)
ax.set_ylim(-(n - 1) / 2 - 1.5, top + 3.6)
ax.set_xticks([])
ax.set_yticks([])

# colour bar 2 mm wide, inside the frame, length <= 60%
fig.canvas.draw()
pos = ax.get_position()
ax_w_mm = pos.width * house.house_canvas(cells)["width_mm"]
w_frac = 2.0 / ax_w_mm
cax = ax.inset_axes([0.04, 0.10, w_frac, 0.36])
cb = fig.colorbar(pc, cax=cax, ticks=[0, 0.5, 1])
cb.outline.set_linewidth(house.LW_PT["frame"])
cax.tick_params(labelsize=7, length=2)
cax.set_title(R2, fontsize=7, loc="left", pad=2)
ax.text(0.99, 0.03, f"{footnote}; n = {n} SNPs", transform=ax.transAxes, ha="right", va="bottom",
        fontsize=6, color=grey["mid"])
house.save_house(fig, HERE / "figure", cells=cells)
print("wrote figure.pdf, figure.png, preview.png")
print(f"colorbar_request_mm=2.0 ax_w_mm={ax_w_mm:.2f} w_frac={w_frac:.4f}")
