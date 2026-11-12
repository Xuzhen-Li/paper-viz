"""Simulated cohort: 8,000 people, standardised polygenic score and case status under a liability model. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(157)
n = 8000
prs = rng.normal(0, 1, n)
liab = 0.55 * prs + rng.normal(0, 1, n)
case = (liab > np.quantile(liab, 0.9)).astype(int)
pd.DataFrame({"id": [f"P{i + 1:05d}" for i in range(n)], "prs": prs.round(4), "case": case}).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
