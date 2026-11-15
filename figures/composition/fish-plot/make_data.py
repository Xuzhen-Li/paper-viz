"""Simulated clonal evolution: cancer cell fractions of 5 nested clones at 4 sampling times. Fixed seed-free (hand-set)."""
from pathlib import Path

import pandas as pd

time = [0, 120, 300, 520]
label = ["Diagnosis", "Remission", "Relapse 1", "Relapse 2"]
clones = {  # clone: (parent, fractions over time, cancer cell fraction including descendants)
    "C1": ("", [99, 15, 80, 99]),
    "C2": ("C1", [40, 8, 5, 3]),
    "C3": ("C1", [20, 4, 60, 30]),
    "C4": ("C3", [0, 1, 30, 10]),
    "C5": ("C1", [0, 0, 2, 60]),
}
rows = [(t, lab, c, p, f) for c, (p, fr) in clones.items() for t, lab, f in zip(time, label, fr)]
pd.DataFrame(rows, columns=["day", "timepoint", "clone", "parent", "ccf"]).to_csv(Path(__file__).resolve().parent / "data.csv", index=False)
