"""Simulated two-sample Mendelian randomisation: 30 instruments with SNP-exposure and SNP-outcome effects. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(13)
n = 30
bx = rng.uniform(0.03, 0.25, n); sx = rng.uniform(0.006, 0.015, n)
pleio = np.where(rng.random(n) < 0.15, rng.normal(0.03, 0.01, n), 0)
by = 0.35 * bx + pleio + rng.normal(0, 0.012, n); sy = rng.uniform(0.008, 0.02, n)
pd.DataFrame({"snp": [f"rs{1000 + i}" for i in range(n)], "beta_exposure": bx.round(4), "se_exposure": sx.round(4),
              "beta_outcome": by.round(4), "se_outcome": sy.round(4)}).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
