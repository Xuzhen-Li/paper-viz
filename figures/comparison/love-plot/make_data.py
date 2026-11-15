"""Simulated observational sample: treatment assigned from a true propensity score
that depends on some covariates (confounding). The propensity score is then
re-estimated by logistic regression on all covariates (Newton-Raphson, numpy only)
and turned into stabilized inverse-probability weights. Fixed seed; placeholder
covariate names. Run: python3 make_data.py  (writes data.csv; fails if it exists)"""
import csv
import numpy as np

SEED = 20261132
rng = np.random.default_rng(SEED)
N = 1000

cont_names = ["Score A", "Score B", "Index C", "Measure D", "Level E", "Amount F", "Rate G", "Ratio H"]
bin_names = ["Flag I", "Flag J", "Status K", "Indicator L"]
Xcont = rng.normal(0.0, 1.0, size=(N, len(cont_names)))
Xbin = np.column_stack([rng.binomial(1, p, N) for p in (0.30, 0.50, 0.22, 0.45)]).astype(float)
X = np.column_stack([Xcont, Xbin])

beta_true = np.array([0.60, 0.45, 0.70, 0.20, 0.0, 0.50, 0.10, 0.0, 0.55, 0.0, 0.40, 0.0])
lin = -0.55 + X @ beta_true
treated = (rng.random(N) < 1.0 / (1.0 + np.exp(-lin))).astype(int)

# estimated propensity score: logistic regression on all covariates
Z = np.column_stack([np.ones(N), X])
b = np.zeros(Z.shape[1])
for _ in range(50):
    p = 1.0 / (1.0 + np.exp(-Z @ b))
    step = np.linalg.solve(Z.T @ (Z * (p * (1 - p))[:, None]), Z.T @ (treated - p))
    b += step
    if np.max(np.abs(step)) < 1e-10:
        break
ps = 1.0 / (1.0 + np.exp(-Z @ b))
pbar = treated.mean()
w = np.where(treated == 1, pbar / ps, (1.0 - pbar) / (1.0 - ps))   # stabilized ATE weights

with open("data.csv", "x", newline="") as fh:
    wr = csv.writer(fh)
    wr.writerow(["unit_id", "treated", "weight"] + cont_names + bin_names)
    for i in range(N):
        wr.writerow([i + 1, int(treated[i]), f"{w[i]:.6f}"]
                    + [f"{Xcont[i, j]:.6f}" for j in range(len(cont_names))]
                    + [f"{int(Xbin[i, j])}" for j in range(len(bin_names))])
print("wrote data.csv")
