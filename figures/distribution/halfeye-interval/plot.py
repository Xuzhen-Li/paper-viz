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
x_label = "Effect (posterior draws)"
widths = (0.66, 0.95)       # inner and outer interval
# ----

df = pd.read_csv(HERE / "data.csv")
groups = list(dict.fromkeys(df.group))[::-1]
fig, ax = house.house_figure(cells="2x2")
xs = np.linspace(df.value.min() - 0.1, df.value.max() + 0.1, 400)
for i, g in enumerate(groups):
    v = df[df.group == g].value.values
    h = 1.06 * v.std() * len(v) ** -0.2
    dens = np.exp(-0.5 * ((xs[:, None] - v[None, :]) / h) ** 2).sum(1); dens = dens / dens.max() * 0.8
    col = PAL[1] if g == "Pooled" else PAL[0]
    ax.fill_between(xs, i, i + dens, color=col, alpha=0.35, lw=0)
    lo1, hi1 = np.quantile(v, [(1 - widths[0]) / 2, (1 + widths[0]) / 2]); lo2, hi2 = np.quantile(v, [(1 - widths[1]) / 2, (1 + widths[1]) / 2])
    ax.plot([lo2, hi2], [i, i], color="black", lw=0.8); ax.plot([lo1, hi1], [i, i], color="black", lw=2.2)
    ax.plot(np.median(v), i, "o", color=col, mec="black", mew=0.4, ms=4.5, zorder=4)
    ax.text(xs[0] + 0.03, i + 0.12, f"P(> 0) = {(v > 0).mean():.2f}", ha="left", va="bottom", fontsize=6.5)
ax.axvline(0, color=GREY["mid"], lw=LW["ref"], ls=(0, (2, 1.5)))
ax.set_yticks(range(len(groups))); ax.set_yticklabels(groups)
ax.set_ylim(-0.95, len(groups) - 0.05); ax.set_xlim(xs[0], xs[-1]); ax.set_xlabel(x_label)
ax.text(0.98, 0.015, "dot: median; bars: 66% and 95% intervals\nsimulated data", transform=ax.transAxes, ha="right", fontsize=6, color=GREY["mid"])
house.save_house(fig, HERE / "figure")
