"""Simulated gene-set membership for an enrichment map: 40 generic pathways built mostly from
five gene pools (themes), 12 pathways of random genes, and a gene list (in_list = 1) enriched
for four of the pools. Fixed seed. Writes data.csv once (open 'x'): one row per pathway x
member gene."""
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261126)
n_genes, pool = 3000, 60
pools = [np.arange(t * pool, (t + 1) * pool) for t in range(5)]
p_hit = np.full(n_genes, 0.04)
for t, h in enumerate([0.50, 0.45, 0.40, 0.35]):
    p_hit[pools[t]] = h
in_list = (rng.random(n_genes) < p_hit).astype(int)
sets = []
for t in range(5):
    for j in range(8):
        size = int(rng.integers(15, 61))
        n_pool = int(round(size * rng.uniform(0.7, 0.9)))
        mem = set(rng.choice(pools[t], min(n_pool, pool), replace=False))
        while len(mem) < size:
            mem.add(int(rng.integers(5 * pool, n_genes)))
        sets.append(mem)
for j in range(12):
    size = int(rng.integers(15, 61))
    sets.append(set(rng.choice(np.arange(5 * pool, n_genes), size, replace=False)))
rows = []
for k, mem in enumerate(sets, start=1):
    rows += [(f"Pathway {k}", f"Gene {g + 1:04d}", int(in_list[g])) for g in sorted(int(x) for x in mem)]
d = pd.DataFrame(rows, columns=["pathway", "gene", "in_list"])
with open("data.csv", "x", encoding="utf-8", newline="") as fh:
    d.to_csv(fh, index=False)
print(len(d), d.pathway.nunique(), d.gene.nunique(), int(d.drop_duplicates("gene").in_list.sum()))
