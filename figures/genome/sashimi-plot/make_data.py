"""Simulated RNA-seq of one cassette exon in two conditions: binned coverage and junction read counts. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(71)
exons = [(1000, 1300), (2100, 2250), (3200, 3600)]
rows = []
for cond, depth, incl in (("Control", 60, 0.8), ("Knockdown", 55, 0.3)):
    for k, (s, e) in enumerate(exons):
        lvl = depth * (incl if k == 1 else 1)
        for b in range(s, e, 10):
            edge = min(b - s, e - b) / 40
            cov = lvl * min(1, 0.35 + edge) * rng.lognormal(0, 0.08)
            rows.append((cond, "coverage", b, b + 10, round(cov, 1)))
    j_in = int(rng.poisson(depth * incl * 0.9)); j_out = int(rng.poisson(depth * incl * 0.85))
    j_skip = int(rng.poisson(depth * (1 - incl) * 0.9))
    rows += [(cond, "junction", 1300, 2100, j_in), (cond, "junction", 2250, 3200, j_out), (cond, "junction", 1300, 3200, j_skip)]
for k, (s, e) in enumerate(exons):
    rows.append(("gene", "exon", s, e, k + 1))
pd.DataFrame(rows, columns=["condition", "type", "start", "end", "value"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
