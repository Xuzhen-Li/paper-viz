"""Simulated scaling-law runs: validation loss of models of nine sizes, each trained on three
token budgets. Loss follows L = E + A / N^alpha + B / D^beta with small multiplicative noise.
Run from this directory: python3 make_data.py"""
import csv
import numpy as np

rng = np.random.default_rng(20261112)
E, A, ALPHA, B, BETA = 1.69, 406.4, 0.34, 410.7, 0.28   # constants of the simulation only
params = np.logspace(7.5, 10.5, 9)                       # non-embedding parameters
tokens = [2e9, 2e10, 2e11]                               # training tokens
with open("data.csv", "w", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["params", "tokens", "loss"])
    for d in tokens:
        for n in params:
            loss = (E + A / n**ALPHA + B / d**BETA) * np.exp(rng.normal(0, 0.008))
            w.writerow([f"{n:.4g}", f"{d:.4g}", f"{loss:.4f}"])
print("wrote data.csv")
