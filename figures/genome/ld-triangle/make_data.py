# Simulated haplotypes in three linkage blocks -> pairwise LD (r^2) for one region.
# Writes data.csv (one row per SNP pair). Fixed seed; no real genotypes.
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261113)
n_hap, n_snp = 300, 60
blocks = [(0, 18), (18, 38), (38, 60)]          # SNP index ranges of the three blocks
start_bp = 12_400_000
pos = np.sort(rng.choice(np.arange(0, 250_000), n_snp, replace=False)) + start_bp

H = np.zeros((n_hap, n_snp), dtype=int)
prev = None
for a, b in blocks:
    k = b - a
    f0 = rng.integers(0, 2, k)
    f1 = np.where(rng.random(k) < 0.8, 1 - f0, f0)      # second common haplotype: mostly opposite alleles
    f2 = np.where(rng.random(k) < 0.25, 1 - f0, f0)     # rarer haplotype close to the first
    f3 = rng.integers(0, 2, k)
    founders = np.vstack([f0, f1, f2, f3])
    for j in range(k):                                    # every SNP polymorphic among founders
        while founders[:, j].min() == founders[:, j].max():
            founders[:, j] = rng.integers(0, 2, 4)
    pick = rng.choice(4, n_hap, p=[0.48, 0.32, 0.14, 0.06])
    if prev is not None:                                  # weak LD between neighbouring blocks
        keep = rng.random(n_hap) < 0.25
        pick[keep] = prev[keep]
    prev = pick
    H[:, a:b] = founders[pick] ^ (rng.random((n_hap, k)) < 0.02)   # 2% noise (mutation / recombination)

r2 = np.corrcoef(H, rowvar=False) ** 2
ids = [f"snp{i + 1:02d}" for i in range(n_snp)]
rows = [(ids[i], int(pos[i]), ids[j], int(pos[j]), round(float(r2[i, j]), 3))
        for i in range(n_snp) for j in range(i + 1, n_snp)]
pd.DataFrame(rows, columns=["snp1", "pos1", "snp2", "pos2", "r2"]).to_csv("data.csv", index=False)
