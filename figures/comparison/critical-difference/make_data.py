"""Simulated method scores on 16 datasets for a Friedman / Nemenyi CD example.
Higher score is better. Fixed seed. Placeholder method and dataset names.
Run: python3 make_data.py"""
import csv
import numpy as np

SEED = 20261136
rng = np.random.default_rng(SEED)
n_data = 16
methods = ["Method A", "Method B", "Method C", "Method D", "Method E", "Method F"]
# Mean offsets: C and D best, A weakest
offset = np.array([-0.22, -0.05, 0.28, 0.22, 0.06, -0.10])

with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["dataset", "method", "score"])
    for i in range(n_data):
        base = rng.normal(0.70, 0.08)
        noise = rng.normal(0.0, 0.07, len(methods))
        for j, m in enumerate(methods):
            score = np.clip(base + offset[j] + noise[j], 0.05, 0.99)
            w.writerow([f"Set {i + 1:02d}", m, f"{score:.6f}"])
print("wrote data.csv")
