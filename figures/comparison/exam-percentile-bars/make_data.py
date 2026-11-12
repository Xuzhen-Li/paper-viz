"""Simulated exam results for two placeholder models: for each of 12 generic exams, the
percentile of a simulated population of human test-takers that each model's score beats.
Exam and model names are placeholders. Writes data.csv once (refuses to overwrite).
Run: python3 make_data.py"""
import csv

import numpy as np

SEED = 20261309
rng = np.random.default_rng(SEED)
exams = [f"Exam {c}" for c in "ABCDEFGHIJKL"]
n_takers = 5000                       # simulated human test-takers per exam
ability = rng.normal(0.0, 1.0, len(exams))   # exam-specific model-1 standing (z score)
gain = rng.normal(0.9, 0.55, len(exams))     # model-2 improvement (z units)

with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["exam", "model", "percentile"])
    for j, e in enumerate(exams):
        takers = rng.normal(0.0, 1.0, n_takers)
        for m, z in (("Model 1", ability[j]), ("Model 2", ability[j] + gain[j])):
            score = z + rng.normal(0.0, 0.15)            # one sitting, small noise
            pct = 100.0 * np.mean(takers < score)
            w.writerow([e, m, f"{pct:.1f}"])
print("wrote data.csv")
