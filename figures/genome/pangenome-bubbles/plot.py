"""Linear graph-pangenome bubbles (house style). Layout only; simulated data. Reads data.csv only.
a: reference backbone (Path 1) with bubbles: alternative alleles are drawn as arcs (above;
a second alternative below), insertions carry a node on the arc, deletions are an edge that
skips the reference node. b: allele taken by every path at every bubble, in the same x
coordinate. Run from this directory: python3 plot.py"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.lines import Line2D
from matplotlib.patches import Rectangle

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "4x2"
ref_len_kb = 100.0
arc_w = 4.0            # drawn width of a bubble (kb); the true allele length is in the label
cell_w = 3.6           # width of a cell in panel b (kb)
footnote = "Simulated data"

house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
tcol = {"SNV": hp[0], "insertion": hp[2], "deletion": hp[3], "divergent": hp[4]}
tname = {"SNV": "SNV", "insertion": "Insertion", "deletion": "Deletion", "divergent": "Divergent (3 alleles)"}


def shade(hex_, f):
    v = np.array([int(hex_[i:i + 2], 16) for i in (1, 3, 5)]) / 255
    v = v * (1 - f)
    return "#" + "".join(f"{int(round(c * 255)):02X}" for c in v)


def kb(bp):
    return f"{bp / 1000:.1f} kb"


d = pd.read_csv(Path(__file__).with_name("data.csv"))
bub = d[d.record == "bubble"].copy()
bub["pos_kb"] = bub.pos_kb.astype(float)
bub["length_bp"] = bub.length_bp.astype(float)
info = bub.drop_duplicates("bubble").set_index("bubble")[["type", "pos_kb"]]
bubbles = sorted(info.index, key=lambda s: int(s[1:]))
paths = d[d.record == "path"].copy()
path_names = sorted(paths.path.unique(), key=lambda s: int(s.split()[-1]))
A = paths.pivot(index="path", columns="bubble", values="allele").loc[path_names, bubbles].astype(int)
n_paths, n_bub = len(path_names), len(bubbles)
ref_path = path_names[0]

fig, (ax_a, ax_b) = house.house_figure(cells=cells, nrows=2, sharex=True,
                                       gridspec_kw={"height_ratios": [1.25, 1.0]})


def length(b, a):
    return float(bub[(bub.bubble == b) & (bub.allele == a)].length_bp.iloc[0])


def arc(ax, x, h, c, lw=1.2):
    t = np.linspace(0, 1, 60)
    ax.plot(x + arc_w * (t - 0.5), h * np.sin(np.pi * t), color=c, lw=lw, solid_capstyle="round", zorder=2)


# backbone: reference nodes between bubbles (grey boxes). Inside a bubble span (arc_w wide)
# the reference allele is a coloured node on the backbone joined by edges; an insertion has
# only a direct edge on the reference side.
bh = 0.28
eg = 0.25              # gap (kb) between a node and the next edge
x_prev = 0.0
for b in bubbles:
    t, x = info.loc[b, "type"], info.loc[b, "pos_kb"]
    l0, r0 = x - arc_w / 2, x + arc_w / 2
    ax_a.add_patch(Rectangle((x_prev, -bh / 2), l0 - x_prev, bh, color=grey["ci"], lw=0))
    x_prev = r0
    c = tcol[t]
    if t == "insertion":
        ax_a.plot([l0, r0], [0, 0], color=grey["dark"], lw=0.7, zorder=1)
    else:
        w = max(length(b, 0) / 1000, 0.6)
        ax_a.add_patch(Rectangle((x - w / 2, -bh / 2), w, bh, color=c, lw=0, zorder=3))
        ax_a.plot([l0, x - w / 2], [0, 0], color=grey["dark"], lw=0.7, zorder=1)
        ax_a.plot([x + w / 2, r0], [0, 0], color=grey["dark"], lw=0.7, zorder=1)
ax_a.add_patch(Rectangle((x_prev, -bh / 2), ref_len_kb - x_prev, bh, color=grey["ci"], lw=0))
for b in bubbles:
    t, x = info.loc[b, "type"], info.loc[b, "pos_kb"]
    c = tcol[t]
    if t == "SNV":
        arc(ax_a, x, 0.9, c)
        ax_a.add_patch(Rectangle((x - 0.3, 0.9 - bh / 2), 0.6, bh, color=c, lw=0, zorder=3))
        lab = "SNV"
    elif t == "insertion":
        arc(ax_a, x, 1.3, c)
        L = length(b, 1)
        ax_a.add_patch(Rectangle((x - 0.9, 1.3 - bh / 2), 1.8, bh, color=c, lw=0, zorder=3))
        lab = f"+{kb(L)}"
    elif t == "deletion":
        arc(ax_a, x, 0.9, c)
        lab = f"−{kb(length(b, 0))}"
    else:
        arc(ax_a, x, 1.3, c)
        arc(ax_a, x, -1.1, shade(c, 0.35))
        ax_a.add_patch(Rectangle((x - 0.9, 1.3 - bh / 2), 1.8, bh, color=c, lw=0, zorder=3))
        ax_a.add_patch(Rectangle((x - 0.9, -1.1 - bh / 2), 1.8, bh, color=shade(c, 0.35), lw=0, zorder=3))
        lab = f"alt {length(b, 1) / 1000:.1f} / {kb(length(b, 2))}"
    top = 1.3 if t in ("insertion", "divergent") else 0.9
    ax_a.text(x, top + 0.3, f"{b}\n{lab}", ha="center", va="bottom", fontsize=6, linespacing=1.35)
ax_a.text(0.5, -0.45, f"Backbone = {ref_path} (reference)", ha="left", va="top", fontsize=7, color=grey["mid"])
ax_a.text(47.5, -0.45, "Arc above = alt allele 1; arc below = alt allele 2\n"
          "b: grey = reference allele, colour = alt 1, darker = alt 2",
          ha="left", va="top", fontsize=6, color=grey["mid"], linespacing=1.4)
handles = [Line2D([], [], color=tcol[t], lw=1.5, label=tname[t]) for t in tcol]
ax_a.legend(handles=handles, loc="upper right", ncol=4, fontsize=7, handlelength=1.6, columnspacing=1.0,
            borderaxespad=0.3)
ax_a.text(0.006, 0.97, f"{footnote}\nn = {n_paths} paths, {n_bub} bubbles", transform=ax_a.transAxes,
          ha="left", va="top", fontsize=6, color=grey["mid"], linespacing=1.4)
ax_a.set_ylim(-1.75, 3.55)
ax_a.set_yticks([])
ax_a.tick_params(axis="x", length=0)
house.add_house_tag(ax_a, "a")

for i, p in enumerate(path_names):
    for b in bubbles:
        t, x = info.loc[b, "type"], info.loc[b, "pos_kb"]
        a = int(A.loc[p, b])
        c = grey["light"] if a == 0 else (tcol[t] if a == 1 else shade(tcol[t], 0.35))
        ax_b.add_patch(Rectangle((x - cell_w / 2, i + 0.1), cell_w, 0.8, color=c, lw=0))
for b in bubbles:
    x = info.loc[b, "pos_kb"]
    k = int((A[b] != 0).sum())
    ax_b.text(x, n_paths + 0.25, f"{k}/{n_paths} alt", ha="center", va="top", fontsize=6)
ax_b.set_ylim(n_paths + 1.15, -0.1)
ax_b.set_yticks(np.arange(n_paths) + 0.5)
ax_b.set_yticklabels([f"{p} (ref)" if p == ref_path else p for p in path_names])
ax_b.tick_params(axis="y", length=0)
ax_b.set_xlim(-1, ref_len_kb + 1)
ax_b.set_xticks(np.arange(0, ref_len_kb + 1, 20))
ax_b.set_xlabel("Reference coordinate (kb)")
house.add_house_tag(ax_b, "b")

out = house.save_house(fig, "figure", cells=cells)
W, H = fig.get_figwidth() * 72, fig.get_figheight() * 72
for name, ax in [("a", ax_a), ("b", ax_b)]:
    bb = ax.get_position()
    print(f"AXES {name} {bb.x0 * W:.2f} {(1 - bb.y1) * H:.2f} {bb.x1 * W:.2f} {(1 - bb.y0) * H:.2f}")
print("canvas_mm", out["width_mm"], out["height_mm"], "n_paths", n_paths, "n_bubbles", n_bub)
print(A.to_string())
