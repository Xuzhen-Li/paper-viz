#!/usr/bin/env python3
"""volcano starter — synthetic DE table."""
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
rng = np.random.default_rng(1)
n = 2000
lfc = rng.normal(0, 1.2, n)
pval = 10 ** (-rng.uniform(0.1, 8, n))
sig = (np.abs(lfc) > 1) & (pval < 0.01)

fig, ax = plt.subplots(figsize=(3.5, 2.8))
ax.scatter(lfc[~sig], -np.log10(pval[~sig]), s=6, c=style.MUTED, alpha=0.5, linewidths=0)
ax.scatter(lfc[sig], -np.log10(pval[sig]), s=8, c=style.PALETTES["bio"][4], alpha=0.7, linewidths=0)
ax.axvline(1, color=style.MUTED, ls="--", lw=0.7)
ax.axvline(-1, color=style.MUTED, ls="--", lw=0.7)
ax.axhline(-np.log10(0.01), color=style.MUTED, ls="--", lw=0.7)
ax.set_xlabel(r"$\log_2$ fold change")
ax.set_ylabel(r"$-\log_{10}(p)$")
despine(ax)
add_panel_tag(ax, "c")
out = Path(__file__).resolve().parents[3] / "gallery" / "volcano.png"
style.save_fig(fig, out)
print(f"wrote {out}")
