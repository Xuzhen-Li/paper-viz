"""Simulated ancient-DNA allele counts at three loci in 12 time bins (years before present). Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(127)
t = np.arange(10500, -1, -900)           # bin centres, years BP
loci = {"LCT-like": (0.035, 4200), "SLC-like": (0.018, 7500), "Neutral": (0.0, 0)}
rows = []
for name, (s, t0) in loci.items():
    if s > 0:
        p = 1 / (1 + np.exp(-s * (t0 - t) / 29))            # generations of 29 years
    else:
        p = np.clip(0.3 + np.cumsum(rng.normal(0, 0.02, t.size)), 0.05, 0.95)
    n = rng.integers(16, 90, t.size)
    k = rng.binomial(n, np.clip(p, 0.002, 0.998))
    rows += [(name, int(a), int(b), int(c)) for a, b, c in zip(t, n, k)]
pd.DataFrame(rows, columns=["locus", "years_bp", "n_chrom", "n_derived"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
