"""Simulated p-values under a uniform null and under a mixture with a spike near 0.
Fixed seed. Run: python3 make_data.py"""
import csv
import numpy as np

SEED = 20261130
N = 2000
rng = np.random.default_rng(SEED)

p_null = rng.uniform(0.0, 1.0, N)
# 18% small p-values (Beta spike near 0), 82% uniform (null-like tests)
is_alt = rng.random(N) < 0.18
p_mix = np.empty(N)
p_mix[is_alt] = rng.beta(0.12, 5.0, int(is_alt.sum()))
p_mix[~is_alt] = rng.uniform(0.0, 1.0, int((~is_alt).sum()))
p_mix = np.clip(p_mix, 1e-12, 1.0)

with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["set", "p_value"])
    for p in p_null:
        w.writerow(["Null only", f"{p:.8f}"])
    for p in p_mix:
        w.writerow(["With effects", f"{p:.8f}"])
print("wrote data.csv")
