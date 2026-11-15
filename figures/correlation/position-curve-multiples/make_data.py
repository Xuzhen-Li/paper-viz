"""Simulated data for position-curve-multiples (C04). Fixed seed; writes data.csv once (open 'x').
Idea only (multi-document QA with 10, 20 and 30 total documents, answer document moved through the
context): accuracy is high when the answer document is first or last and lower in the middle. Curve
shapes and all numbers are invented; three unnamed models. One row per model x context length x
position, with the number of simulated questions and how many were answered correctly.
"""
from pathlib import Path

import numpy as np
import pandas as pd

SEED = 20261404
rng = np.random.default_rng(SEED)
N_Q = 1200                                  # simulated questions per point
TOTAL_DOCS = [10, 20, 30]
POSITIONS = {10: [1, 3, 5, 8, 10], 20: [1, 5, 10, 15, 20], 30: [1, 8, 15, 23, 30]}
#            middle, primacy gain, recency gain, extra middle loss per +10 docs
MODELS = {"Model A": (0.60, 0.14, 0.11, 0.035),
          "Model B": (0.53, 0.18, 0.07, 0.050),
          "Model C": (0.47, 0.08, 0.13, 0.025)}

rows = []
for m, (mid, prim, rec, slope) in MODELS.items():
    for k in TOTAL_DOCS:
        tau = 0.25 * (k - 1)
        for pos in POSITIONS[k]:
            p = (mid - slope * (k - 10) / 10 + prim * np.exp(-(pos - 1) / tau)
                 + rec * np.exp(-(k - pos) / tau) + rng.normal(0, 0.004))
            p = float(np.clip(p, 0.02, 0.98))
            rows.append(dict(model=m, total_docs=k, position=pos, n_questions=N_Q,
                             n_correct=int(rng.binomial(N_Q, p))))

df = pd.DataFrame(rows)
with open(Path(__file__).with_name("data.csv"), "x") as fh:
    df.to_csv(fh, index=False)
print("rows", len(df), "questions", int(df.n_questions.sum()))
