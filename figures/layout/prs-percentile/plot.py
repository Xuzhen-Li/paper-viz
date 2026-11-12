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
from math import exp, log, sqrt

# ---- parameters
top = 0.05             # top share compared with the rest
n_bins = 50            # percentile bins in panel b
# ----

df = pd.read_csv(HERE / "data.csv")
fig, (a, b) = house.house_figure(cells="4x2", nrows=1, ncols=2)
xs = np.linspace(-4, 4, 300)
for k, (lab, c) in enumerate([("controls", GREY["mid"]), ("cases", PAL[3])]):
    v = df[df.case == k].prs.values; h = 1.06 * v.std() * len(v) ** -0.2
    dens = np.exp(-0.5 * ((xs[:, None] - v[None, :]) / h) ** 2).sum(1) / (len(v) * h * np.sqrt(2 * np.pi))
    a.fill_between(xs, 0, dens, color=c, alpha=0.25, lw=0); a.plot(xs, dens, color=c, lw=LW["main"])
    i = np.argmax(dens); a.text(xs[i] + (0.35 if k else -0.35), dens[i] * 1.02, f"{lab} (n = {len(v)})", color=c, fontsize=7, ha="left" if k else "right", va="bottom")
d = df.prs[df.case == 1].mean() - df.prs[df.case == 0].mean()
a.set_xlabel("Polygenic score (SD units)"); a.set_ylabel("Density"); a.set_ylim(0, 0.52)
a.text(0.03, 0.97, f"mean difference = {d:.2f} SD\nsimulated data", transform=a.transAxes, va="top", fontsize=6.5)
house.add_house_tag(a, "a")
pct = df.prs.rank(pct=True)
binned = df.assign(b=np.minimum((pct * n_bins).astype(int), n_bins - 1)).groupby("b").case.mean()
xb = (binned.index + 0.5) / n_bins * 100
hi_ = xb > (1 - top) * 100
b.scatter(xb[~hi_], binned[~hi_] * 100, color=PAL[0], **house.SCATTER)
b.scatter(xb[hi_], binned[hi_] * 100, color=PAL[3], **house.SCATTER)
is_top = pct > 1 - top
t1, t0 = df.case[is_top], df.case[~is_top]
a_, b_, c_, d_ = t1.sum(), (1 - t1).sum(), t0.sum(), (1 - t0).sum()
OR = (a_ * d_) / (b_ * c_); se = sqrt(1 / a_ + 1 / b_ + 1 / c_ + 1 / d_)
b.axvline((1 - top) * 100, color=GREY["mid"], lw=LW["ref"], ls=(0, (2, 1.5)))
b.axhline(df.case.mean() * 100, color=GREY["mid"], lw=LW["ref"])
b.text(2, df.case.mean() * 100 + 0.8, f"overall {df.case.mean() * 100:.0f}%", fontsize=6.5, color=GREY["mid"])
b.text(0.03, 0.97, f"top {top * 100:.0f}% vs rest: OR = {OR:.1f}\n95% CI {exp(log(OR) - 1.96 * se):.1f} to {exp(log(OR) + 1.96 * se):.1f} (Woolf, two-sided)",
       transform=b.transAxes, va="top", fontsize=6.5)
b.set_xlabel("Polygenic score percentile"); b.set_ylabel("Prevalence (%)"); b.set_xlim(0, 100)
house.add_house_tag(b, "b")
house.save_house(fig, HERE / "figure")
