#!/usr/bin/env python3
"""PCA score scatter. Reads data.csv only. Run from this directory."""
from __future__ import annotations

import csv
import sys
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import style  # noqa: E402
from helpers import despine  # noqa: E402

style.apply_style()
rows = list(csv.DictReader(open("data.csv")))
by = defaultdict(lambda: ([], []))
order = []
for row in rows:
    g = row["group"]
    if g not in by:
        order.append(g)
    by[g][0].append(float(row["pc1"]))
    by[g][1].append(float(row["pc2"]))
colors = style.PALETTES["bio"][: len(order)]
fig, ax = plt.subplots(figsize=(3.5, 2.8))
for name, c in zip(order, colors):
    xs, ys = by[name]
    ax.scatter(xs, ys, s=12, c=c, label=name, alpha=0.85, linewidths=0)
ax.set_xlabel("PC1")
ax.set_ylabel("PC2")
ax.legend(frameon=False, markerscale=1.2)
despine(ax)
fig.savefig("figure.pdf")
fig.savefig("figure.png", dpi=600)
w_in = fig.get_size_inches()[0]
fig.savefig("preview.png", dpi=1200 / w_in)
print("wrote preview.png")
