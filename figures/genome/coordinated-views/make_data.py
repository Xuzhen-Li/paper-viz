"""Simulated cells for a coordinated multi-view figure: each cell has a cluster, a 2-D
embedding position, a spatial position and expression of 10 generic genes. Fixed seed.
Writes data.csv once (open 'x')."""
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261122)
n = 1000
k = 6
genes = [f"Gene {c}" for c in "ABCDEFGHIJ"]
# spatial domains on a 2400 x 2000 um field: cluster = nearest domain seed (with noise)
seeds = np.array([[360, 1550], [1040, 1650], [1960, 1500], [560, 500], [1320, 650], [2040, 450]])
xy = np.column_stack([rng.uniform(0, 2400, n), rng.uniform(0, 2000, n)])
dist = np.linalg.norm(xy[:, None, :] - seeds[None, :, :], axis=2) + rng.normal(0, 120, (n, k))
cl = dist.argmin(1)
# embedding: cluster centres + noise (two loose super-groups)
centres = np.array([[-6, 4], [-3, 6.5], [0.5, 5], [-5, -3], [1, -4.5], [5.5, -1]])
emb = centres[cl] + rng.normal(0, 0.9, (n, 2)) * np.array([1.0, 0.8])
# expression: log-normalised, two marker genes per cluster, one shared gene
mean = np.full((k, len(genes)), 0.4)
markers = {0: [0, 1], 1: [1, 2], 2: [3, 4], 3: [5, 6], 4: [7, 6], 5: [8, 9]}
for c, gi in markers.items():
    mean[c, gi[0]] = 2.6
    mean[c, gi[1]] = 1.6
expr = np.clip(mean[cl] + rng.normal(0, 0.55, (n, len(genes))), 0, None)
d = pd.DataFrame({"cell": [f"C{i + 1:04d}" for i in range(n)], "cluster": [f"Cluster {c + 1}" for c in cl],
                  "emb_1": emb[:, 0].round(3), "emb_2": emb[:, 1].round(3),
                  "x_um": xy[:, 0].round(1), "y_um": xy[:, 1].round(1)})
for j, g in enumerate(genes):
    d[g] = expr[:, j].round(2)
with open("data.csv", "x", encoding="utf-8", newline="") as fh:
    d.to_csv(fh, index=False)
print(len(d), d.cluster.value_counts().sort_index().to_dict())
