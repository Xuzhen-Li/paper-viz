"""Simulated 2-D embedding of 1,500 cells on a branching trajectory with per-cell velocity vectors. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(163)
rows = []
def arm(name, n, p0, p1, bend):
    t = rng.random(n)
    x = p0[0] + (p1[0] - p0[0]) * t; y = p0[1] + (p1[1] - p0[1]) * t + bend * np.sin(np.pi * t)
    dx = (p1[0] - p0[0]); dy = (p1[1] - p0[1]) + bend * np.pi * np.cos(np.pi * t)
    nrm = np.hypot(dx, dy)
    x = x + rng.normal(0, 0.35, n); y = y + rng.normal(0, 0.35, n)
    vx = dx / nrm + rng.normal(0, 0.35, n); vy = dy / nrm + rng.normal(0, 0.35, n)
    return [(name, a, b, c, d) for a, b, c, d in zip(x, y, vx, vy)]
rows += arm("Progenitor", 600, (-6, -1), (0, 0), 1.0)
rows += arm("Lineage A", 450, (0, 0), (6, 4), -0.8)
rows += arm("Lineage B", 450, (0, 0), (5, -5), 0.8)
df = pd.DataFrame(rows, columns=["cluster", "x", "y", "vx", "vy"]).round(4)
df.insert(0, "cell", [f"c{i + 1:04d}" for i in range(len(df))])
df.to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
