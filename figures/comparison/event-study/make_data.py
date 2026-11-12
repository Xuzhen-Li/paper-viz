"""Simulated balanced panel for an event-study example: unit fixed effects, a
common event at time 0, and a post-event rise in the outcome. Fixed seed.
Placeholder unit ids. Run: python3 make_data.py"""
import csv
import numpy as np

SEED = 20261133
rng = np.random.default_rng(SEED)
n_units = 80
times = np.arange(-5, 7)
# True event-time effects (time -1 is the omitted reference in the plot)
tau = {
    -5: 0.00, -4: 0.02, -3: -0.03, -2: 0.04, -1: 0.00,
    0: 0.18, 1: 0.42, 2: 0.63, 3: 0.74, 4: 0.80, 5: 0.83, 6: 0.84,
}
unit_fe = rng.normal(0.0, 0.70, n_units)

with open("data.csv", "x", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(["unit_id", "time", "y"])
    for i in range(n_units):
        for t in times:
            y = unit_fe[i] + tau[int(t)] + rng.normal(0.0, 0.55)
            w.writerow([i + 1, int(t), f"{y:.6f}"])
print("wrote data.csv")
