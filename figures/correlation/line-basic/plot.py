#!/usr/bin/env python3
"""Line chart (house style, single series). Reads data.csv only. Run from this directory."""
from __future__ import annotations

import csv
import sys
from pathlib import Path

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

FOOTNOTE = "Simulated data for illustration; not biological results"

house.apply_house_style()
rows = list(csv.DictReader(open("data.csv")))
first = rows[0]["series"]  # single-series variant: the first series in data.csv
rows = [r for r in rows if r["series"] == first]
x = [float(r["x"]) for r in rows]
y = [float(r["y"]) for r in rows]
fig, ax = house.house_figure(cells="2x1")
ax.plot(x, y, color=house.pv_palette("house")[0], lw=house.LW_PT["main"])
n = len(x)
mx, my = sum(x) / n, sum(y) / n
slope = sum((a - mx) * (b - my) for a, b in zip(x, y)) / sum((a - mx) ** 2 for a in x)
ax.text(0.02, 0.96, f"Slope {slope:+.3f} per day (n = {n})", transform=ax.transAxes,
        ha="left", va="top", color=house.pv_palette("house")[0])
ax.set_xlabel("Day")
ax.set_ylabel("Relative abundance")
ax.set_xlim(min(x), max(x))
# footnote below the x-axis title, inside the canvas (an axes annotation, so the layout makes room)
ax.annotate(FOOTNOTE, xy=(0, 0), xycoords="axes fraction", xytext=(0, -24), textcoords="offset points",
            ha="left", va="top", fontsize=7, color="#6B6B6B", annotation_clip=False)
house.save_house(fig, "figure")
print("wrote preview.png")
