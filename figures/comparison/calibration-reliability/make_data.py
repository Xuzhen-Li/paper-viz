import numpy as np, csv
rng = np.random.default_rng(20261113)
rows = []
for model, bend in [("Pretrained", 0.0), ("After preference tuning", 0.35)]:
    for _ in range(4000):
        p = rng.beta(2.2, 1.4)
        q = np.clip(p - bend * (p - 0.25) * (p > 0.25) + rng.normal(0, 0.02), 0.01, 0.99)
        rows.append({"model": model, "confidence": round(p, 4), "correct": int(rng.random() < q)})
with open("data.csv", "x", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
