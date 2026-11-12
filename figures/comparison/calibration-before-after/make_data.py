"""Simulated 10-class classifier logits for the calibration-before-after figure.
One row per example: split (val = held-out set used only to fit the temperature, test = set
shown in the reliability diagrams), true label and the 10 raw logits. The logits are scaled up
so the raw softmax is over-confident. Classes are numbered, not named. Fixed seed; writes
data.csv once (refuses to overwrite). Run: python3 make_data.py"""
import csv

import numpy as np

SEED = 71060
K = 10              # classes
N = {"val": 2000, "test": 5000}
MU = 2.0            # mean logit advantage of the true class (sets accuracy)
SCALE = 2.6         # logit inflation -> over-confidence
rng = np.random.default_rng(SEED)

rows = []
for split, n in N.items():
    y = rng.integers(0, K, size=n)
    # per-example difficulty: some examples are much harder than others
    hard = rng.gamma(4.0, 0.25, size=n)
    z = rng.normal(0, 1, size=(n, K))
    z[np.arange(n), y] += MU / hard
    z *= SCALE
    for i in range(n):
        row = {"split": split, "example": f"{split}{i:05d}", "label": int(y[i])}
        row.update({f"logit_{k}": round(float(z[i, k]), 3) for k in range(K)})
        rows.append(row)

with open("data.csv", "x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0]))
    w.writeheader()
    w.writerows(rows)
print(f"wrote data.csv: {len(rows)} rows, seed {SEED}")
