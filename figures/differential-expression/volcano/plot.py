#!/usr/bin/env python3
"""Optional Python volcano (house style). Reads the same data.csv. Does not replace preview.png."""
from __future__ import annotations

import csv
import sys
from pathlib import Path

import numpy as np

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

FOOTNOTE = "Simulated data;\nnot biological results"

house.apply_house_style()
lfc_cut = 1.0
p_cut = 0.01
rows = list(csv.DictReader(open("data.csv")))
lfc = np.array([float(r["log2_fold_change"]) for r in rows])
pval = np.array([float(r["pvalue"]) for r in rows])
nlp = -np.log10(pval)
up = (lfc >= lfc_cut) & (pval < p_cut)
down = (lfc <= -lfc_cut) & (pval < p_cut)
ns = ~(up | down)
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
red, blue = hp[3], hp[0]
fig, ax = house.house_figure(cells="1x1")
ref = dict(color=grey["ref"], ls="--", lw=house.LW_PT["ref"], zorder=1)
ax.axvline(lfc_cut, **ref)
ax.axvline(-lfc_cut, **ref)
ax.axhline(-np.log10(p_cut), **ref)
ax.scatter(lfc[ns], nlp[ns], s=2.5, c=grey["light"], linewidths=0, zorder=2)
ax.scatter(lfc[up], nlp[up], s=2.5, c=red, linewidths=0, zorder=3)
ax.scatter(lfc[down], nlp[down], s=2.5, c=blue, linewidths=0, zorder=3)
ax.set_ylim(0, nlp.max() * 1.15)
ax.text(0.03, 0.97, f"Down {int(down.sum())}", transform=ax.transAxes, ha="left", va="top", color=blue)
ax.text(0.97, 0.97, f"Up {int(up.sum())}", transform=ax.transAxes, ha="right", va="top", color=red)
ax.set_xlabel("log2 fold change")
ax.set_ylabel("-log10(p)")
ax.annotate(FOOTNOTE, xy=(0, 0), xycoords="axes fraction", xytext=(-18, -20), textcoords="offset points",
            ha="left", va="top", fontsize=7, color=grey["mid"], annotation_clip=False)
house.save_house(fig, "figure-python", preview=False)
w_in = fig.get_size_inches()[0]
fig.savefig("preview-python.png", dpi=1200 / w_in, facecolor="white")
print("wrote preview-python.png")
