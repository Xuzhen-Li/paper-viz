"""Spatial spot map (house style). Layout only; simulated data. Reads data.csv only.
a: spots coloured by region, regions labelled directly; b, c: two feature channels on the
same spots. Run from this directory: python3 plot.py"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.collections import PatchCollection
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.patches import Circle

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "3x2"
spot_d = 55.0          # spot diameter (um) drawn on the 100 um grid
scalebar_um = 1000
clip_pct = (2, 98)     # colour scale clipped to these percentiles
footnote = "Simulated data"
channels = [("feature_a", "Feature A (transcript)", "log1p counts"),
            ("feature_b", "Feature B (m/z peak)", "rel. intensity")]

house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
cmaps = [house.house_cmap("house_warm"),
         LinearSegmentedColormap.from_list("blue", ["#DEE4F0", "#8EBDDA", "#4A82B0", "#1D7CBB"])]
label_box = dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.85)

d = pd.read_csv(Path(__file__).with_name("data.csv"))
regions = sorted(d.region.unique(), key=lambda s: int(s.split()[-1]))
rcol = {r: hp[i] for i, r in enumerate(regions)}
n_spots = int(len(d))
n_reg = {r: int((d.region == r).sum()) for r in regions}
xlim = (d.x_um.min() - 250, d.x_um.max() + 250)
ylim = (d.y_um.min() - 350, d.y_um.max() + 750)
ylim_side = (d.y_um.min() - 1000, d.y_um.max() + 650)  # bottom band holds the colour bar


def spots(ax, colors, ylim=ylim):
    pc = PatchCollection([Circle((a, b), spot_d / 2) for a, b in zip(d.x_um, d.y_um)],
                         facecolors=colors, edgecolors="none")
    ax.add_collection(pc)
    ax.set_xlim(*xlim)
    ax.set_ylim(*ylim)
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])


def label_xy(r):
    """Label anchor: the region spot closest to the region's median x/y (stays on the region)."""
    s = d[d.region == r]
    mx, my = s.x_um.median(), s.y_um.median()
    i = ((s.x_um - mx) ** 2 + (s.y_um - my) ** 2).idxmin()
    return s.x_um[i], s.y_um[i]


fig, axs = house.house_figure(cells=cells, nrows=2, ncols=2, gridspec_kw={"width_ratios": [2, 1]})
gs = axs[0, 0].get_gridspec()
axs[0, 0].remove()
axs[1, 0].remove()
ax_a = fig.add_subplot(gs[:, 0])
spots(ax_a, [rcol[r] for r in d.region])
small = regions[-1]  # the island region is labelled with a leader to free space
for r in regions:
    x, y = label_xy(r)
    if r == small:
        s = d[d.region == r]
        j = s.x_um.idxmin()
        ax_a.annotate(f"{r}\nn = {n_reg[r]}", xy=(s.x_um[j], s.y_um[j]), xytext=(xlim[0] + 120, ylim[0] + 650),
                      ha="left", va="bottom", fontsize=7, color=rcol[r], linespacing=1.3,
                      arrowprops=dict(arrowstyle="-", lw=0.5, color=rcol[r], shrinkA=1, shrinkB=2))
    else:
        ax_a.text(x, y, f"{r}, n = {n_reg[r]}", ha="center", va="center", fontsize=7,
                  color="#000000", bbox=label_box)
ax_a.text(0.02, 0.98, f"{footnote}\nn = {n_spots:,} spots, 100 µm grid", transform=ax_a.transAxes,
          ha="left", va="top", fontsize=6, color=grey["mid"], linespacing=1.4)
x1 = xlim[1] - 200
ax_a.plot([x1 - scalebar_um, x1], [ylim[1] - 300] * 2, color="#000000", lw=1.5, solid_capstyle="butt")
ax_a.text(x1 - scalebar_um / 2, ylim[1] - 360, f"{scalebar_um / 1000:g} mm", ha="center", va="top", fontsize=7)
house.add_house_tag(ax_a, "a")

side = [axs[0, 1], axs[1, 1]]
for ax, (col, title, unit), cm, tag in zip(side, channels, cmaps, "bc"):
    v = d[col].to_numpy()
    lo, hi = np.percentile(v, clip_pct)
    norm = np.clip((v - lo) / (hi - lo), 0, 1)
    spots(ax, cm(norm), ylim=ylim_side)
    ax.text(0.03, 0.97, title, transform=ax.transAxes, ha="left", va="top", fontsize=7)
    cax = ax.inset_axes([0.06, 0.10, 0.42, 0.045])
    cax.imshow(np.linspace(0, 1, 64)[None, :], aspect="auto", cmap=cm, extent=(lo, hi, 0, 1))
    cax.set_yticks([])
    cax.set_xticks([lo, hi])
    cax.set_xticklabels([f"{lo:.1f}", f"{hi:.1f}"], fontsize=6)
    cax.tick_params(axis="x", length=1.5, pad=1)
    cax.text(1.06, 0.5, unit, transform=cax.transAxes, ha="left", va="center", fontsize=6)
    house.add_house_tag(ax, tag)

out = house.save_house(fig, "figure", cells=cells)
W, H = fig.get_figwidth() * 72, fig.get_figheight() * 72
for name, ax in [("a", ax_a), ("b", side[0]), ("c", side[1])]:
    bb = ax.get_position()
    print(f"AXES {name} {bb.x0 * W:.2f} {(1 - bb.y1) * H:.2f} {bb.x1 * W:.2f} {(1 - bb.y0) * H:.2f}")
print("canvas_mm", out["width_mm"], out["height_mm"], "n_spots", n_spots, n_reg)
