"""Simulated unpaired two-group responses for a Gardner-Altman estimation plot.
Group names are placeholders. Run: python3 make_data.py"""
from pathlib import Path

import csv
import numpy as np

SEED = 20261125
rng = np.random.default_rng(SEED)

rows = []
for v in rng.normal(10.0, 2.0, 32):
    rows.append({"group": "Control", "value": f"{v:.3f}"})
for v in rng.normal(12.4, 2.2, 30):
    rows.append({"group": "Treatment", "value": f"{v:.3f}"})

out = Path(__file__).with_name("data.csv")
with out.open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["group", "value"])
    w.writeheader()
    w.writerows(rows)
print("wrote data.csv")
