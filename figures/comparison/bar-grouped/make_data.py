#!/usr/bin/env python3
"""Simulated grouped means. Writes data.csv."""
import csv

rows = [
    ("A", "Control", 3.1),
    ("B", "Control", 2.4),
    ("C", "Control", 4.0),
    ("D", "Control", 2.9),
    ("A", "Treatment", 4.2),
    ("B", "Treatment", 3.5),
    ("C", "Treatment", 4.8),
    ("D", "Treatment", 3.7),
]
with open("data.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["group", "series", "value"])
    w.writerows(rows)
print("wrote data.csv")
