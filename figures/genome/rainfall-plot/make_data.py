"""Simulated somatic SNVs on 6 chromosomes with two kataegis clusters; substitution class per variant. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(21)
sizes = {"chr1": 248, "chr2": 242, "chr3": 198, "chr4": 190, "chr5": 181, "chr6": 171}   # Mb
cls = ["C>A", "C>G", "C>T", "T>A", "T>C", "T>G"]
rows = []
for c, L in sizes.items():
    for p in np.sort(rng.uniform(0, L * 1e6, int(L * 2.2))):
        rows.append((c, int(p), rng.choice(cls, p=[.18, .12, .35, .1, .17, .08])))
for c, centre in (("chr2", 61e6), ("chr5", 120e6)):          # kataegis: dense C>T / C>G at TpC
    for p in centre + np.cumsum(rng.exponential(900, 40)):
        rows.append((c, int(p), rng.choice(["C>T", "C>G"])))
df = pd.DataFrame(rows, columns=["chrom", "pos", "substitution"]).sort_values(["chrom", "pos"])
df.to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
