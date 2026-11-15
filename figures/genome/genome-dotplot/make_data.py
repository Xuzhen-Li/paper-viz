"""Simulated whole-genome alignment of two assemblies (3 chromosomes each): collinear blocks, an inversion and a translocation. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(101)
qlen = {"Q1": 42e6, "Q2": 35e6, "Q3": 28e6}; tlen = {"T1": 44e6, "T2": 33e6, "T3": 29e6}
rows = []


def block(qc, qs, qe, tc, ts, te, ident, n=30):
    edges_q = np.linspace(qs, qe, n + 1); edges_t = np.linspace(ts, te, n + 1)
    for k in range(n):
        if rng.random() < 0.15:
            continue
        rows.append((qc, int(edges_q[k]), int(edges_q[k + 1] * 0.98 + edges_q[k] * 0.02), tc, int(edges_t[k]),
                     int(edges_t[k + 1] * 0.98 + edges_t[k] * 0.02), round(float(np.clip(ident + rng.normal(0, 1.2), 75, 100)), 2)))


block("Q1", 0, 18e6, "T1", 0, 19e6, 97)
block("Q1", 18e6, 26e6, "T1", 28e6, 20e6, 95, 12)      # inversion (reverse strand)
block("Q1", 26e6, 42e6, "T1", 28e6, 44e6, 97)
block("Q2", 0, 22e6, "T2", 0, 21e6, 93, 22)
block("Q2", 22e6, 35e6, "T3", 16e6, 29e6, 90, 15)      # translocation to T3
block("Q3", 0, 16e6, "T3", 0, 15.5e6, 84, 16)
block("Q3", 16e6, 28e6, "T2", 21.5e6, 33e6, 86, 12)    # reciprocal part of the translocation
df = pd.DataFrame(rows, columns=["q_chr", "q_start", "q_end", "t_chr", "t_start", "t_end", "identity"])
df.to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
pd.DataFrame([("query", k, int(v)) for k, v in qlen.items()] + [("target", k, int(v)) for k, v in tlen.items()],
             columns=["genome", "chr", "length"]).to_csv(Path(__file__).resolve().parent / "lengths.csv", index=False)
