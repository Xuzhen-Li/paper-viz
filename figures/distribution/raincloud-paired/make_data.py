"""Simulated repeated-measures data: every subject measured under two conditions; a few
subjects miss the second session (kept in data.csv, not paired). One row per subject x
condition. Subject ids and condition names are placeholders. Fixed seed.
Run: python3 make_data.py"""
import csv
from pathlib import Path

import numpy as np

SEED = 20261328
rng = np.random.default_rng(SEED)
n = 34
base = rng.normal(50, 8, n)                      # subject level
change = rng.normal(4.0, 5.0, n)                 # subject-specific change
missing = set(rng.choice(n, 2, replace=False))   # no second session

rows = []
for i in range(n):
    sid = f"S{i + 1:02d}"
    rows.append({"subject": sid, "condition": "Condition 1", "value": f"{base[i] + rng.normal(0, 2):.2f}"})
    if i not in missing:
        rows.append({"subject": sid, "condition": "Condition 2", "value": f"{base[i] + change[i]:.2f}"})

with Path(__file__).with_name("data.csv").open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["subject", "condition", "value"])
    w.writeheader()
    w.writerows(rows)
print(f"wrote data.csv ({len(rows)} rows)")
