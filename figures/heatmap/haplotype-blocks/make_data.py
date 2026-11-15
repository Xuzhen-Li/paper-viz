# Simulated phased haplotypes of three groups across four haplotype blocks; block 3 carries a
# swept haplotype in the cultivated group. Writes data.csv (one row per haplotype x SNP).
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261115)
groups = {"Wild": 24, "Landrace": 24, "Cultivar": 24}
block_sizes = [10, 14, 12, 14]
start_bp = 8_200_000
gaps = rng.integers(3_000, 9_000, sum(block_sizes)); gaps[np.cumsum(block_sizes)[:-1]] += 25_000
pos = start_bp + np.cumsum(gaps)
# per block: 4 founder haplotypes; group-specific founder frequencies (rows = Wild, Landrace, Cultivar)
freqs = [np.array([[.35, .30, .20, .15], [.45, .30, .15, .10], [.50, .30, .15, .05]]),
         np.array([[.30, .30, .25, .15], [.40, .25, .20, .15], [.55, .20, .15, .10]]),
         np.array([[.20, .30, .30, .20], [.55, .20, .15, .10], [.92, .04, .02, .02]]),   # sweep in Cultivar
         np.array([[.30, .25, .25, .20], [.35, .30, .20, .15], [.40, .30, .20, .10]])]
rows, snp0 = [], 0
hap_ids = [(g, f"{g[:1]}{k + 1:02d}") for g, m in groups.items() for k in range(m)]
for b, k in enumerate(block_sizes):
    founders = rng.integers(0, 2, (4, k))
    founders[0] = 0                                  # most common haplotype carries reference alleles
    for j in range(k):
        while founders[:, j].max() == 0:
            founders[1:, j] = rng.integers(0, 2, 3)
    for gi, (g, h) in enumerate(hap_ids):
        grp = list(groups).index(g)
        f = rng.choice(4, p=freqs[b][grp])
        alle = founders[f] ^ (rng.random(k) < 0.015)
        for j in range(k):
            rows.append((h, g, f"B{b + 1}", f"s{snp0 + j + 1:02d}", int(pos[snp0 + j]), int(alle[j])))
    snp0 += k
pd.DataFrame(rows, columns=["hap", "group", "block", "snp", "pos", "allele"]).to_csv("data.csv", index=False)
