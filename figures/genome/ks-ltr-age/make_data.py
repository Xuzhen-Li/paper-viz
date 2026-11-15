# Simulated synonymous divergence (Ks) of gene pairs and LTR-LTR divergence (K) of intact LTR
# retrotransposons. Writes data.csv: panel (ks / ltr), group, value.
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261117)
para = np.r_[rng.lognormal(np.log(0.26), 0.25, 700),       # recent whole-genome duplication
             rng.lognormal(np.log(1.55), 0.18, 900),       # older shared duplication
             rng.exponential(0.6, 350)]                    # small-scale duplicates
orth = rng.lognormal(np.log(0.75), 0.15, 1300)
gyp = rng.gamma(2.2, 0.0075, 900)                          # K2P distance between the two LTRs
cop = rng.gamma(1.6, 0.0130, 650)
rows = ([("ks", "Paralogs (species A)", v) for v in para[para < 3]] +
        [("ks", "Orthologs (A vs B)", v) for v in orth[orth < 3]] +
        [("ltr", "Gypsy", v) for v in gyp] + [("ltr", "Copia", v) for v in cop])
pd.DataFrame(rows, columns=["panel", "group", "value"]).round({"value": 4}).to_csv("data.csv", index=False)
