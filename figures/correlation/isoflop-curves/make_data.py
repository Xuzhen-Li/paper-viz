# Simulated IsoFLOP sweep. Fixed seed 20261113.
# Loss uses a Chinchilla-style parametric form L = E + A/N^alpha + B/D^beta
# whose constants (E=1.69, A=406.4, B=410.7, alpha=0.34, beta=0.28) are those
# reported by Hoffmann et al. 2022 (arXiv:2203.15556); points are simulated
# plus Gaussian noise, not published data points.
import numpy as np, csv
rng = np.random.default_rng(20261113)
E, A, B, a, b = 1.69, 406.4, 410.7, 0.34, 0.28
rows = []
for C in [6e18, 3e19, 1e20, 6e20, 3e21]:
    Nopt = 0.6 * (C / 6) ** 0.5
    for N in np.exp(np.linspace(np.log(Nopt / 12), np.log(Nopt * 12), 11)):
        D = C / (6 * N)
        L = E + A / N ** a + B / D ** b + rng.normal(0, 0.008)
        rows.append({"compute_flops": f"{C:.3g}", "params": f"{N:.4g}", "tokens": f"{D:.4g}", "loss": f"{L:.4f}"})
with open("data.csv", "x", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
