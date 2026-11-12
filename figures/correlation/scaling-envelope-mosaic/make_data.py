"""Simulated data for scaling-envelope-mosaic (C03). Fixed seed; writes data.csv once (open 'x').
Chinchilla-style idea only: a parametric loss L(N, D) = E + A / N**alpha + B / D**beta with made-up
constants (not the published fit), C = 6 N D FLOPs. No published values are used.
  kind = 'run'     : training curves; 10 model sizes x 4 cosine cycle lengths, loss logged along each run
  kind = 'isoflop' : final losses for 9 model sizes at each of 6 fixed compute budgets
"""
from pathlib import Path

import numpy as np
import pandas as pd

SEED = 20261403
rng = np.random.default_rng(SEED)
E, A, ALPHA, B, BETA = 1.75, 380.0, 0.33, 410.0, 0.28   # simulation constants (invented)


def loss(n, d):
    return E + A / n**ALPHA + B / d**BETA


rows = []
sizes = np.geomspace(7e7, 1.0e10, 10)
tokens_per_param = [6.0, 12.0, 24.0, 48.0]          # cosine cycle length = tpp x N tokens
rid = 0
for n in sizes:
    for tpp in tokens_per_param:
        rid += 1
        cycle = tpp * n
        d = np.geomspace(cycle / 40, cycle, 36)
        frac = d / cycle
        penalty = 0.09 * (1 - frac) * (1 - np.exp(-6 * frac))   # mid-cycle lr is still high
        y = loss(n, d) + penalty + rng.normal(0, 0.004, d.size)
        for di, yi in zip(d, y):
            rows.append(dict(kind="run", run_id=f"R{rid:02d}", params=float(f"{n:.4g}"),
                             tokens=float(f"{di:.4g}"), cycle_tokens=float(f"{cycle:.4g}"),
                             budget_flops=np.nan, loss=round(float(yi), 5)))

budgets = [3e18, 1e19, 3e19, 1e20, 3e20, 1e21]
for c in budgets:
    # 9 sizes on a log grid around the model that minimises the simulated loss for this budget
    grid = np.geomspace(1e7, 1e12, 4001)
    nstar = grid[np.argmin(loss(grid, c / (6 * grid)))]
    ns = nstar * np.geomspace(1 / 8, 8, 9) * np.exp(rng.normal(0, 0.05, 9))
    for n in ns:
        d = c / (6 * n)
        y = loss(n, d) + rng.normal(0, 0.006)
        rows.append(dict(kind="isoflop", run_id=f"B{budgets.index(c) + 1}", params=float(f"{n:.4g}"),
                         tokens=float(f"{d:.4g}"), cycle_tokens=float(f"{d:.4g}"),
                         budget_flops=c, loss=round(float(y), 5)))

df = pd.DataFrame(rows)
with open(Path(__file__).with_name("data.csv"), "x") as fh:
    df.to_csv(fh, index=False)
print("rows", len(df), "runs", df[df.kind == "run"].run_id.nunique(), "budgets", df[df.kind == "isoflop"].run_id.nunique())
