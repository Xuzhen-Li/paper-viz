"""Simulated ChIP-seq signal around 300 transcription start sites (two clusters), 40 bins of 150 bp. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(113)
bins = np.arange(-3000, 3000, 150) + 75
rows = []
for g in range(300):
    active = g < 120
    amp = rng.gamma(4, 1.2) if active else rng.gamma(1.5, 0.35)
    width = rng.uniform(350, 700)
    shift = rng.normal(150, 60)
    s = amp * np.exp(-0.5 * ((bins - shift) / width) ** 2) + 0.25 * amp * np.exp(-0.5 * ((bins + 400) / 300) ** 2) * active
    s = s + rng.gamma(2, 0.08, bins.size)
    rows += [(f"gene{g + 1:03d}", "active" if active else "low", int(b), round(float(v), 3)) for b, v in zip(bins, s)]
pd.DataFrame(rows, columns=["gene", "cluster", "bin_mid", "signal"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
