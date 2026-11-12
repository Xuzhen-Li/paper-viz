"""Simulated model zoo: 36 models from four families, each with training compute (FLOPs) and a
benchmark accuracy (%) that rises logistically with log10(compute) plus a family offset and noise.
Model names are placeholders. Run: python3 make_data.py"""
import csv
import numpy as np

rng = np.random.default_rng(20261115)
families = {"A": 6.0, "B": 0.0, "C": -5.0, "D": -10.0}     # accuracy offset (points)
with open("data.csv", "w", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["model", "family", "flops", "accuracy"])
    for fam, off in families.items():
        logc = np.linspace(20.2, 24.8, 9) + rng.normal(0, 0.15, 9)
        for k, lc in enumerate(logc, 1):
            acc = 25 + 60 / (1 + np.exp(-(lc - 22.6) * 1.3)) + off + rng.normal(0, 2.0)
            w.writerow([f"{fam}-{k}", fam, f"{10**lc:.4g}", f"{np.clip(acc, 0, 100):.1f}"])
print("wrote data.csv")
