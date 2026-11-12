"""Simulated review scores (1-10 scale) of generated papers, by domain x base model; the
number of papers per cell varies. One row per paper. Domain, model and paper ids are
placeholders. Fixed seed. Run: python3 make_data.py"""
import csv
from pathlib import Path

import numpy as np

SEED = 20261318
rng = np.random.default_rng(SEED)
domains = ["Domain A", "Domain B", "Domain C", "Domain D"]
models = ["Model 1", "Model 2", "Model 3"]
model_mu = np.array([4.9, 4.2, 3.4])
domain_mu = np.array([0.3, -0.2, 0.1, -0.5])

rows = []
for di, d in enumerate(domains):
    for mi, m in enumerate(models):
        n = int(rng.integers(24, 52))
        mu = model_mu[mi] + domain_mu[di] + rng.normal(0, 0.25)
        # mixture: most papers near mu, a few failed ones near the floor
        fail = rng.random(n) < 0.08
        s = np.where(fail, rng.normal(1.8, 0.5, n), rng.normal(mu, 1.0, n))
        s = np.clip(np.round(s, 1), 1.0, 10.0)
        for i, v in enumerate(s):
            rows.append({"domain": d, "model": m, "paper": f"{d[-1]}{mi + 1}-{i + 1:03d}", "score": f"{v:.1f}"})

with Path(__file__).with_name("data.csv").open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["domain", "model", "paper", "score"])
    w.writeheader()
    w.writerows(rows)
print(f"wrote data.csv ({len(rows)} rows)")
