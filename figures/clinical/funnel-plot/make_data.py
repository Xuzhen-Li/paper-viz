"""Simulated meta-analysis: 35 studies, log odds ratios and standard errors with mild small-study effect. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(23)
se = rng.uniform(0.06, 0.55, 35)
y = 0.25 + rng.normal(0, se) + 0.5 * (se - 0.2) * (rng.random(35) < 0.5)
pd.DataFrame({"study": [f"S{i + 1:02d}" for i in range(35)], "log_or": y.round(4), "se": se.round(4)}).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
