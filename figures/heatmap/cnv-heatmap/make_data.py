"""Simulated single-cell copy-number ratios: 150 cells (normal reference + two tumour subclones) x 8 chromosomes. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(131)
nb = {f"chr{i}": b for i, b in enumerate([40, 36, 32, 30, 28, 26, 24, 24], 1)}
cols = [f"{c}_{k + 1:02d}" for c, b in nb.items() for k in range(b)]
groups = [("Reference", 40), ("Tumour A", 65), ("Tumour B", 45)]
events = {"Tumour A": [("chr1", 20, 40, 0.5), ("chr3", 0, 32, -0.6), ("chr7", 0, 13, 0.45)],
          "Tumour B": [("chr1", 20, 40, 0.5), ("chr3", 0, 32, -0.6), ("chr5", 10, 28, 0.55), ("chr8", 0, 24, -0.5)]}
off = {}; o = 0
for c, b in nb.items():
    off[c] = o; o += b
rows = []; k = 0
for g, n in groups:
    for _ in range(n):
        v = rng.normal(0, 0.12, len(cols))
        for c, a, b, d in events.get(g, []):
            v[off[c] + a: off[c] + b] += d * rng.uniform(0.8, 1.1)
        v = np.convolve(v, np.ones(3) / 3, mode="same")
        k += 1
        rows.append([f"cell{k:03d}", g] + list(np.round(v, 3)))
pd.DataFrame(rows, columns=["cell", "group"] + cols).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
