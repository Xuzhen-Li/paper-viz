"""Simulated cell-level measurements: 3 conditions x 3 biological replicates x 30-45 cells. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(8)
rows = []
for cond, mu in (("Control", 20.0), ("Drug A", 24.0), ("Drug B", 21.5)):
    for rep in (1, 2, 3):
        rmu = mu + rng.normal(0, 1.5)
        for v in rng.gamma(9, rmu / 9, rng.integers(30, 46)):
            rows.append((cond, rep, round(v, 3)))
pd.DataFrame(rows, columns=["condition", "replicate", "speed"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
