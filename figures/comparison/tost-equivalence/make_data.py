"""Simulated two-group scores for a TOST equivalence example.
Fixed seed. Placeholder group names. Run: python3 make_data.py"""
import csv
import numpy as np

SEED = 20261131
rng = np.random.default_rng(SEED)
n_a, n_b = 42, 45
# Small mean difference relative to a pre-specified margin of 0.50
a = rng.normal(0.00, 0.95, n_a)
b = rng.normal(0.12, 0.95, n_b)

with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["group", "score"])
    for v in a:
        w.writerow(["Group A", f"{v:.6f}"])
    for v in b:
        w.writerow(["Group B", f"{v:.6f}"])
print("wrote data.csv")
