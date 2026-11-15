"""Simulated reinforcement-learning run on a placeholder benchmark of 60 problems. At each
checkpoint (every 400 steps) the policy draws 16 answers per problem; an answer is either the
correct one or one of four wrong candidates. For each problem we store how many of the 16
answers were correct and whether the most frequent answer (majority vote; ties broken at
random) was correct. A fixed reference model is scored the same way once (step left empty).
Names are placeholders. Writes data.csv once (refuses to overwrite). Run: python3 make_data.py"""
import csv

import numpy as np

SEED = 20261310
rng = np.random.default_rng(SEED)
n_problems, n_samples, n_wrong = 60, 16, 4
steps = np.arange(0, 8001, 400)
difficulty = rng.normal(0.0, 1.3, n_problems)
wrong_w = rng.dirichlet(np.full(n_wrong, 1.5), n_problems)     # how wrong answers cluster


def score(logit):
    """16 answers per problem -> (n_correct, majority_correct) per problem."""
    out = []
    p = 1 / (1 + np.exp(-logit))
    for j in range(n_problems):
        probs = np.concatenate([[p[j]], (1 - p[j]) * wrong_w[j]])
        counts = rng.multinomial(n_samples, probs)
        top = np.flatnonzero(counts == counts.max())
        out.append((int(counts[0]), int(rng.choice(top) == 0)))
    return out


with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["model", "step", "problem", "n_samples", "n_correct", "majority_correct"])
    for t in steps:
        drift = rng.normal(0.0, 0.12)                               # checkpoint-to-checkpoint wobble
        logit = -1.9 + 3.0 * (1 - np.exp(-t / 3000)) - difficulty + drift
        for j, (c, mv) in enumerate(score(logit)):
            w.writerow(["Policy", int(t), f"Q{j + 1:02d}", n_samples, c, mv])
    for j, (c, mv) in enumerate(score(-1.9 + 2.5 - difficulty)):
        w.writerow(["Reference A", "", f"Q{j + 1:02d}", n_samples, c, mv])
print("wrote data.csv")
