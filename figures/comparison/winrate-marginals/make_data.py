"""Simulated pairwise battles for the winrate-marginals figure.
One row per battle: two anonymous models and the outcome (model_a, model_b or tie). Model
strengths follow a Bradley-Terry model; some pairs are sampled far more often than others, as
in crowd-sourced arenas. Labels are generic (Model A ... Model H). Fixed seed; writes data.csv
once (refuses to overwrite). Run: python3 make_data.py"""
import csv
import itertools

import numpy as np

SEED = 71070
N_BATTLES = 9000
TIE_RATE = 0.12
rng = np.random.default_rng(SEED)

models = [f"Model {c}" for c in "ABCDEFGH"]
strength = dict(zip(models, rng.normal(0, 0.7, size=len(models))))
pairs = list(itertools.combinations(models, 2))
weight = rng.gamma(1.2, 1.0, size=len(pairs))          # uneven sampling of pairs
weight /= weight.sum()

rows = []
for b in range(N_BATTLES):
    i, j = pairs[rng.choice(len(pairs), p=weight)]
    if rng.random() < 0.5:                              # random left/right position
        i, j = j, i
    if rng.random() < TIE_RATE:
        winner = "tie"
    else:
        p = 1 / (1 + np.exp(-(strength[i] - strength[j])))
        winner = "model_a" if rng.random() < p else "model_b"
    rows.append({"battle": b + 1, "model_a": i, "model_b": j, "winner": winner})

with open("data.csv", "x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0]))
    w.writeheader()
    w.writerows(rows)
print(f"wrote data.csv: {len(rows)} rows, seed {SEED}")
