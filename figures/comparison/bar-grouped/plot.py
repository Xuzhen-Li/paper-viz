#!/usr/bin/env python3
"""Grouped bars. Reads data.csv only. Run from this directory."""
from __future__ import annotations

import csv
import sys
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import style  # noqa: E402
from helpers import despine  # noqa: E402

style.apply_style()

rows = list(csv.DictReader(open("data.csv")))
groups = []
for row in rows:
    if row["group"] not in groups:
        groups.append(row["group"])
series = []
for row in rows:
    if row["series"] not in series:
        series.append(row["series"])
vals = defaultdict(dict)
for row in rows:
    vals[row["series"]][row["group"]] = float(row["value"])

x = np.arange(len(groups))
w = 0.8 / max(len(series), 1)
pal = style.PALETTES["bio"]
fig, ax = plt.subplots(figsize=(3.5, 2.4))
for i, name in enumerate(series):
    heights = [vals[name][g] for g in groups]
    ax.bar(x + (i - (len(series) - 1) / 2) * w, heights, w, label=name, color=pal[1 + i])
ax.set_xticks(x, groups)
ax.set_ylabel("Value")
ax.legend(frameon=False, loc="upper left", bbox_to_anchor=(1.02, 1), borderaxespad=0)
despine(ax)
fig.savefig("figure.pdf")
fig.savefig("figure.png", dpi=600)
w_in = fig.get_size_inches()[0]
fig.savefig("preview.png", dpi=1200 / w_in)
print("wrote preview.png")
