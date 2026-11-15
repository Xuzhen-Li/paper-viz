"""Simulated responses for one shared control group and three test groups (independent
groups, unequal n). One row per subject. Group names are placeholders. Fixed seed.
Run: python3 make_data.py"""
import csv
from pathlib import Path

import numpy as np

SEED = 20261320
rng = np.random.default_rng(SEED)
specs = {"Control": (22, 10.0, 1.6), "Group A": (20, 10.6, 1.7),
         "Group B": (24, 12.1, 1.9), "Group C": (18, 9.1, 1.5)}   # n, mean, s.d.

rows = []
for g, (n, mu, sd) in specs.items():
    for i, v in enumerate(rng.normal(mu, sd, n)):
        rows.append({"subject": f"{g[-1] if g != 'Control' else 'K'}{i + 1:02d}", "group": g, "value": f"{v:.3f}"})

with Path(__file__).with_name("data.csv").open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["subject", "group", "value"])
    w.writeheader()
    w.writerows(rows)
print(f"wrote data.csv ({len(rows)} rows)")
