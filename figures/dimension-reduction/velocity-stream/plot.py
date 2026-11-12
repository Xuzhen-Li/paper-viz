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
cols = {"Progenitor": PAL[0], "Lineage A": PAL[1], "Lineage B": PAL[2]}
bandwidth = 0.8         # Gaussian kernel width for smoothing velocities onto the grid
label_pos = {"Progenitor": (-4.2, 2.0), "Lineage A": (2.6, 4.9), "Lineage B": (7.3, -3.2)}
# ----

df = pd.read_csv(HERE / "data.csv")
fig, ax = house.house_figure(cells="2x2")
for c, col in cols.items():
    d = df[df.cluster == c]
    ax.scatter(d.x, d.y, s=3, color=col, alpha=0.45, linewidths=0)
gx = np.linspace(df.x.min(), df.x.max(), 40); gy = np.linspace(df.y.min(), df.y.max(), 40)
X, Y = np.meshgrid(gx, gy)
P = np.c_[X.ravel(), Y.ravel()]
w = np.exp(-((P[:, None, 0] - df.x.values[None]) ** 2 + (P[:, None, 1] - df.y.values[None]) ** 2) / (2 * bandwidth ** 2))
ws = w.sum(1)
U = (w @ df.vx.values / np.maximum(ws, 1e-9)).reshape(X.shape); V = (w @ df.vy.values / np.maximum(ws, 1e-9)).reshape(X.shape)
mask = (ws < 6).reshape(X.shape); U[mask] = np.nan; V[mask] = np.nan
ax.streamplot(gx, gy, U, V, color="black", linewidth=0.5, density=1.1, arrowsize=0.6)
for c, col in cols.items():
    ax.text(*label_pos[c], c, color=col, fontsize=7, ha="center",
            fontweight="bold", bbox=dict(facecolor="white", edgecolor="none", pad=0.5, alpha=0.8))
ax.set_xticks([]); ax.set_yticks([]); ax.set_xlabel("Embedding 1"); ax.set_ylabel("Embedding 2")
ax.set_aspect("equal", adjustable="datalim")
ax.text(0.02, 0.02, "streamlines: kernel-smoothed velocities\nsimulated data",
        transform=ax.transAxes, fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
