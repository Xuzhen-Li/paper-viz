"""Simulated binary labels and classifier scores for three placeholder models
on the same items (class imbalance around 15%). Run: python3 make_data.py"""
from pathlib import Path

import csv
import numpy as np

SEED = 20261128
rng = np.random.default_rng(SEED)

n = 2500
prev = 0.15
y = (rng.random(n) < prev).astype(int)

# higher score should tend to belong to the positive class; models differ in separation
# latent: positives ~ N(mu, 1), negatives ~ N(0, 1), then a small calibration jitter
models = {
    "Model A": 1.10,
    "Model B": 1.70,
    "Model C": 2.35,
}

rows = []
for name, sep in models.items():
    z = rng.normal(sep * y, 1.0)
    # logistic-ish score in (0, 1) but not a probability calibrated to prev
    score = 1.0 / (1.0 + np.exp(-(z - 0.5)))
    score = np.clip(score, 1e-6, 1 - 1e-6)
    for i in range(n):
        rows.append({
            "model": name,
            "item": f"X{i + 1:04d}",
            "label": int(y[i]),
            "score": f"{score[i]:.6f}",
        })

out = Path(__file__).with_name("data.csv")
with out.open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["model", "item", "label", "score"])
    w.writeheader()
    w.writerows(rows)
print("wrote data.csv")
