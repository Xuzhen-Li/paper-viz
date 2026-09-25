#!/usr/bin/env python3
"""line-basic starter — uses visualization/py style."""
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
rng = np.random.default_rng(0)
x = np.linspace(0, 10, 80)
y = np.sin(x) + rng.normal(0, 0.08, size=x.shape)

fig, ax = plt.subplots(figsize=(3.5, 2.4))
ax.plot(x, y, color=style.ACCENT, lw=1.4)
ax.set_xlabel("Time (a.u.)")
ax.set_ylabel("Signal")
despine(ax)
out = Path(__file__).resolve().parents[3] / "gallery" / "line-basic.png"
style.save_fig(fig, out)
print(f"wrote {out}")
