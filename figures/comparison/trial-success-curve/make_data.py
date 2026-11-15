"""Simulated success rate over repeated trials for four agent variants on 134 tasks. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(151)
n = 134
methods = {"Base": (0.48, 0.0), "Retry": (0.48, 0.10), "Self-critique": (0.50, 0.22), "Critique + memory": (0.50, 0.40)}
rows = []
for m, (p0, gain) in methods.items():
    solved = np.zeros(n, bool); p_task = np.clip(rng.normal(p0, 0.25, n), 0.02, 0.98)
    solved |= rng.random(n) < p_task
    for t in range(1, 11):
        if t > 1:
            solved |= rng.random(n) < gain * (1 - p_task) / (1 + 0.25 * t)
        rows.append((m, t, int(solved.sum()), n))
pd.DataFrame(rows, columns=["method", "trial", "solved", "n_tasks"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
