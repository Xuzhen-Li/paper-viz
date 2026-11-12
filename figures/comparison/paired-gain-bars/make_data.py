"""Simulated pairwise-judge evaluation for six placeholder models on 400 placeholder prompts.
Each model answers every prompt twice: alone, and after it is shown the answers of the other
models as extra context. A judge compares each answer with a fixed reference answer: win = 1,
tie = 0.5, loss = 0. Names are placeholders. Writes data.csv once (refuses to overwrite).
Run: python3 make_data.py"""
import csv

import numpy as np

SEED = 20261313
rng = np.random.default_rng(SEED)
n_prompts = 400
models = [f"Model {i}" for i in range(1, 7)]
base = rng.uniform(-1.4, 0.3, len(models))          # logit of winning, answering alone
gain = rng.uniform(0.25, 0.75, len(models))          # logit gain with other models' answers
prompt_eff = rng.normal(0.0, 0.8, n_prompts)
p_tie = 0.08

with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["model", "condition", "prompt", "outcome"])
    for i, m in enumerate(models):
        for cond, lg in (("Alone", base[i]), ("With other models' answers", base[i] + gain[i])):
            p = 1 / (1 + np.exp(-(lg + prompt_eff)))
            u = rng.uniform(size=n_prompts)
            tie = rng.uniform(size=n_prompts) < p_tie
            out = np.where(tie, 0.5, (u < p).astype(float))
            for j in range(n_prompts):
                w.writerow([m, cond, f"P{j + 1:03d}", f"{out[j]:g}"])
print("wrote data.csv")
