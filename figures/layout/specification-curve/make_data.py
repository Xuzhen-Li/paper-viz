"""Simulated multiverse: effect estimate and 95% CI for 48 analysis specifications (4 x 3 x 2 x 2 choices). Fixed seed."""
from itertools import product
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(5)
rows = []
for out, cov, smp, mod in product(["Outcome A", "Outcome B", "Outcome C", "Outcome D"], ["No covariates", "Age + sex", "Full set"],
                                  ["All samples", "Exclude outliers"], ["OLS", "Mixed model"]):
    eff = 0.18 + {"Outcome A": 0.05, "Outcome B": 0.0, "Outcome C": -0.08, "Outcome D": 0.1}[out] \
        + {"No covariates": 0.06, "Age + sex": 0.0, "Full set": -0.05}[cov] + (0.02 if smp == "Exclude outliers" else 0) + rng.normal(0, 0.03)
    se = rng.uniform(0.04, 0.07)
    rows.append((out, cov, smp, mod, round(eff, 4), round(se, 4)))
pd.DataFrame(rows, columns=["outcome", "covariates", "sample", "model", "estimate", "se"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
