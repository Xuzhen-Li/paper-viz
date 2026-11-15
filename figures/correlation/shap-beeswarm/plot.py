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
import matplotlib as mpl

# ---- parameters
row_height = 0.36       # half-height of each swarm row
# ----

df = pd.read_csv(HERE / "data.csv")
imp = df.assign(a=df.shap.abs()).groupby("feature").a.mean().sort_values()
cmap = mpl.colors.LinearSegmentedColormap.from_list("lohi", [PAL[0], "#DDDDDD", PAL[3]])


def swarm(v, width):
    """Offset points that fall in the same x bin, alternating up and down."""
    edges = np.linspace(v.min(), v.max(), 60)
    b = np.digitize(v, edges); y = np.zeros_like(v)
    for k in np.unique(b):
        idx = np.where(b == k)[0]
        off = np.array([(i + 1) // 2 * (1 if i % 2 else -1) for i in range(len(idx))], float)
        y[idx] = off
    m = np.abs(y).max() or 1
    return y / m * width


fig, ax = house.house_figure(cells="2x2")
for r, f in enumerate(imp.index):
    d = df[df.feature == f]
    y = r + swarm(d.shap.values, row_height)
    ax.scatter(d.shap, y, c=d.value, cmap=cmap, vmin=0, vmax=1, s=4, linewidths=0, zorder=3)
ax.axvline(0, color=GREY["mid"], lw=LW["ref"])
ax.set_yticks(range(len(imp))); ax.set_yticklabels([f"{f} ({v:.2f})" for f, v in imp.items()])
ax.set_xlabel("SHAP value"); ax.set_ylabel("Feature (mean |SHAP|)")
ax.set_ylim(-0.7, len(imp) - 0.3)
sm = mpl.cm.ScalarMappable(cmap=cmap, norm=mpl.colors.Normalize(0, 1))
cax = ax.inset_axes([0.73, 0.06, 0.22, 0.03])
cb = fig.colorbar(sm, cax=cax, orientation="horizontal", ticks=[0, 1]); cb.outline.set_linewidth(0.4)
cb.ax.set_xticklabels(["low", "high"]); cb.ax.tick_params(labelsize=6, length=1.5)
cax.set_title("feature value", fontsize=6, pad=1.5)
ax.text(0.97, 0.20, "simulated data", transform=ax.transAxes, ha="right", va="bottom", fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
