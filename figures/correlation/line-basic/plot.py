#!/usr/bin/env python3
"""Line chart. Reads data.csv only. Run from this directory."""
from __future__ import annotations

import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import style  # noqa: E402
from helpers import despine  # noqa: E402

style.apply_style()
rows = list(csv.DictReader(open("data.csv")))
x = [float(r["x"]) for r in rows]
y = [float(r["y"]) for r in rows]
fig, ax = plt.subplots(figsize=(3.5, 2.4))
ax.plot(x, y, color=style.ACCENT, lw=1.4)
ax.set_xlabel("Time (a.u.)")
ax.set_ylabel("Signal")
despine(ax)
fig.savefig("figure.pdf")
fig.savefig("figure.png", dpi=600)
w_in = fig.get_size_inches()[0]
fig.savefig("preview.png", dpi=1200 / w_in)
print("wrote preview.png")
