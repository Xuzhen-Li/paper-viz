"""Simulated posterior draws (1,000 each) for six group effects. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(149)
groups = {"Site A": (0.42, 0.12), "Site B": (0.30, 0.18), "Site C": (0.05, 0.10), "Site D": (0.22, 0.25),
          "Site E": (-0.12, 0.14), "Pooled": (0.18, 0.06)}
rows = []
for g, (m, s) in groups.items():
    d = m + s * rng.standard_t(8, 1000)
    rows += [(g, i + 1, round(float(v), 4)) for i, v in enumerate(d)]
pd.DataFrame(rows, columns=["group", "draw", "value"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
