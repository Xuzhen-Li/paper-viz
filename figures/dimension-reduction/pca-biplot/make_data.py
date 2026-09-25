#!/usr/bin/env python3
"""Simulated PC scores for three populations. Writes data.csv."""
import csv

import numpy as np

rng = np.random.default_rng(2)
groups = {
    "Pop1": rng.normal([-1, 0], 0.35, size=(40, 2)),
    "Pop2": rng.normal([1, 0.2], 0.4, size=(40, 2)),
    "Pop3": rng.normal([0, 1.2], 0.3, size=(30, 2)),
}
with open("data.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["sample", "group", "pc1", "pc2"])
    i = 1
    for name, pts in groups.items():
        for pc1, pc2 in pts:
            w.writerow([f"S{i:03d}", name, f"{pc1:.6f}", f"{pc2:.6f}"])
            i += 1
print("wrote data.csv")
