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
from helpers import despine  # noqa: E402

style.apply_style()
rng = np.random.default_rng(1)
n = 4000
lfc = rng.normal(0, 0.45, n)
tail = rng.random(n) < 0.08
lfc[tail] = rng.choice(np.array([-1.0, 1.0]), int(tail.sum())) * rng.uniform(1.2, 4.0, int(tail.sum()))
nlp = 0.9 * np.abs(lfc) ** 1.5 + rng.normal(0, 0.12, n)
nlp = np.clip(nlp, 0, 8)
pval = 10.0 ** (-nlp)
up = (lfc > 1) & (pval < 0.01)
down = (lfc < -1) & (pval < 0.01)
ns = ~(up | down)
pal = style.PALETTES["bio"]

fig, ax = plt.subplots(figsize=(3.5, 2.8))
ax.scatter(lfc[ns], nlp[ns], s=6, c=pal[5], alpha=0.45, linewidths=0)
ax.scatter(lfc[up], nlp[up], s=8, c=pal[4], alpha=0.85, linewidths=0)
ax.scatter(lfc[down], nlp[down], s=8, c=pal[3], alpha=0.85, linewidths=0)
ax.axvline(1, color=style.MUTED, ls="--", lw=0.7)
ax.axvline(-1, color=style.MUTED, ls="--", lw=0.7)
ax.axhline(-np.log10(0.01), color=style.MUTED, ls="--", lw=0.7)
ax.set_xlabel(r"$\log_2$ fold change")
ax.set_ylabel(r"$-\log_{10}(p)$")
despine(ax)
out = Path(__file__).resolve().parents[3] / "gallery" / "volcano.png"
style.save_fig(fig, out)
print(f"wrote {out}")
