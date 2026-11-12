"""Simulated head-to-head judgments: for every corpus x metric, each pair of methods is
compared on the same questions; one row per judgment (outcome a / b / tie).
Method, metric and corpus names are placeholders. Fixed seed. Run: python3 make_data.py"""
import csv
from itertools import combinations
from pathlib import Path

import numpy as np

SEED = 20261307
rng = np.random.default_rng(SEED)
methods = ["Method A", "Method B", "Method C", "Method D", "Method E"]
metrics = ["Metric 1", "Metric 2", "Metric 3", "Metric 4"]
corpora = {"Corpus A": 120, "Corpus B": 140}        # questions per pair
base = np.array([-0.9, -0.2, 0.5, 0.35, 0.0])       # latent method strength
p_tie = 0.08

rows = []
for corpus, nq in corpora.items():
    for mi, metric in enumerate(metrics):
        s = base + rng.normal(0, 0.35, len(methods))
        if mi == 3:                                  # last metric favours the simplest method
            s = s[::-1] * 0.8
        for i, j in combinations(range(len(methods)), 2):
            p = 1 / (1 + np.exp(-(s[i] - s[j])))
            for q in range(nq):
                u = rng.random()
                out = "tie" if u < p_tie else ("a" if rng.random() < p else "b")
                rows.append({"corpus": corpus, "metric": metric, "question": f"Q{q + 1:03d}",
                             "method_a": methods[i], "method_b": methods[j], "outcome": out})

with Path(__file__).with_name("data.csv").open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0]))
    w.writeheader()
    w.writerows(rows)
print(f"wrote data.csv ({len(rows)} rows)")
