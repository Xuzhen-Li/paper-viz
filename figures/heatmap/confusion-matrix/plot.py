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
show_min = 0.05      # off-diagonal shares below this are left blank
# ----

df = pd.read_csv(HERE / "data.csv")
types = list(dict.fromkeys(df["true"]))
M = df.pivot(index="true", columns="predicted", values="count").loc[types, types].values.astype(float)
Rn = M / M.sum(1, keepdims=True)
acc = np.trace(M) / M.sum()
prec = np.diag(M) / M.sum(0); rec = np.diag(M) / M.sum(1); f1 = 2 * prec * rec / (prec + rec)
cmap = mpl.colors.LinearSegmentedColormap.from_list("w2b", ["#FFFFFF", "#8EBDDA", PAL[0]])
fig, ax = house.house_figure(cells="2x2")
im = ax.imshow(Rn, cmap=cmap, vmin=0, vmax=1)
for i in range(len(types)):
    for j in range(len(types)):
        v = Rn[i, j]
        if i == j or v >= show_min:
            ax.text(j, i, f"{v:.2f}".lstrip("0") if v < 1 else "1", ha="center", va="center", fontsize=6.5,
                    color="white" if v > 0.6 else "black", fontweight="bold" if i == j else "normal")
ax.set_xticks(range(len(types))); ax.set_xticklabels(types, rotation=45, ha="right")
ax.set_yticks(range(len(types))); ax.set_yticklabels([f"{t} ({int(n)})" for t, n in zip(types, M.sum(1))])
ax.set_xlabel("Predicted"); ax.set_ylabel("True (cells)")
for s in ax.spines.values():
    s.set_visible(False)
ax.tick_params(length=0)
ax.text(0.98, 0.98, f"accuracy = {acc:.2f}\nmacro F1 = {np.nanmean(f1):.2f}\nrow-normalised\nsimulated data", transform=ax.transAxes,
        ha="right", va="top", fontsize=6.5)
house.save_house(fig, HERE / "figure")
