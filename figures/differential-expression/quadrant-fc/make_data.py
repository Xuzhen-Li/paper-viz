"""Simulated log2 fold changes of 3,000 genes in two contrasts (drought vs control, heat vs control). Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(17)
n = 3000
shared = rng.normal(0, 1.0, n) * (rng.random(n) < 0.3)
a = shared + rng.normal(0, 0.55, n); b = 0.8 * shared + rng.normal(0, 0.55, n)
b[:60] = -a[:60] * rng.uniform(0.6, 1.2, 60)                     # opposite responders
pd.DataFrame({"gene": [f"g{i:04d}" for i in range(n)], "lfc_a": a.round(3), "lfc_b": b.round(3)}).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
