# Simulated gene-family expansion / contraction counts on a dated species tree (8 species), the kind
# of table a birth-death analysis of family sizes reports per branch. Writes data.csv (one row per node).
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261118)
# node, parent, age (Mya); tips have age 0
nodes = [("root", "", 120), ("n1", "root", 90), ("n2", "n1", 62), ("n3", "n2", 24), ("n4", "n1", 41),
         ("n5", "root", 78), ("n6", "n5", 31),
         ("Species A", "n3", 0), ("Species B", "n3", 0), ("Species C", "n2", 0), ("Species D", "n4", 0),
         ("Species E", "n4", 0), ("Species F", "n6", 0), ("Species G", "n6", 0), ("Species H", "n5", 0)]
age = {n: a for n, _, a in nodes}
rows = []
for n, p, a in nodes:
    L = age[p] - a if p else 0
    exp_ = int(rng.poisson(6 + 9 * L)) if p else 0
    con = int(rng.poisson(4 + 14 * L)) if p else 0
    tip = a == 0
    if n == "Species C":
        exp_ += 900                                  # one lineage with a burst of expansions
    rows.append({"node": n, "parent": p, "age": a, "expanded": exp_, "contracted": con,
                 "rapid_expanded": int(rng.poisson(0.06 * exp_)) if tip else "",
                 "rapid_contracted": int(rng.poisson(0.04 * con)) if tip else ""})
pd.DataFrame(rows).to_csv("data.csv", index=False)
