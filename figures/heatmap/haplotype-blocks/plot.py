"""Haplotype block structure (house style), v4. Layout only; simulated data.
Within-group Nei haplotype diversity is printed for each block. Reads data.csv
only. The upper-left n line is 'n = {n_per} haplotypes per group' (n_per from
data.csv, as in v3). The longer n line does not fit in the v3 title-row
pocket beside B1, so a small in-frame top band is added; block titles, Hd,
strip and group names keep the same data-y as v3. Run from this directory:
python3 plot.py"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.colors import ListedColormap
from matplotlib.patches import Rectangle

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

group_order = ["Wild", "Landrace", "Cultivar"]
group_short = {"Wild": "W", "Landrace": "L", "Cultivar": "C"}
sort_block = "B3"
block_gap = 1.0
footnote = "Simulated data"
cells = "3x2"

house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
group_cols = {"Wild": hp[2], "Landrace": hp[1], "Cultivar": hp[4]}
allele_cmap = ListedColormap([grey["light"], grey["dark"]])
TEXT = "#1A1A1A"


def label_col(hex_):
    v = np.array([int(hex_[i:i + 2], 16) for i in (1, 3, 5)]) / 255
    v = np.where(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055) ** 2.4)
    return hex_ if 1.05 / (v @ [0.2126, 0.7152, 0.0722] + 0.05) >= 3 else TEXT


def nei_hd(hap_strings):
    """Nei haplotype diversity: n/(n-1) * (1 - sum p^2). n from the slice."""
    hap_strings = pd.Series(hap_strings)
    nn = int(len(hap_strings))
    if nn <= 1:
        return float("nan"), nn
    p = hap_strings.value_counts(normalize=True)
    return float(nn / (nn - 1) * (1 - (p ** 2).sum())), nn


d = pd.read_csv(Path(__file__).with_name("data.csv"))
wide = d.pivot(index="hap", columns="snp", values="allele")
snps = d.drop_duplicates("snp").sort_values("pos")
wide = wide[snps.snp]
meta = d.drop_duplicates("hap").set_index("hap")
n_hap_total = int(meta.shape[0])
blocks = list(dict.fromkeys(snps.block))
bsnps = {b: snps.snp[snps.block == b].tolist() for b in blocks}
hapstr = {b: wide[bsnps[b]].astype(str).agg("".join, axis=1) for b in blocks}
order = []
for g in group_order:
    hs = meta.index[meta.group == g]
    key = pd.DataFrame({b: hapstr[b][hs] for b in blocks})
    rank = key[sort_block].map(key[sort_block].value_counts())
    key = key.assign(_r=-rank).sort_values(["_r", sort_block] + [b for b in blocks if b != sort_block])
    order += key.index.tolist()
M = wide.loc[order].to_numpy()

xs, x = [], 0.0
for b in blocks:
    for _ in bsnps[b]:
        xs.append(x)
        x += 1
    x += block_gap
xs = np.array(xs)

fig, ax = house.house_figure(cells=cells)
for c in range(M.shape[1]):
    ax.imshow(
        M[:, [c]],
        cmap=allele_cmap,
        vmin=0,
        vmax=1,
        aspect="auto",
        interpolation="nearest",
        extent=(xs[c], xs[c] + 1, len(order), 0),
    )
# Colour strip and names stay inside the frame (xlim includes them; clip_on True).
y0 = 0
n_per_group = {}
for g in group_order:
    m = int((meta.loc[order].group == g).sum())
    n_per_group[g] = m
    ax.add_patch(Rectangle((-3.4, y0), 1.6, m, color=group_cols[g], lw=0, zorder=3))
    ax.text(-4.0, y0 + m / 2, f"{g}\nn = {m}", ha="right", va="center", fontsize=7,
            color=label_col(group_cols[g]))
    if y0 > 0:
        ax.axhline(y0, color="white", lw=1.2, zorder=4)
    y0 += m

for b in blocks:
    i0 = snps.snp.tolist().index(bsnps[b][0])
    i1 = i0 + len(bsnps[b]) - 1
    kb = (snps.pos.iloc[i1] - snps.pos.iloc[i0]) / 1e3
    bits = []
    for g in group_order:
        hd_g, _nn = nei_hd(hapstr[b][meta.group == g])
        bits.append(f"{group_short[g]} {hd_g:.2f}")
    hd_line = "  ".join(bits)
    xmid = (xs[i0] + xs[i1] + 1) / 2
    # Title 7 pt, compact within-group Hd at 6 pt so the line fits in the narrowest block (B1).
    ax.text(
        xmid, -6.85, f"{b}: {len(bsnps[b])} SNPs, {kb:.0f} kb",
        ha="center", va="top", fontsize=7, color=TEXT,
    )
    ax.text(
        xmid, -3.95, hd_line,
        ha="center", va="top", fontsize=6, color=TEXT,
    )

ax.set_xlim(-9.2, xs[-1] + 1.2)
ax.set_ylim(len(order), -14.0)
ax.set_xticks([])
ax.set_yticks([])
ax.set_xlabel("SNPs ordered by position (dark = alternative allele)")
# Footnote in an in-frame top band, above the block titles, so the longer
# n line stays inside the frame and does not collide with B1.
n_per = n_per_group[group_order[0]]
ax.text(
    -9.0, -13.5,
    f"{footnote}\nn = {n_per} haplotypes per group",
    ha="left", va="top", fontsize=6, color=grey["mid"],
)
house.save_house(fig, "figure", cells=cells)
print("wrote figure.pdf, figure.png, preview.png")
print(f"n_hap_total={n_hap_total} n_per_group={n_per_group}")
for b in blocks:
    parts = [f"{g}={nei_hd(hapstr[b][meta.group == g])[0]:.4f}" for g in group_order]
    print(b, " ".join(parts), "pooled", f"{nei_hd(hapstr[b])[0]:.4f}")
