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
cmap = house.house_cmap("house_div")
# ----

df = pd.read_csv(HERE / "data.csv")
mods = list(dict.fromkeys(df.module)); traits = list(dict.fromkeys(df.trait))
R = df.pivot(index="module", columns="trait", values="r").loc[mods, traits].values
P = df.pivot(index="module", columns="trait", values="p").loc[mods, traits].values
size = df.drop_duplicates("module").set_index("module").module_size.loc[mods].values
fig, ax = house.house_figure(cells="2x2")
im = ax.imshow(R, cmap=cmap, vmin=-1, vmax=1, aspect="auto")
for i in range(len(mods)):
    for j in range(len(traits)):
        ptxt = f"{P[i, j]:.0e}".replace("e-0", "e-") if P[i, j] < 0.001 else f"{P[i, j]:.2f}"
        ax.text(j, i, f"{R[i, j]:.2f}\n({ptxt})", ha="center", va="center", fontsize=6,
                color="white" if abs(R[i, j]) > 0.6 else "black", linespacing=0.95)
ax.set_xticks(range(len(traits))); ax.set_xticklabels(traits, rotation=40, ha="right")
ax.set_yticks(range(len(mods))); ax.set_yticklabels([f"{m[2:]} ({s})" for m, s in zip(mods, size)])
for s in ax.spines.values():
    s.set_visible(False)
ax.tick_params(length=0)
cax = ax.inset_axes([1.03, 0.25, 0.04, 0.5])
cb = fig.colorbar(im, cax=cax, ticks=[-1, 0, 1]); cb.outline.set_linewidth(0.4)
cax.set_title("r", fontsize=6.5, pad=2)
fig.supxlabel(f"Simulated data; Pearson r (P, two-sided t test, n = {df.n.iloc[0]}), no correction", fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
