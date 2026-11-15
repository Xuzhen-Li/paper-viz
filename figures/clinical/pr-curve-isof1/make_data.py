"""Simulated classifier scores: 1,500 samples, 12% positives, two models. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(83)
n = 1500
y = (rng.random(n) < 0.12).astype(int)
a = rng.normal(0, 1, n) + 2.0 * y
b = rng.normal(0, 1, n) + 1.2 * y
pd.DataFrame({"sample": [f"s{i + 1:04d}" for i in range(n)], "label": y,
              "score_a": a.round(4), "score_b": b.round(4)}).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
