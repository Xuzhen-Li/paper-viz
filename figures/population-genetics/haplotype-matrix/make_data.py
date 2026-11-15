"""Simulated phased haplotypes around a focal site for a sweep-style haplotype matrix.
Pop 1: most haplotypes carry the derived focal allele on a shared core haplotype, broken up by
recombination at random distances from the focal site; Pop 2: background haplotypes with a
few short core tracts. Fixed seed. Writes data.csv once (open 'x')."""
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261123)
n_sites, n_per_pop = 51, 40
pos = np.sort(rng.choice(np.arange(1000, 200000, 250), n_sites, replace=False))
focal = n_sites // 2
pos[focal] = 100000
bg = (rng.random((10, n_sites)) < 0.35).astype(int)
bg[:, focal] = 0
core = bg[0].copy()
core[focal] = 1


def background():
    h = bg[rng.integers(1, len(bg))].copy()
    flip = rng.random(n_sites) < 0.04
    h[flip] = 1 - h[flip]
    h[focal] = 0
    return h


def carrier(mean_kb):
    h = background()
    left = pos[focal] - rng.exponential(mean_kb * 1000)
    right = pos[focal] + rng.exponential(mean_kb * 1000)
    m = (pos >= left) & (pos <= right)
    h[m] = core[m]
    flip = (rng.random(n_sites) < 0.005) & m
    flip[focal] = False
    h[flip] = 1 - h[flip]
    return h


rows = []
for pop, p_carrier, mean_kb in [("Pop 1", 0.85, 70.0), ("Pop 2", 0.15, 20.0)]:
    for i in range(n_per_pop):
        h = carrier(mean_kb) if rng.random() < p_carrier else background()
        hap = f"{pop.replace(' ', '')}_Hap{i + 1:02d}"
        rows += [(hap, pop, f"Site {s + 1}", int(pos[s]), int(h[s])) for s in range(n_sites)]
d = pd.DataFrame(rows, columns=["hap", "pop", "site", "pos", "allele"])
with open("data.csv", "x", encoding="utf-8", newline="") as fh:
    d.to_csv(fh, index=False)
print(len(d), d.hap.nunique(), "focal", f"Site {focal + 1}", pos[focal])
