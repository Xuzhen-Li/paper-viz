"""Simulated two-group observations for eight placeholder studies of the same
endpoint. plot.py computes the mean difference, CI and n from these rows.
Run: python3 make_data.py"""
from pathlib import Path

import csv
import numpy as np

SEED = 20261122
rng = np.random.default_rng(SEED)

# study, n_control, n_treat, mu_control, mu_treat, sd
studies = [
    ("Study 1", 42, 44, 10.0, 11.6, 2.4),
    ("Study 2", 30, 31, 10.2, 10.8, 2.1),
    ("Study 3", 55, 54, 9.8, 12.1, 2.6),
    ("Study 4", 28, 27, 10.1, 9.7, 2.0),
    ("Study 5", 48, 50, 10.4, 12.4, 2.5),
    ("Study 6", 36, 35, 9.9, 11.0, 2.3),
    ("Study 7", 60, 61, 10.0, 11.3, 2.2),
    ("Study 8", 24, 26, 10.3, 13.0, 2.8),
]

rows = []
for name, n0, n1, m0, m1, sd in studies:
    for v in rng.normal(m0, sd, n0):
        rows.append({"study": name, "group": "Control", "value": f"{v:.3f}"})
    for v in rng.normal(m1, sd, n1):
        rows.append({"study": name, "group": "Treatment", "value": f"{v:.3f}"})

out = Path(__file__).with_name("data.csv")
with out.open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["study", "group", "value"])
    w.writeheader()
    w.writerows(rows)
print("wrote data.csv")
