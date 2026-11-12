"""Simulated right-censored survival times for three groups. Event=1 is an
observed event; Event=0 is right-censoring (dropout or administrative end at
36 months). Group names are placeholders. Run: python3 make_data.py"""
from pathlib import Path

import numpy as np
import csv

SEED = 20261121
rng = np.random.default_rng(SEED)

groups = {
    "Control": 0.045,
    "Treatment A": 0.028,
    "Treatment B": 0.018,
}
n_per = 90
admin = 36.0

rows = []
for g, rate in groups.items():
    # exponential event times, uniform dropout, administrative censor at 36 mo
    event_t = rng.exponential(1.0 / rate, n_per)
    drop_t = rng.uniform(8.0, 40.0, n_per)
    obs = np.minimum(np.minimum(event_t, drop_t), admin)
    event = ((event_t <= drop_t) & (event_t <= admin)).astype(int)
    for i, (t, e) in enumerate(zip(obs, event), start=1):
        rows.append({"subject": f"{''.join(w[0] for w in g.split())}{i:03d}", "group": g, "time": f"{t:.3f}", "event": int(e)})

out = Path(__file__).with_name("data.csv")
with out.open("x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["subject", "group", "time", "event"])
    w.writeheader()
    w.writerows(rows)
print("wrote data.csv")
