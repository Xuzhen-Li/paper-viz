"""Simulated human evaluation of two placeholder systems on 12 placeholder tasks by 10 raters.
For every (rater, task) the rater (i) states which system's answer they prefer (A, B or tie)
and (ii) scores both answers on three generic dimensions on a 1-10 integer scale.
record = "preference" rows carry the choice in `system` and leave dimension/score empty;
record = "score" rows carry one score. Names are placeholders. Writes data.csv once
(refuses to overwrite). Run: python3 make_data.py"""
import csv

import numpy as np

SEED = 20261315
rng = np.random.default_rng(SEED)
n_raters, n_tasks = 10, 12
systems = ["System A", "System B"]
dims = ["Correctness", "Reasoning", "Completion"]
dim_gap = {"Correctness": 1.6, "Reasoning": 0.9, "Completion": 2.2}   # A minus B, scale points
task_eff = rng.normal(0.0, 0.8, n_tasks)          # task-specific advantage of A (scale points)
rater_eff = rng.normal(0.0, 0.6, n_raters)        # rater leniency

with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["record", "rater", "task", "system", "dimension", "score"])
    for i in range(n_raters):
        for t in range(n_tasks):
            r, tk = f"Rater {i + 1:02d}", f"Task {t + 1}"
            tot = {}
            for s in systems:
                tot[s] = 0.0
                for d in dims:
                    mu = 5.4 + rater_eff[i] + (0.5 if s == "System A" else -0.5) * (dim_gap[d] + task_eff[t])
                    sc = int(np.clip(np.rint(mu + rng.normal(0.0, 1.2)), 1, 10))
                    tot[s] += sc
                    w.writerow(["score", r, tk, s, d, sc])
            diff = tot["System A"] - tot["System B"] + rng.normal(0.0, 4.0)
            choice = "System A" if diff > 1.5 else ("System B" if diff < -1.5 else "Tie")
            w.writerow(["preference", r, tk, choice, "", ""])
print("wrote data.csv")
