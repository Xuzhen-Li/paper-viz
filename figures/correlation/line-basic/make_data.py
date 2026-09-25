#!/usr/bin/env python3
"""Simulated noisy sine. Writes data.csv."""
import csv

import numpy as np

rng = np.random.default_rng(0)
x = np.linspace(0, 10, 80)
y = np.sin(x) + rng.normal(0, 0.08, size=x.shape)
with open("data.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["x", "y"])
    w.writerows(zip((f"{v:.6f}" for v in x), (f"{v:.6f}" for v in y)))
print("wrote data.csv")
