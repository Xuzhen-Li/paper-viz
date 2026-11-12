# Regional association plot (house style): -log10(P) against position for one locus, points
# coloured by r^2 with the lead SNP, a recombination-rate track and a gene track below (no second y axis).
# P: two-sided per-SNP test (here a mixed-model Wald test); significance only by the genome-wide threshold.
# Reads data.csv only (column `track` = snp / recomb / gene). Run: python3 plot.py
# v3: test note wrapped to three right-aligned lines so no line sits on SNP points (review G1).
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.lines import Line2D

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent

# Parameters ---------------------------------------------------------------------------
chrom_label = "Chr05"
gw_threshold = 5e-8                    # dashed genome-wide line (Bonferroni-type); None to hide
# v3 (G1): three right-aligned lines; the widest line is the one that already sat on empty background
test_note = "Two-sided\nmixed-model Wald test\nuncorrected P on the axis"
r2_breaks = [0, 0.2, 0.4, 0.6, 0.8, 1.0001]
r2_labels = ["< 0.2", "0.2-0.4", "0.4-0.6", "0.6-0.8", ">= 0.8"]
footnote = "Simulated data"
cells = "2x2"
R2 = "r\u00b2"
point_alpha = 0.7                      # STYLE: 200-2000 points use 0.6-0.8


def fmt_sci(p):
    """Plain-text scientific notation with ASCII hyphen-minus, values from the variable."""
    if p <= 0:
        return str(p)
    exp = int(np.floor(np.log10(p)))
    man = p / (10.0 ** exp)
    if abs(man - 1.0) < 1e-9:
        return f"10^{exp}"
    if abs(man - round(man)) < 1e-9:
        return f"{int(round(man))} x 10^{exp}"
    return f"{man:.1f} x 10^{exp}"


house.apply_house_style()
# a little more than the v1 0.51 mm left gap for the y-axis title (G-c)
plt_w_pad_mm = 2.0
import matplotlib.pyplot as plt
plt.rcParams["figure.constrained_layout.w_pad"] = plt_w_pad_mm * house.MM

grey = house.pv_palette("house_grey")
hp = house.pv_palette("house")
r2_cols = house.pv_palette("house_warm")
lead_col = hp[4]
rec_col = hp[0]
TEXT = "#1A1A1A"

d = pd.read_csv(HERE / "data.csv", keep_default_na=False, na_values=[""])
snp = d[d.track == "snp"].copy()
rec = d[d.track == "recomb"]
gen = d[d.track == "gene"]
snp["mb"] = snp.start / 1e6
snp["bin"] = np.digitize(snp.r2, r2_breaks) - 1
lead = snp.loc[snp.value.idxmax()]

fig, (ax, axr, axg) = house.house_figure(
    cells=cells, nrows=3, sharex=True,
    gridspec_kw={"height_ratios": [3.4, 0.9, 1.1]},
)
engine = fig.get_layout_engine()
if engine is not None:
    engine.set(w_pad=plt_w_pad_mm * house.MM)

axr.fill_between(rec.start / 1e6, rec.value, color=rec_col, alpha=0.20, lw=0)
axr.plot(rec.start / 1e6, rec.value, color=rec_col, lw=house.LW_PT["minor"])
axr.set_ylim(0, rec.value.max() * 1.15)
axr.set_ylabel("cM/Mb")
axr.text(0.01, 0.92, "Recombination rate", transform=axr.transAxes, ha="left", va="top", fontsize=7, color=rec_col)

for b in range(len(r2_labels)):
    s = snp[(snp.bin == b) & (snp.name != lead["name"])]
    ax.scatter(
        s.mb, s.value, c=r2_cols[b], s=house.SCATTER["s"] * 0.7,
        linewidths=house.SCATTER["linewidths"], edgecolors="black",
        alpha=point_alpha, zorder=2 + b,
    )
ax.scatter([lead.mb], [lead.value], marker="D", c=lead_col, s=26, linewidths=0.4, edgecolors="black", zorder=10)
# P of the lead from the plotted -log10 P in data.csv
lead_p = 10.0 ** (-float(lead.value))
ax.annotate(
    f"{lead['name']} (lead)\nP = {fmt_sci(lead_p)}",
    (lead.mb, lead.value), xytext=(6, -2),
    textcoords="offset points", ha="left", va="top", fontsize=7, color=lead_col,
)
if gw_threshold:
    yt = -np.log10(gw_threshold)
    ax.axhline(yt, ls=(0, (3, 2)), color=grey["ref"], lw=house.LW_PT["ref"], zorder=1)
    # G-b: label on the right-hand stretch of the threshold line, formatted from gw_threshold
    ax.text(
        float(snp.mb.max()), yt + 0.18,
        f"Genome-wide threshold\nP = {fmt_sci(gw_threshold)}",
        fontsize=7, color=grey["ref"], va="bottom", ha="right",
    )
ax.set_ylim(0, snp.value.max() * 1.18)
ax.set_ylabel("-log10 P")
handles = [Line2D([], [], ls="", marker="o", ms=4, mfc=c, mec="black", mew=0.3) for c in r2_cols]
leg = ax.legend(
    handles[::-1], r2_labels[::-1], title=f"{R2} with lead", loc="upper left", fontsize=7,
    handletextpad=0.2, labelspacing=0.25, borderaxespad=0.4, alignment="left",
)
ax.text(0.99, 0.97, f"n = {len(snp)} SNPs", transform=ax.transAxes, ha="right", va="top", fontsize=7, color=TEXT)
ax.text(0.99, 0.44, test_note, transform=ax.transAxes, ha="right", va="top", fontsize=6.5, color=grey["mid"])

for k, (_, g) in enumerate(gen.sort_values("start").iterrows()):
    y = 1.0 if k % 2 == 0 else 0.0
    x0, x1 = g.start / 1e6, g.end / 1e6
    axg.plot([x0, x1], [y, y], color=grey["dark"], lw=2.0, solid_capstyle="butt")
    tip, tail = (x1, x0) if g.strand == "+" else (x0, x1)
    axg.annotate(
        "", xy=(tip + (0.006 if g.strand == "+" else -0.006), y), xytext=(tip, y),
        arrowprops=dict(arrowstyle="-|>,head_length=0.25,head_width=0.18", color=grey["dark"], lw=0.6),
    )
    axg.text((x0 + x1) / 2, y - 0.28, g["name"], ha="center", va="top", fontsize=6.5, style="italic", color=TEXT)
axg.set_ylim(-0.95, 1.45)
axg.set_yticks([])
axg.set_xlabel(f"{chrom_label} position (Mb)")
axg.text(0.99, 0.95, footnote, transform=axg.transAxes, ha="right", va="top", fontsize=6, color=grey["mid"])
axg.set_xlim(rec.start.min() / 1e6, rec.start.max() / 1e6)
house.save_house(fig, HERE / "figure", cells=cells)
print("wrote figure.pdf, figure.png, preview.png")
