"""Simulated case-level predicted risks and binary outcomes for two models.
Fixed seed. Placeholder model names. Run: python3 make_data.py"""
import csv
import numpy as np

SEED = 20261129
N = 800
rng = np.random.default_rng(SEED)

# Latent risk; event rate near 0.30
logit_true = rng.normal(-0.85, 1.15, N)
p_true = 1.0 / (1.0 + np.exp(-logit_true))
y = (rng.random(N) < p_true).astype(int)

# Model A: well calibrated, good discrimination
logit_a = logit_true + rng.normal(0.0, 0.45, N)
p_a = np.clip(1.0 / (1.0 + np.exp(-logit_a)), 1e-4, 1 - 1e-4)

# Model B: noisier and somewhat over-confident (shifted and stretched)
logit_b = 1.15 * logit_true + 0.35 + rng.normal(0.0, 1.05, N)
p_b = np.clip(1.0 / (1.0 + np.exp(-logit_b)), 1e-4, 1 - 1e-4)

out = "data.csv"
with open(out, "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["case_id", "outcome", "model", "predicted_risk"])
    for i in range(N):
        w.writerow([i + 1, int(y[i]), "Model A", f"{p_a[i]:.6f}"])
        w.writerow([i + 1, int(y[i]), "Model B", f"{p_b[i]:.6f}"])
print("wrote data.csv")
