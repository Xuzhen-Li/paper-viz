"""Simulated cell-type annotation: counts of true vs predicted labels for 8 types. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(97)
types = ["B cell", "CD4 T", "CD8 T", "NK", "Monocyte", "DC", "Platelet", "Plasma"]
size = [420, 910, 610, 330, 780, 120, 90, 60]
conf = {("CD4 T", "CD8 T"): 0.12, ("CD8 T", "CD4 T"): 0.10, ("CD8 T", "NK"): 0.08, ("NK", "CD8 T"): 0.14,
        ("DC", "Monocyte"): 0.22, ("Plasma", "B cell"): 0.30, ("Monocyte", "DC"): 0.03}
rows = []
for t, n in zip(types, size):
    p = np.full(len(types), 0.004)
    for (a, b), v in conf.items():
        if a == t:
            p[types.index(b)] = v
    p[types.index(t)] = 0
    p[types.index(t)] = max(0, 1 - p.sum())
    cnt = rng.multinomial(n, p / p.sum())
    rows += [(t, q, int(c)) for q, c in zip(types, cnt)]
pd.DataFrame(rows, columns=["true", "predicted", "count"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
