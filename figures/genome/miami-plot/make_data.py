"""Simulated GWAS summary statistics for two traits on 10 chromosomes with shared and trait-specific peaks. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(31)
rows = []
peaks = {"A": [(2, 40e6, 14), (5, 90e6, 9), (8, 30e6, 11)], "B": [(2, 40e6, 10), (7, 60e6, 12), (9, 20e6, 8)]}
for c in range(1, 11):
    L = (160 - c * 8) * 1e6
    pos = np.sort(rng.uniform(0, L, 1500))
    for t in "AB":
        p = rng.uniform(0, 1, pos.size)
        for pc, pp, h in peaks[t]:
            if pc == c:
                lp = h * np.exp(-((pos - pp) / 1.2e6) ** 2) * rng.uniform(0.6, 1.0, pos.size)
                p = np.minimum(p, 10 ** -lp)
        for x, v in zip(pos, p):
            rows.append((t, c, int(x), float(f"{v:.3g}")))
pd.DataFrame(rows, columns=["trait", "chrom", "pos", "p"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
