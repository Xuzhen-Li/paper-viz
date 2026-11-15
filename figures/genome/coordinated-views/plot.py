"""Coordinated multi-view layout (house style). Layout only; simulated data. Reads data.csv only.
a: 2-D embedding; b: spatial positions; c: cluster x gene heatmap (z-score of cluster means).
The same cluster colours are used in all three views; one selected cluster is outlined in
every view. Run from this directory: python3 plot.py
v2: contrast-only text recolour (Cluster 2 / Cluster 6 labels in a use dark variants of their
swatch); 0.3 pt white separators between heatmap cells; b spans the same height as a and c
(equal x/y scale kept by widening the y range). Data, wording and colours of points unchanged."""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.patches import Rectangle

_HERE = Path(__file__).resolve()
_STYLE_CANDIDATES = [
    *([_HERE.parents[3] / "styles" / "python"] if len(_HERE.parents) > 3 else []),  # repo: figures/<cat>/<slug>/
]
STYLES = next(p for p in _STYLE_CANDIDATES if (p / "house.py").is_file())
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "4x2"
selected = "Cluster 3"
footnote = "Simulated data"
pt_size = 7.0          # marker area (pt^2) for cells in a and b

house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
div = house.house_cmap("house_div")
label_box = dict(boxstyle="round,pad=0.12", fc="white", ec="none", alpha=0.8)
# v2: dark text-only variants for the two light swatches that are < 3:1 on white.
# Points, fills and edges keep the house palette; only text set in these swatches changes.
TEXT_DARK = {"#F77E12": "#B95E0E", "#62B4E7": "#437B9E"}

d = pd.read_csv(Path(__file__).with_name("data.csv"))
clusters = sorted(d.cluster.unique(), key=lambda s: int(s.split()[-1]))
genes = [c for c in d.columns if c.startswith("Gene ")]
col = {c: hp[i] for i, c in enumerate(clusters)}
tcol = {c: TEXT_DARK.get(v.upper(), v) for c, v in col.items()}   # text colour per cluster
n_cells = int(len(d))
n_sel = int((d.cluster == selected).sum())
means = d.groupby("cluster")[genes].mean().loc[clusters]
z = (means - means.mean()) / means.std(ddof=0)   # z-score across clusters, per gene
Z = z.T.to_numpy()                                # genes x clusters

fig, (ax_a, ax_b, ax_c) = house.house_figure(cells=cells, ncols=3, gridspec_kw={"width_ratios": [1.0, 1.25, 0.75]})


def cells_view(ax, xcol, ycol):
    rest = d[d.cluster != selected]
    ax.scatter(rest[xcol], rest[ycol], s=pt_size, c=[col[c] for c in rest.cluster], linewidths=0)
    sel = d[d.cluster == selected]
    ax.scatter(sel[xcol], sel[ycol], s=pt_size * 1.6, c=col[selected], edgecolors="#000000", linewidths=0.35,
               zorder=3)
    ax.set_xticks([])
    ax.set_yticks([])


cells_view(ax_a, "emb_1", "emb_2")
ax_a.set_xlabel("Embedding 1")
ax_a.set_ylabel("Embedding 2")
for c in clusters:
    s = d[d.cluster == c]
    ax_a.text(s.emb_1.median(), s.emb_2.max() + 0.3, c, ha="center", va="bottom", fontsize=7,
              color=tcol[c] if c != selected else "#000000", bbox=label_box,
              fontweight="bold" if c == selected else "normal")
y0, y1 = d.emb_2.min(), d.emb_2.max()
ax_a.set_ylim(y0 - 2.6, y1 + 2.0)
ax_a.text(0.03, 0.03, f"{footnote}\nn = {n_cells:,} cells", transform=ax_a.transAxes, ha="left", va="bottom",
          fontsize=6, color=grey["mid"], linespacing=1.4)
house.add_house_tag(ax_a, "a")

cells_view(ax_b, "x_um", "y_um")
bx0, bx1, by0, by1 = -60, 2460, -330, 2400   # v1 limits; y range is widened below for equal scale
ax_b.set_xlim(bx0, bx1)
ax_b.set_ylim(by0, by1)
ax_b.set_xlabel("Spatial x")
ax_b.set_ylabel("Spatial y")
house.add_house_tag(ax_b, "b")

nr, nc = Z.shape
lim = float(np.ceil(np.abs(Z).max() * 2) / 2)
ax_c.imshow(Z, cmap=div, vmin=-lim, vmax=lim, aspect="auto", interpolation="nearest",
            extent=(0, nc, nr, 0))
# v2: 0.3 pt white separators between heatmap cells
ax_c.hlines(np.arange(1, nr), 0, nc, colors="white", lw=0.3, zorder=2)
ax_c.vlines(np.arange(1, nc), 0, nr, colors="white", lw=0.3, zorder=2)
for j, c in enumerate(clusters):
    ax_c.add_patch(Rectangle((j, -0.9), 1, 0.7, color=col[c], lw=0, clip_on=True))
    ax_c.text(j + 0.5, -1.05, c.split()[-1], ha="center", va="bottom", fontsize=7)
js = clusters.index(selected)
ax_c.add_patch(Rectangle((js, -0.9), 1, nr + 0.9, fill=False, ec="#000000", lw=1.2, zorder=4))
ax_c.text(0.08, -2.05, "Cluster", ha="left", va="bottom", fontsize=7)
ax_c.set_xlim(0, nc)
ax_c.set_ylim(nr + 1.9, -2.6)
ax_c.set_xticks([])
ax_c.set_yticks(np.arange(nr) + 0.5)
ax_c.set_yticklabels(genes)
cax = ax_c.inset_axes([0.08, 0.06, 0.5, 0.03])
cax.imshow(np.linspace(-lim, lim, 64)[None, :], cmap=div, aspect="auto", extent=(-lim, lim, 0, 1))
cax.set_yticks([])
cax.set_xticks([-lim, 0, lim])
cax.set_xticklabels([f"{-lim:g}", "0", f"{lim:g}"], fontsize=6)
cax.tick_params(axis="x", length=1.5, pad=1)
cax.text(1.05, 0.5, "z-score", transform=cax.transAxes, ha="left", va="center", fontsize=6)
house.add_house_tag(ax_c, "c")

# v2: b keeps the full height of a and c; equal x/y data scale by widening the y range evenly
bar, = ax_b.plot([1850, 2350], [by0 + 130, by0 + 130], color="#000000", lw=1.5, solid_capstyle="butt")
bar_t = ax_b.text(1800, by0 + 130, "500 µm", ha="right", va="center", fontsize=7)
sel_t = ax_b.text(0, by1 - 30, f"Outlined in a–c: {selected}\nn = {n_sel} cells", ha="left", va="top", fontsize=7,
                  linespacing=1.3)
for _ in range(4):   # layout settles after a pass or two; keep 1:1 x/y scale on the final box
    fig.canvas.draw()
    bb = ax_b.get_window_extent()
    pad = ((bx1 - bx0) * bb.height / bb.width - (by1 - by0)) / 2
    assert pad >= 0, pad
    y_lo, y_hi = by0 - pad, by1 + pad
    ax_b.set_ylim(y_lo, y_hi)
    bar.set_ydata([y_lo + 130, y_lo + 130])
    bar_t.set_y(y_lo + 130)
    sel_t.set_y(y_hi - 30)
fig.set_layout_engine("none")   # freeze the settled layout so every output shares one geometry

out = house.save_house(fig, "figure", cells=cells)
bb = ax_b.get_window_extent()
print("b_scale_units_per_px x", round((bx1 - bx0) / bb.width, 4), "y", round((y_hi - y_lo) / bb.height, 4))
W, H = fig.get_figwidth() * 72, fig.get_figheight() * 72
for name, ax in [("a", ax_a), ("b", ax_b), ("c", ax_c)]:
    bb = ax.get_position()
    print(f"AXES {name} {bb.x0 * W:.2f} {(1 - bb.y1) * H:.2f} {bb.x1 * W:.2f} {(1 - bb.y0) * H:.2f}")
print("canvas_mm", out["width_mm"], out["height_mm"], "n_cells", n_cells, "n_selected", n_sel)
print(z.round(3).to_string())
