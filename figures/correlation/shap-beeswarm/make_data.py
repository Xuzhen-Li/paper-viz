"""Simulated SHAP values for a tree model: 400 samples x 9 features, feature values scaled to 0-1. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(137)
n = 400
feats = {"Age": 0.9, "HbA1c": 0.75, "BMI": 0.55, "Systolic BP": 0.4, "LDL": 0.3, "eGFR": -0.35, "Smoking": 0.25,
         "Physical activity": -0.2, "Sex": 0.08}
rows = []
for f, w in feats.items():
    x = rng.random(n) if f not in ("Smoking", "Sex") else (rng.random(n) < 0.35).astype(float)
    s = w * (x - x.mean()) * 2 + rng.normal(0, 0.06 + 0.1 * abs(w), n) * (0.4 + x)
    rows += [(i + 1, f, round(float(a), 3), round(float(b), 4)) for i, (a, b) in enumerate(zip(x, s))]
pd.DataFrame(rows, columns=["sample", "feature", "value", "shap"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
