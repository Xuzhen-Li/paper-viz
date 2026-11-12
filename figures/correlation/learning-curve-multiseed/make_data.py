"""Simulated validation error vs training-set size for two methods and five seeds.
Fixed seed. Placeholder method names. Run: python3 make_data.py"""
import csv
import numpy as np

SEED = 20261135
rng = np.random.default_rng(SEED)
n_train = [50, 100, 200, 400, 800, 1600]
n_seeds = 5
# method: (floor, scale, exponent, seed s.d.)
methods = {
    "Method A": (0.085, 0.70, 0.42, 0.016),
    "Method B": (0.130, 0.95, 0.38, 0.022),
}

with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["method", "seed", "n_train", "val_error"])
    for name, (floor, scale, exp, sd) in methods.items():
        for s in range(n_seeds):
            # one persistent seed offset plus small size-specific noise
            off = rng.normal(0.0, sd)
            for n in n_train:
                err = floor + scale * (n ** (-exp)) + off + rng.normal(0.0, sd * 0.35)
                w.writerow([name, s + 1, n, f"{max(err, 0.02):.6f}"])
print("wrote data.csv")
