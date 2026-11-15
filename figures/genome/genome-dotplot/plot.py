import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[2] / "styles" / "python"))
import house  # noqa: E402

house.apply_house_style()
PAL = house.pv_palette("house")
GREY = house.pv_palette("house_grey")
LW = house.LW_PT

# ---- parameters
bins = [(0, 85, "< 85%", house.pv_palette("house_warm")[0]), (85, 92, "85-92%", house.pv_palette("house_warm")[2]),
        (92, 101, ">= 92%", house.pv_palette("house_warm")[4])]
# ----

df = pd.read_csv(HERE / "data.csv"); L = pd.read_csv(HERE / "lengths.csv")
off = {}
for g in ("query", "target"):
    d = L[L.genome == g]; o = np.r_[0, np.cumsum(d.length.values)[:-1]]
    off.update(dict(zip(d.chr, o))); off[g + "_end"] = d.length.sum()
fig, ax = house.house_figure(cells="2x2")
for lo_, hi_, lab, c in bins:
    s = df[(df.identity >= lo_) & (df.identity < hi_)]
    for _, r in s.iterrows():
        ax.plot([(off[r.t_chr] + r.t_start) / 1e6, (off[r.t_chr] + r.t_end) / 1e6], [(off[r.q_chr] + r.q_start) / 1e6, (off[r.q_chr] + r.q_end) / 1e6],
                color=c, lw=1.6, solid_capstyle="butt")
    ax.plot([], [], color=c, lw=2, label=lab)
for g, setline in (("target", ax.axvline), ("query", ax.axhline)):
    d = L[L.genome == g]
    for ch in d.chr.values[1:]:
        setline(off[ch] / 1e6, color=GREY["light"], lw=LW["ref"], zorder=0)
ax.set_xlim(0, off["target_end"] / 1e6); ax.set_ylim(0, off["query_end"] / 1e6)
tq = L[L.genome == "target"]; qq = L[L.genome == "query"]
ax.set_xticks([(off[c] + n / 2) / 1e6 for c, n in zip(tq.chr, tq.length)]); ax.set_xticklabels(tq.chr)
ax.set_yticks([(off[c] + n / 2) / 1e6 for c, n in zip(qq.chr, qq.length)]); ax.set_yticklabels(qq.chr)
ax.tick_params(length=0)
ax.set_xlabel("Target assembly (chromosomes)"); ax.set_ylabel("Query assembly (chromosomes)")
ax.annotate("inversion", (24, 22), xytext=(6, 33), fontsize=6.5, arrowprops=dict(arrowstyle="-", lw=0.5, color="black"))
ax.annotate("translocation", (off["T3"] / 1e6 + 22.5, off["Q2"] / 1e6 + 28.5), xytext=(86, 50), fontsize=6.5, ha="center",
            arrowprops=dict(arrowstyle="-", lw=0.5, color="black"))
ax.legend(title="identity", loc="lower right", fontsize=6.5, title_fontsize=6.5, frameon=True, framealpha=1, edgecolor="none")
ax.text(0.02, 0.98, "simulated data", transform=ax.transAxes, fontsize=6, color=GREY["mid"], va="top")
house.save_house(fig, HERE / "figure")
