"""Simulated random-intercept scores for 24 groups with uneven sample sizes.
Fixed seed. Placeholder group names. Run: python3 make_data.py"""
import csv
import numpy as np

SEED = 20261134
rng = np.random.default_rng(SEED)
n_groups = 24
mu = 0.0
tau = 0.55
sigma = 0.90
# Uneven group sizes
n_j = rng.integers(8, 36, size=n_groups)
u = rng.normal(0.0, tau, n_groups)

with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["group", "y"])
    for j in range(n_groups):
        name = f"Group {j + 1:02d}"
        y = mu + u[j] + rng.normal(0.0, sigma, int(n_j[j]))
        for v in y:
            w.writerow([name, f"{v:.6f}"])
print("wrote data.csv")
