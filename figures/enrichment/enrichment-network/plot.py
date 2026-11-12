"""Enrichment map: pathway-similarity network with cluster colouring (house style). Layout only;
simulated data. Reads data.csv only.
Universe = all genes in data.csv; list = genes with in_list = 1. Each pathway is tested with a
one-sided (over-representation) hypergeometric test; P values are BH-adjusted across all
pathways. Pathways with q < q_max are nodes; an edge joins two nodes when the Jaccard index of
their member genes is >= jaccard_min. Clusters = connected components with >= 2 nodes.
Node area ~ gene-set size; number in the node = pathway number. Single 2x2 panel: text is set at
printed size (+2 pt) here and save_house(..., bump=0). Run from this directory: python3 plot.py
v2: contrast-only change. Cluster titles set in a light swatch (< 3:1 on white) use a dark variant of
that swatch; node fills, numerals, data and wording unchanged."""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import hypergeom

_HERE = Path(__file__).resolve()
_STYLE_CANDIDATES = [
    *([_HERE.parents[3] / "styles" / "python"] if len(_HERE.parents) > 3 else []),  # repo: figures/<cat>/<slug>/
]
STYLES = next(p for p in _STYLE_CANDIDATES if (p / "house.py").is_file())
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "2x2"
q_max = 0.05
jaccard_min = 0.25
seed = 20261126        # layout seed (force-directed layout inside each cluster)
footnote = "Simulated data"
FS = {"label": 9, "small": 8, "node": 8}   # printed sizes for a single 2x2 panel (+2 pt)

house.apply_house_style(single_panel=True)
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
# v2: dark text-only variants for the two light swatches that are < 3:1 on white.
# Points, fills and edges keep the house palette; only text set in these swatches changes.
TEXT_DARK = {"#F77E12": "#B95E0E", "#62B4E7": "#437B9E"}

d = pd.read_csv(Path(__file__).with_name("data.csv"))
gl = d.drop_duplicates("gene")
M = int(len(gl))                       # universe size
N = int(gl.in_list.sum())              # list size
sets = d.groupby("pathway").gene.apply(set)
hits = d.groupby("pathway").in_list.sum()
names = sorted(sets.index, key=lambda s: int(s.split()[-1]))
K = np.array([len(sets[p]) for p in names])
k = np.array([int(hits[p]) for p in names])
pval = hypergeom.sf(k - 1, M, K, N)    # P(X >= k), one-sided
order = np.argsort(pval)
q = np.empty_like(pval)
m = len(pval)
q[order] = np.minimum.accumulate((pval[order] * m / np.arange(1, m + 1))[::-1])[::-1]
q = np.minimum(q, 1)
keep = [i for i in range(m) if q[i] < q_max]
nodes = [names[i] for i in keep]
size = {names[i]: int(K[i]) for i in keep}

edges = []
for a in range(len(nodes)):
    for b in range(a + 1, len(nodes)):
        sa, sb = sets[nodes[a]], sets[nodes[b]]
        j = len(sa & sb) / len(sa | sb)
        if j >= jaccard_min:
            edges.append((nodes[a], nodes[b], j))
# connected components
parent = {n: n for n in nodes}


def find(x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


for a, b, _ in edges:
    parent[find(a)] = find(b)
comps = {}
for n in nodes:
    comps.setdefault(find(n), []).append(n)
clusters = sorted([c for c in comps.values() if len(c) >= 2], key=lambda c: (-len(c), int(c[0].split()[-1])))
singles = sorted([c[0] for c in comps.values() if len(c) == 1], key=lambda s: int(s.split()[-1]))


def fr_layout(members, rng, iters=400):
    """Fruchterman-Reingold inside one cluster; returns positions scaled to the unit disc."""
    n = len(members)
    idx = {v: i for i, v in enumerate(members)}
    P = rng.uniform(-1, 1, (n, 2))
    W = np.zeros((n, n))
    for a, b, j in edges:
        if a in idx and b in idx:
            W[idx[a], idx[b]] = W[idx[b], idx[a]] = j
    kk = 1.0 / np.sqrt(n)
    t = 0.2
    for _ in range(iters):
        delta = P[:, None, :] - P[None, :, :]
        dist = np.linalg.norm(delta, axis=2) + 1e-9
        rep = (kk ** 2 / dist ** 2)[:, :, None] * delta
        att = (W * dist / kk)[:, :, None] * delta
        disp = (rep - att).sum(1)
        ln = np.linalg.norm(disp, axis=1)[:, None] + 1e-9
        P += disp / ln * np.minimum(ln, t)
        t *= 0.99
    P -= P.mean(0)
    r = np.linalg.norm(P, axis=1).max()
    return P / r if r > 0 else P


def diam_pt(n):
    return 12 + (n - 15) / 45 * 8     # 12-20 pt for 15-60 genes


def separate(P, R, pad, iters=400):
    """Push overlapping nodes apart (radii R, axes units) until gaps >= pad."""
    P = P.copy()
    for _ in range(iters):
        moved = False
        for i in range(len(P)):
            for j in range(i + 1, len(P)):
                v = P[j] - P[i]
                dd = np.hypot(*v) + 1e-9
                need = R[i] + R[j] + pad
                if dd < need:
                    s = (need - dd) / 2 * v / dd
                    P[i] -= s
                    P[j] += s
                    moved = True
        if not moved:
            break
    return P - P.mean(0)


fig, ax = house.house_figure(cells=cells)
ax.set_xlim(0, 1)
ax.set_ylim(0, 1)
fig.canvas.draw()
ax_pt = ax.get_window_extent().width * 72 / fig.dpi   # axes width in pt (square axes)
rng = np.random.default_rng(seed)
pos = {}
ncol = 2
label_h, row_gap, y_cursor = 0.05, 0.025, 0.975   # clusters stacked in rows from the top
cw = 1.0 / ncol
local, ext = [], []
for c in clusters:
    R = np.array([diam_pt(size[v]) / 2 / ax_pt for v in c])
    P = separate(fr_layout(c, rng) * 0.06, R, pad=2.0 / ax_pt)
    local.append(P)
    ext.append(((P[:, 0] - R).min(), (P[:, 0] + R).max(), (P[:, 1] - R).min(), (P[:, 1] + R).max()))
centres, label_y = [], []
for r0 in range(0, len(clusters), ncol):
    row = range(r0, min(r0 + ncol, len(clusters)))
    row_h = max(ext[i][3] - ext[i][2] for i in row)
    for i in row:
        x0, x1, y0, y1 = ext[i]
        cx = cw * (i % ncol + 0.5) - (x0 + x1) / 2
        cy = y_cursor - label_h - y1
        for v, (x, y) in zip(clusters[i], local[i]):
            pos[v] = (cx + x, cy + y)
        centres.append((cw * (i % ncol + 0.5), cy))
        label_y.append(y_cursor - label_h)
    y_cursor -= label_h + row_h + row_gap
ys = y_cursor - 0.045
for i, v in enumerate(singles):
    pos[v] = (0.36 + 0.085 * i, ys)
print("cluster extents (axes units)", [tuple(round(float(e), 3) for e in x) for x in ext], "singles_y", round(ys, 3))
ccol = {}
for i, c in enumerate(clusters):
    for v in c:
        ccol[v] = hp[i] if i < 6 else grey["ci"]
for v in singles:
    ccol[v] = grey["ci"]
for a, b, j in edges:
    (x1, y1), (x2, y2) = pos[a], pos[b]
    ax.plot([x1, x2], [y1, y2], color=grey["mid"], lw=0.4 + 3.0 * (j - jaccard_min), zorder=1,
            solid_capstyle="round")


for v in nodes:
    x, y = pos[v]
    ax.scatter([x], [y], s=diam_pt(size[v]) ** 2, color=ccol[v], edgecolors="#000000", linewidths=0.43,
               zorder=3)
    ax.text(x, y, v.split()[-1], ha="center", va="center", fontsize=FS["node"],
            color="white" if ccol[v] in (hp[0], hp[3], hp[4]) else "#000000", zorder=4)
for i, (c, (cx, cy)) in enumerate(zip(clusters, centres)):
    ax.text(cx, label_y[i] + 0.008, f"Cluster {i + 1} ({len(c)} pathways)", ha="center", va="bottom",
            fontsize=FS["label"], color=TEXT_DARK.get(hp[i].upper(), hp[i]) if i < 6 else "#000000")
if singles:
    ax.text(0.03, ys, "Unclustered", ha="left", va="center", fontsize=FS["label"], color=grey["mid"])
# size key, bottom right
for j, n_ in enumerate([20, 40, 60]):
    x = 0.79 + 0.08 * j
    ax.scatter([x], [0.075], s=diam_pt(n_) ** 2, color="white", edgecolors="#000000", linewidths=0.43)
    ax.text(x, 0.075, f"{n_}", ha="center", va="center", fontsize=FS["node"])
ax.text(0.985, 0.075 + 0.06, "Genes per pathway", ha="right", va="bottom", fontsize=FS["small"])
ax.text(0.02, 0.015,
        f"{footnote}\n{len(nodes)} of {m} pathways with BH q < {q_max:g}\n"
        f"(one-sided hypergeometric test; N = {M:,} genes)\nEdge: Jaccard ≥ {jaccard_min:g}",
        ha="left", va="bottom", fontsize=FS["small"], color=grey["mid"], linespacing=1.35)
ax.set_xlim(0, 1)
ax.set_ylim(0, 1)
ax.set_xticks([])
ax.set_yticks([])
out = house.save_house(fig, "figure", cells=cells, bump=0)
W, H = fig.get_figwidth() * 72, fig.get_figheight() * 72
bb = ax.get_position()
print(f"AXES a {bb.x0 * W:.2f} {(1 - bb.y1) * H:.2f} {bb.x1 * W:.2f} {(1 - bb.y0) * H:.2f}")
print("canvas_mm", out["width_mm"], out["height_mm"], "bump", out["bump"], "universe", M, "list", N,
      "tested", m, "kept", len(nodes), "edges", len(edges))
print("clusters", [len(c) for c in clusters], "singles", singles)
for i in np.argsort(q):
    print(names[i], int(K[i]), int(k[i]), f"p={pval[i]:.3g}", f"q={q[i]:.3g}")
