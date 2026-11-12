# Gene family expansion / contraction on a dated species tree (house style): each branch carries
# +expanded / -contracted family counts (green / red), and a side panel gives the families with
# significantly rapid change per species.
# Right: rapid families, family-wide P under the birth-death model, BH q < 0.05
# as diverging bars. Reads data.csv only. Run: python3 plot.py
import sys
from pathlib import Path

import numpy as np
import pandas as pd

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent

# Parameters ---------------------------------------------------------------------------
time_ticks = [120, 90, 60, 30, 0]      # Mya
name_pad = 3                           # Mya between tip and its name
tip_space = 42                         # Mya of room right of the tips for names
footnote = "Simulated data"
rapid_note = "Right: rapid families, family-wide P under the birth-death model, BH q < 0.05"
cells = "3x2"

house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
c_exp, c_con = hp[2], hp[3]
TEXT = "#1A1A1A"

d = pd.read_csv(HERE / "data.csv", keep_default_na=False)
d = d.set_index("node")
children = {n: d.index[d.parent == n].tolist() for n in d.index}
root = d.index[d.parent == ""][0]
tips, ypos = [], {}


def walk(n):
    if not children[n]:
        ypos[n] = len(tips)
        tips.append(n)
    else:
        for c in children[n]:
            walk(c)
        ypos[n] = np.mean([ypos[c] for c in children[n]])


walk(root)

fig, (ax, bx) = house.house_figure(cells=cells, ncols=2, sharey=True, gridspec_kw={"width_ratios": [2.6, 1]})
lw = house.LW_PT["minor"]
for n in d.index:
    x1 = d.age[n]
    if children[n]:
        ys = [ypos[c] for c in children[n]]
        ax.plot([x1, x1], [min(ys), max(ys)], color="black", lw=lw, solid_capstyle="butt")
    if d.parent[n]:
        x0 = d.age[d.parent[n]]
        ax.plot([x0, x1], [ypos[n], ypos[n]], color="black", lw=lw, solid_capstyle="butt")
        xm = (x0 + x1) / 2
        kw = dict(textcoords="offset points", va="bottom", fontsize=6.5)
        ax.annotate("/", (xm, ypos[n]), xytext=(0, 1), ha="center", color=grey["mid"], **kw)
        ax.annotate(f"+{d.expanded[n]}", (xm, ypos[n]), xytext=(-2, 1), ha="right", color=c_exp, **kw)
        ax.annotate(f"-{d.contracted[n]}", (xm, ypos[n]), xytext=(2, 1), ha="left", color=c_con, **kw)
    else:
        ax.plot([x1 + 6, x1], [ypos[n], ypos[n]], color="black", lw=lw)
for t in tips:
    ax.text(-name_pad, ypos[t], t, ha="left", va="center", fontsize=7, style="italic", color=TEXT)
ax.set_xlim(d.age[root] + 8, -tip_space)
ax.set_xticks(time_ticks)
ax.set_xlabel("Time (Mya)")
ax.set_ylim(len(tips) - 0.4, -1.75)
ax.set_yticks([])
ax.text(0.02, 0.985, "+expanded", transform=ax.transAxes, ha="left", va="top", fontsize=7, color=c_exp)
ax.text(0.02 + 0.155, 0.985, "/", transform=ax.transAxes, ha="left", va="top", fontsize=7, color=grey["mid"])
ax.text(0.02, 0.935, rapid_note, transform=ax.transAxes, ha="left", va="top", fontsize=6.5, color=grey["mid"])
ax.text(0.02 + 0.175, 0.985, "-contracted families per branch", transform=ax.transAxes, ha="left", va="top",
        fontsize=7, color=c_con)

y = np.array([ypos[t] for t in tips])
re = d.loc[tips, "rapid_expanded"].astype(int).to_numpy()
rc = d.loc[tips, "rapid_contracted"].astype(int).to_numpy()
bx.barh(y, re, height=0.6, color=c_exp, lw=0)
bx.barh(y, -rc, height=0.6, color=c_con, lw=0)
bx.axvline(0, color="black", lw=house.LW_PT["frame"])
m = max(re.max(), rc.max()) * 1.45
for yi, a_, b_ in zip(y, re, rc):
    bx.text(a_ + m * 0.03, yi, str(a_), ha="left", va="center", fontsize=6.5, color=c_exp)
    bx.text(-b_ - m * 0.03, yi, str(b_), ha="right", va="center", fontsize=6.5, color=c_con)
bx.set_xlim(-m, m)
tk = np.array(sorted(set([-int(m * 0.6 // 10 * 10), 0, int(m * 0.6 // 10 * 10)])))
bx.set_xticks(tk)
bx.set_xticklabels([str(abs(v)) for v in tk])
bx.set_xlabel("Rapid families (q < 0.05)")
ax.text(0.02, 0.02, footnote, transform=ax.transAxes, ha="left", va="bottom", fontsize=6, color=grey["mid"])
house.save_house(fig, HERE / "figure", cells=cells)
print("wrote figure.pdf, figure.png, preview.png")
