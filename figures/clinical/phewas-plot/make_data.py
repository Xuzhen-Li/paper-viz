"""Simulated PheWAS of one variant: 1,400 phecodes in 14 categories, two-sided P and effect direction. Fixed seed."""
from pathlib import Path

import numpy as np
import pandas as pd

rng = np.random.default_rng(47)
cats = ["Infectious", "Neoplasms", "Endocrine", "Haematologic", "Mental", "Neurological", "Sense organs",
        "Circulatory", "Respiratory", "Digestive", "Genitourinary", "Dermatologic", "Musculoskeletal", "Injuries"]
rows = []
for ci, c in enumerate(cats):
    k = int(rng.integers(70, 130))
    p = rng.uniform(0, 1, k) ** 1.05
    beta = rng.normal(0, 0.05, k)
    for j in range(k):
        rows.append((f"{ci * 50 + 8 + j * 0.3:.1f}", f"{c} phenotype {j + 1}", c, p[j], beta[j]))
df = pd.DataFrame(rows, columns=["phecode", "phenotype", "category", "p", "beta"])
hits = {"Endocrine": [(1e-14, 0.31, "Type 2 diabetes"), (3e-9, 0.18, "Obesity")],
        "Circulatory": [(2e-7, 0.12, "Hypertension")],
        "Digestive": [(4e-6, -0.15, "Gallstones")]}
for c, hs in hits.items():
    idx = df.index[df.category == c][:len(hs)]
    for i, (p, b, name) in zip(idx, hs):
        df.loc[i, ["p", "beta", "phenotype"]] = [p, b, name]
df["p"] = df.p.map(lambda v: float(f"{v:.4g}")); df["beta"] = df.beta.round(4)
df.to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
