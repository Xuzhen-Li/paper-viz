"""Simulated paired before/after responses for a paired estimation plot.
Subject identifiers are placeholders. Run: python3 make_data.py"""
from pathlib import Path

import csv
import numpy as np

SEED = 20261126
rng = np.random.default_rng(SEED)

n = 24
before = rng.normal(10.0, 1.8, n)
delta = rng.normal(1.9, 1.3, n)
after = before + delta

rows = []
for i, (b, a) in enumerate(zip(before, after), start=1):
    rows.append({"subject": f"S{i:02d}", "condition": "Before", "value": f"{b:.3f}"})
    rows.append({"subject": f"S{i:02d}", "condition": "After", "value": f"{a:.3f}"})

out = Path(__file__).with_name("data.csv")
with out.open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["subject", "condition", "value"])
    w.writeheader()
    w.writerows(rows)
print("wrote data.csv")
