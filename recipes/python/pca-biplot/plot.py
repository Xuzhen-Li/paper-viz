#!/usr/bin/env python3
"""pca-biplot starter — synthetic 2D embedding."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import style  # noqa: E402
from helpers import add_panel_tag, despine  # noqa: E402

style.apply_style()
rng = np.random.default_rng(2)
groups = {
    "Pop1": rng.normal([-1, 0], 0.35, size=(40, 2)),
    "Pop2": rng.normal([1, 0.2], 0.4, size=(40, 2)),
    "Pop3": rng.normal([0, 1.2], 0.3, size=(30, 2)),
}
colors = style.PALETTES["bio"][:3]

fig, ax = plt.subplots(figsize=(3.5, 2.8))
for (name, pts), c in zip(groups.items(), colors):
    ax.scatter(pts[:, 0], pts[:, 1], s=12, c=c, label=name, alpha=0.85, linewidths=0)
ax.set_xlabel("PC1")
ax.set_ylabel("PC2")
ax.legend(frameon=False, markerscale=1.2)
despine(ax)
add_panel_tag(ax, "d")
out = Path(__file__).resolve().parents[3] / "gallery" / "pca-biplot.png"
style.save_fig(fig, out)
print(f"wrote {out}")
