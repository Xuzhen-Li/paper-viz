"""Simulated paired before/after responses for two groups (one row per subject and
condition). Subject ids are placeholders. Fixed seed. Run: python3 make_data.py"""
import csv
from pathlib import Path

import numpy as np

SEED = 20261127
rng = np.random.default_rng(SEED)
conditions = ["Before", "After"]
specs = {"Control": (18, 0.3), "Treatment": (18, 2.0)}   # (n subjects, mean change)

rows = []
for g, (n, shift) in specs.items():
    base = rng.normal(10.0, 1.6, n)                 # subject baselines
    change = rng.normal(shift, 1.1, n)              # subject-specific change
    for i in range(n):
        sid = f"{g[0]}{i + 1:02d}"
        rows.append({"subject": sid, "group": g, "condition": "Before", "value": f"{base[i]:.3f}"})
        rows.append({"subject": sid, "group": g, "condition": "After", "value": f"{base[i] + change[i]:.3f}"})

with Path(__file__).with_name("data.csv").open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["subject", "group", "condition", "value"])
    w.writeheader()
    w.writerows(rows)
print("wrote data.csv")
