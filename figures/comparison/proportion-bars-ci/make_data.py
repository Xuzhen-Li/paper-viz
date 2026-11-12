"""Simulated benchmark tasks tagged with keywords (a task can carry 1-3 keywords) and
whether each task shows the property of interest (1 / 0). One row per task x keyword.
Keyword and task names are placeholders. Fixed seed. Run: python3 make_data.py"""
import csv
from pathlib import Path

import numpy as np

SEED = 20261317
rng = np.random.default_rng(SEED)
n_tasks = 210
keywords = [f"Keyword {i}" for i in range(1, 13)]
pop = rng.dirichlet(np.full(len(keywords), 2.0))          # how often each keyword is used
logit_k = rng.normal(-0.9, 0.9, len(keywords))           # keyword effect on the property

rows = []
for t in range(n_tasks):
    kw = rng.choice(len(keywords), size=rng.integers(1, 4), replace=False, p=pop)
    p = 1 / (1 + np.exp(-np.mean(logit_k[kw])))
    y = int(rng.random() < p)
    for k in sorted(kw):
        rows.append({"task": f"Task {t + 1:03d}", "keyword": keywords[k], "has_property": y})

with Path(__file__).with_name("data.csv").open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["task", "keyword", "has_property"])
    w.writeheader()
    w.writerows(rows)
print(f"wrote data.csv ({len(rows)} rows)")
