"""Simulated univariate responses in five conditions. plot.py computes means,
95% CIs and n from these rows. Run: python3 make_data.py"""
from pathlib import Path

import csv
import numpy as np

SEED = 20261123
rng = np.random.default_rng(SEED)

conditions = [
    ("Vehicle", 10.0, 1.8, 18),
    ("Dose A", 11.1, 1.9, 17),
    ("Dose B", 12.4, 2.0, 19),
    ("Dose C", 13.0, 2.1, 18),
    ("Dose D", 12.2, 2.4, 16),
]

rows = []
for name, mu, sd, n in conditions:
    for v in rng.normal(mu, sd, n):
        rows.append({"condition": name, "value": f"{v:.3f}"})

out = Path(__file__).with_name("data.csv")
with out.open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["condition", "value"])
    w.writeheader()
    w.writerows(rows)
print("wrote data.csv")
