#!/usr/bin/env python3
"""Optional Python volcano. Reads the same data.csv. Does not replace preview.png."""
from __future__ import annotations

import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import style  # noqa: E402
from helpers import despine  # noqa: E402

style.apply_style()
lfc_cut = 1.0
p_cut = 0.01
rows = list(csv.DictReader(open("data.csv")))
lfc = np.array([float(r["log2_fold_change"]) for r in rows])
pval = np.array([float(r["pvalue"]) for r in rows])
nlp = -np.log10(pval)
up = (lfc > lfc_cut) & (pval < p_cut)
down = (lfc < -lfc_cut) & (pval < p_cut)
ns = ~(up | down)
pal = style.PALETTES["bio"]
fig, ax = plt.subplots(figsize=(3.5, 2.8))
ax.scatter(lfc[ns], nlp[ns], s=6, c=pal[5], alpha=0.45, linewidths=0)
ax.scatter(lfc[up], nlp[up], s=8, c=pal[4], alpha=0.85, linewidths=0)
ax.scatter(lfc[down], nlp[down], s=8, c=pal[3], alpha=0.85, linewidths=0)
ax.axvline(lfc_cut, color=style.MUTED, ls="--", lw=0.7)
ax.axvline(-lfc_cut, color=style.MUTED, ls="--", lw=0.7)
ax.axhline(-np.log10(p_cut), color=style.MUTED, ls="--", lw=0.7)
ax.set_xlabel("log2 fold change")
ax.set_ylabel("-log10(p)")
despine(ax)
fig.savefig("figure-python.pdf")
fig.savefig("figure-python.png", dpi=600)
w_in = fig.get_size_inches()[0]
fig.savefig("preview-python.png", dpi=1200 / w_in)
print("wrote preview-python.png")
