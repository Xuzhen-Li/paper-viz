#!/usr/bin/env python3
"""bar-grouped starter."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import style  # noqa: E402
from helpers import despine  # noqa: E402

style.apply_style()
groups = ["A", "B", "C", "D"]
x = np.arange(len(groups))
w = 0.35
ctrl = np.array([3.1, 2.4, 4.0, 2.9])
trt = np.array([4.2, 3.5, 4.8, 3.7])

fig, ax = plt.subplots(figsize=(3.5, 2.4))
ax.bar(x - w / 2, ctrl, w, label="Control", color=style.PALETTES["bio"][1])
ax.bar(x + w / 2, trt, w, label="Treatment", color=style.PALETTES["bio"][2])
ax.set_xticks(x, groups)
ax.set_ylabel("Value")
ax.legend(frameon=False, loc="upper left", bbox_to_anchor=(1.02, 1), borderaxespad=0)
despine(ax)
out = Path(__file__).resolve().parents[3] / "gallery" / "bar-grouped.png"
style.save_fig(fig, out)
print(f"wrote {out}")
