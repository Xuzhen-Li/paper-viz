"""Haplotype x site allele matrix around a focal site (house style). Layout only; simulated
data. Reads data.csv only. Core haplotype = per-site majority allele among haplotypes carrying
the derived allele at the focal site (populations pooled). Rows are sorted within each
population by the length of the tract that spans the focal site and is identical to the core
haplotype (distance between the first and last matching site of the uninterrupted run, kb);
ties by the fraction of all sites matching the core. With polarise = True cells show whether
the allele equals the core allele; with False they show derived / ancestral.
Run from this directory: python3 plot.py"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.colors import ListedColormap
from matplotlib.patches import Rectangle

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "3x2"
focal_site = "Site 26"
pop_order = ["Pop 1", "Pop 2"]
bar_w = 9.0            # width (in site columns) of the tract-length bar strip
footnote = "Simulated data"
polarise = True       # True: same as / different from core; False: derived / ancestral

house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
pop_col = {"Pop 1": hp[0], "Pop 2": hp[1]}
allele_cmap = ListedColormap([grey["light"], grey["dark"]])
CORE = hp[3]

d = pd.read_csv(Path(__file__).with_name("data.csv"))
sites = d.drop_duplicates("site").sort_values("pos")
pos = sites.pos.to_numpy()
wide = d.pivot(index="hap", columns="site", values="allele")[sites.site]
meta = d.drop_duplicates("hap").set_index("hap")
fi = sites.site.tolist().index(focal_site)
carriers = wide.index[wide[focal_site] == 1]
core = (wide.loc[carriers].mean() >= 0.5).astype(int)
match = (wide == core).to_numpy()
ident = pd.Series(match.mean(axis=1), index=wide.index)


def tract_kb(row):
    if not row[fi]:
        return 0.0
    lo = hi = fi
    while lo > 0 and row[lo - 1]:
        lo -= 1
    while hi < len(row) - 1 and row[hi + 1]:
        hi += 1
    return (pos[hi] - pos[lo]) / 1e3


tract = pd.Series([tract_kb(r) for r in match], index=wide.index)
order, n_pop, n_car = [], {}, {}
for p in pop_order:
    hs = meta.index[meta["pop"] == p]
    n_pop[p] = int(len(hs))
    n_car[p] = int((wide.loc[hs, focal_site] == 1).sum())
    key = pd.DataFrame({"t": tract[hs], "i": ident[hs]}).sort_values(["t", "i"], ascending=False, kind="mergesort")
    order += key.index.tolist()
M = (1 - match[[wide.index.get_loc(h) for h in order]].astype(int)) if polarise else wide.loc[order].to_numpy()
nr, ns = M.shape
n_hap = int(meta.shape[0])
span_kb = (pos[-1] - pos[0]) / 1e3
tmax = float(np.ceil(span_kb / 50) * 50)

fig, ax = house.house_figure(cells=cells)
ax.imshow(M, cmap=allele_cmap, vmin=0, vmax=1, aspect="auto", interpolation="nearest", extent=(0, ns, nr, 0))
if not polarise:
    ax.imshow(core.to_numpy()[None, :], cmap=allele_cmap, vmin=0, vmax=1, aspect="auto",
              interpolation="nearest", extent=(0, ns, -1.2, -3.4))
    ax.add_patch(Rectangle((0, -3.4), ns, 2.2, fill=False, ec=CORE, lw=1.0))
    ax.text(-0.6, -2.3, "Core", ha="right", va="center", fontsize=7, color=CORE)
ax.add_patch(Rectangle((fi, -1.0), 1, nr + 1.0, fill=False, ec=CORE, lw=1.0, zorder=4))
ax.text(fi + 0.5, -1.5, f"Focal site ({focal_site})", ha="center", va="bottom", fontsize=7, color=CORE)
y0 = 0
for p in pop_order:
    m = n_pop[p]
    ax.add_patch(Rectangle((-2.2, y0), 1.4, m, color=pop_col[p], lw=0))
    ax.text(-2.8, y0 + m / 2, f"{p}\nn = {m}\n{n_car[p]} carry\nderived", ha="right", va="center",
            fontsize=7, linespacing=1.4)
    if y0 > 0:
        ax.axhline(y0, color="white", lw=1.2, zorder=3)
    y0 += m
x0 = ns + 1.0
tv = tract[order].to_numpy()
ax.barh(np.arange(nr) + 0.5, tv / tmax * bar_w, left=x0, height=0.8,
        color=[pop_col[meta.loc[h, "pop"]] for h in order], lw=0)
for v in (0, tmax / 2, tmax):
    ax.plot([x0 + v / tmax * bar_w] * 2, [0, nr], color=grey["mid"], lw=0.4, ls=(0, (2, 2)), zorder=0)
    ax.text(x0 + v / tmax * bar_w, -1.2, f"{v:g}", ha="center", va="bottom", fontsize=6)
ax.text(x0 + bar_w / 2, -4.0, "Core tract\n(kb)", ha="center", va="bottom", fontsize=7, linespacing=1.45)
kx = 6.0
keys = [("Same allele as core", grey["light"]), ("Different from core", grey["dark"])] if polarise else \
    [("Derived", grey["dark"]), ("Ancestral", grey["light"])]
for lab, c in keys:
    ax.add_patch(Rectangle((kx, -9.6), 1.0, 1.4, color=c, lw=0))
    ax.text(kx + 1.4, -8.9, lab, ha="left", va="center", fontsize=7)
    kx += 16.0
ax.text(-12.5, -11.2, f"{footnote}\nn = {n_hap} haplotypes, {ns} sites", ha="left", va="top", fontsize=6,
        color=grey["mid"], linespacing=1.45)
ax.set_xlim(-12.8, x0 + bar_w + 1.6)
ax.set_ylim(nr + 0.6, -11.6)
ax.set_xticks([])
ax.set_yticks([])
ax.set_xlabel(f"Sites ordered by position ({pos[0] / 1e3:.0f}–{pos[-1] / 1e3:.0f} kb); "
              "rows sorted by core tract length")
out = house.save_house(fig, "figure", cells=cells)
W, H = fig.get_figwidth() * 72, fig.get_figheight() * 72
bb = ax.get_position()
print(f"AXES a {bb.x0 * W:.2f} {(1 - bb.y1) * H:.2f} {bb.x1 * W:.2f} {(1 - bb.y0) * H:.2f}")
print("canvas_mm", out["width_mm"], out["height_mm"], "n_hap", n_hap, n_pop, "carriers", n_car,
      "n_carriers_total", len(carriers))
print("median tract kb among carriers", {p: float(tract[meta.index[(meta["pop"] == p)]][tract > 0].median())
                                         for p in pop_order})
