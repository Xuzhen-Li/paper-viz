"""Simulated linear graph-pangenome: a 100 kb reference backbone with 10 bubbles (SNV,
insertion, deletion, multi-allelic divergent site) and the allele each of 8 paths takes
through every bubble (Path 1 = reference). Fixed seed. Writes data.csv once (open 'x')."""
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261124)
types = ["SNV", "insertion", "deletion", "divergent", "insertion",
         "SNV", "deletion", "insertion", "divergent", "SNV"]
pos = np.round(np.linspace(6, 94, len(types)) + rng.uniform(-2, 2, len(types)), 2)
rows = []
n_alle = {}
for b, (t, p) in enumerate(zip(types, pos), start=1):
    bid = f"B{b}"
    if t == "SNV":
        alle = [(0, 1), (1, 1)]
    elif t == "insertion":
        alle = [(0, 0), (1, int(rng.integers(3, 60)) * 100)]
    elif t == "deletion":
        L = int(rng.integers(5, 30)) * 100
        alle = [(0, L), (1, 0)]
    else:
        alle = [(0, int(rng.integers(8, 20)) * 100), (1, int(rng.integers(3, 25)) * 100),
                (2, int(rng.integers(3, 25)) * 100)]
    n_alle[bid] = len(alle)
    rows += [("bubble", bid, t, p, a, L_, "") for a, L_ in alle]
n_paths = 8
for k in range(1, n_paths + 1):
    for b in range(1, len(types) + 1):
        bid = f"B{b}"
        if k == 1:
            a = 0
        elif n_alle[bid] == 2:
            a = int(rng.random() < rng.uniform(0.25, 0.7))
        else:
            a = int(rng.choice(3, p=[0.4, 0.35, 0.25]))
        rows.append(("path", bid, "", "", a, "", f"Path {k}"))
d = pd.DataFrame(rows, columns=["record", "bubble", "type", "pos_kb", "allele", "length_bp", "path"])
with open("data.csv", "x", encoding="utf-8", newline="") as fh:
    d.to_csv(fh, index=False)
print(len(d), dict(zip([f"B{i + 1}" for i in range(len(types))], types)))
