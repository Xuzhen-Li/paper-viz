"""Simulated co-expression modules vs traits: 40 samples, Pearson r and two-sided t-test P per cell. Fixed seed.
P is computed with a numerical Student t integral so the script needs only numpy."""
from math import lgamma
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(59)
n = 40
traits = ["Height", "Leaf area", "Yield", "Flowering", "Drought score", "Sugar"]
modules = [("turquoise", 1820), ("blue", 1311), ("brown", 954), ("yellow", 702), ("green", 588),
           ("red", 431), ("black", 377), ("pink", 290), ("magenta", 214), ("purple", 158)]
T = rng.normal(0, 1, (n, len(traits)))
load = np.zeros((len(modules), len(traits)))
load[0, 2] = 0.9; load[1, 0] = -0.7; load[1, 1] = -0.5; load[3, 4] = 0.75; load[5, 3] = -0.6; load[7, 5] = 0.55; load[2, 2] = 0.35
ME = T @ load.T + rng.normal(0, 0.8, (n, len(modules)))


def t_sf2(t, df):
    x = np.linspace(abs(t), abs(t) + 60, 20001)
    c = np.exp(lgamma((df + 1) / 2) - lgamma(df / 2)) / np.sqrt(df * np.pi)
    f = c * (1 + x ** 2 / df) ** (-(df + 1) / 2)
    return float(2 * np.sum((f[1:] + f[:-1]) / 2 * np.diff(x)))


rows = []
for i, (m, size) in enumerate(modules):
    for j, t in enumerate(traits):
        r = np.corrcoef(ME[:, i], T[:, j])[0, 1]
        tt = r * np.sqrt((n - 2) / (1 - r ** 2))
        rows.append((f"ME{m}", size, t, round(r, 3), float(f"{t_sf2(tt, n - 2):.3g}"), n))
pd.DataFrame(rows, columns=["module", "module_size", "trait", "r", "p", "n"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
