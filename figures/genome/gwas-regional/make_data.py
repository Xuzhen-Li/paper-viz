# Simulated association signal in one 800 kb region: SNP -log10(P) with r^2 to the lead SNP,
# a recombination-rate track and a gene track. Writes data.csv (long table, column `track`).
import numpy as np
import pandas as pd

rng = np.random.default_rng(20261114)
lo, hi, lead_pos = 30_000_000, 30_800_000, 30_421_350
n = 420
pos = np.sort(rng.integers(lo, hi, n)); pos[np.argmin(abs(pos - lead_pos))] = lead_pos
dist = np.abs(pos - lead_pos)
r2 = np.clip(np.exp(-dist / 45_000) * rng.beta(4, 2, n) + rng.beta(1, 12, n) * 0.3, 0, 1)
r2[pos == lead_pos] = 1.0
mlogp = 11.6 * r2 ** 1.3 + rng.exponential(0.45, n)
mlogp[pos == lead_pos] = 11.7
snp = pd.DataFrame({"track": "snp", "name": [f"snp{i + 1:03d}" for i in range(n)], "start": pos, "end": pos,
                    "strand": "", "value": mlogp.round(3), "r2": r2.round(3)})

rx = np.linspace(lo, hi, 161)
rate = 0.4 + rng.gamma(1.2, 0.35, rx.size)
for h, w, amp in [(30_180_000, 8_000, 38), (30_512_000, 6_000, 52), (30_690_000, 9_000, 26)]:
    rate += amp * np.exp(-0.5 * ((rx - h) / w) ** 2)
rec = pd.DataFrame({"track": "recomb", "name": "", "start": rx.astype(int), "end": rx.astype(int),
                    "strand": "", "value": rate.round(3), "r2": np.nan})

genes = [("gene01", 30_030_000, 30_078_000, "+"), ("gene02", 30_120_000, 30_165_000, "-"),
         ("gene03", 30_230_000, 30_262_000, "+"), ("gene04", 30_300_000, 30_390_000, "+"),
         ("gene05", 30_405_000, 30_446_000, "-"), ("gene06", 30_470_000, 30_500_000, "+"),
         ("gene07", 30_560_000, 30_640_000, "-"), ("gene08", 30_700_000, 30_770_000, "+")]
gen = pd.DataFrame([{"track": "gene", "name": g, "start": s, "end": e, "strand": st, "value": np.nan,
                     "r2": np.nan} for g, s, e, st in genes])
pd.concat([snp, rec, gen]).to_csv("data.csv", index=False)
