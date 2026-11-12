# Simulated two-population joint site frequency spectrum (unfolded, derived-allele counts):
# ancestral frequencies ~ 1/p (neutral), then drift in each population (F = 0.03 and 0.10), then
# binomial sampling of n1 = 20 and n2 = 16 chromosomes. Writes data.csv: d1, d2, count (all cells).
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261120)
n1, n2, S = 20, 16, 60_000
p = np.exp(rng.uniform(np.log(1 / 2000), np.log(0.999), S))   # density ~ 1/p (neutral)
def drift(p, F):
    a = p * (1 - F) / F; b = (1 - p) * (1 - F) / F
    return rng.beta(a, b)
x1 = rng.binomial(n1, drift(p, 0.03)); x2 = rng.binomial(n2, drift(p, 0.10))
keep = ~(((x1 == 0) & (x2 == 0)) | ((x1 == n1) & (x2 == n2)))
J = np.zeros((n1 + 1, n2 + 1), dtype=int)
np.add.at(J, (x1[keep], x2[keep]), 1)
pd.DataFrame([(i, j, int(J[i, j])) for i in range(n1 + 1) for j in range(n2 + 1)],
             columns=["d1", "d2", "count"]).to_csv("data.csv", index=False)
