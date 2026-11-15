"""Simulated validation cohort: 800 patients, binary outcome, predicted risks from two models. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(31)
n = 800
lp = rng.normal(-1.5, 1.1, n)
y = (rng.random(n) < 1 / (1 + np.exp(-lp))).astype(int)
risk_a = 1 / (1 + np.exp(-(lp + rng.normal(0, 0.45, n))))
risk_b = 1 / (1 + np.exp(-(0.55 * lp - 0.6 + rng.normal(0, 0.9, n))))
pd.DataFrame({"patient": [f"P{i + 1:03d}" for i in range(n)], "outcome": y,
              "risk_a": risk_a.round(4), "risk_b": risk_b.round(4)}).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
