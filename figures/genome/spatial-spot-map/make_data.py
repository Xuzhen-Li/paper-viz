"""Simulated spatial spot map: spots on a hexagonal grid (100 um spacing) inside a tissue-like
outline, five generic regions (four wavy layers and small islands) and two feature channels.
Fixed seed. Writes data.csv once (open 'x')."""
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261121)
spacing = 100.0
cx, cy, r0 = 2600.0, 2600.0, 2350.0
rows = []
dy = spacing * np.sqrt(3) / 2
for j in range(int(5400 / dy)):
    y = j * dy
    for i in range(54):
        x = i * spacing + (spacing / 2 if j % 2 else 0.0)
        th = np.arctan2(y - cy, x - cx)
        r = r0 * (1 + 0.10 * np.sin(3 * th + 0.7) + 0.05 * np.cos(5 * th - 0.3))
        if np.hypot(x - cx, y - cy) <= r:
            rows.append((x, y))
xy = np.array(rows)
x, y = xy[:, 0], xy[:, 1]
f = y + 280 * np.sin(x / 850.0) + rng.normal(0, 70, len(x))
region = np.select([f > 3500, f > 2600, f > 1600], ["Region 1", "Region 2", "Region 3"], "Region 4")
islands = [(1500, 1300, 330), (3300, 900, 300), (3900, 2000, 260)]
for ix, iy, ir in islands:
    d = np.hypot(x - ix, y - iy) + rng.normal(0, 40, len(x))
    region = np.where(d < ir, "Region 5", region)
idx = {f"Region {k}": k for k in range(1, 6)}
k = np.array([idx[r] for r in region])
base_a = np.select([k == 3, k == 2, k == 4, k == 5], [3.2, 1.6, 1.0, 0.6], 0.4)
fa = np.clip(base_a + 0.0004 * (x - cx) + rng.normal(0, 0.45, len(x)), 0, None)
base_b = np.select([k == 5, k == 1], [2.6, 1.4], 0.5)
fb = np.clip(base_b + rng.normal(0, 0.35, len(x)), 0, None)
d = pd.DataFrame({
    "spot": [f"S{i + 1:04d}" for i in range(len(x))],
    "x_um": np.round(x, 1), "y_um": np.round(y, 1), "region": region,
    "feature_a": np.round(fa, 3), "feature_b": np.round(fb, 3),
})
with open("data.csv", "x", encoding="utf-8", newline="") as fh:
    d.to_csv(fh, index=False)
print(len(d), d.region.value_counts().sort_index().to_dict())
