"""Training-accuracy curve (house style): benchmark accuracy of a policy across RL training
steps, as pass@1 (share of correct answers among k samples, averaged over problems) and
majority vote over the same k samples; a fixed reference model's two scores are dashed
horizontal lines in the matching colours. Direct labels inside the frame, no legend box.
Single 2x2 panel: the +2 pt bump is applied up front (9 pt ticks, 10 pt axis titles), labels
are placed at printed size, then save_house(bump=0). Reads data.csv only. Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np

def _find_styles():
    here = Path(__file__).resolve()
    cands = []
    if len(here.parents) > 3:
        cands.append(here.parents[3] / "styles" / "python")   # future figures/<cat>/<slug>/ layout
    for c in cands:
        if (c / "house.py").is_file():
            return c
    raise FileNotFoundError("styles/python/house.py not found; tried " + ", ".join(map(str, cands)))


sys.path.insert(0, str(_find_styles()))
import house  # noqa: E402

HERE = Path(__file__).resolve().parent
CELLS = (2, 2)                    # 89 x 89 mm, single panel
X_LABEL = "Training step"
Y_LABEL = "Accuracy (%)"
FS_LAB = 7.5
FS_NOTE = 6.5

rows = list(csv.DictReader(open(HERE / "data.csv")))
pol = [r for r in rows if r["step"] != ""]
ref = [r for r in rows if r["step"] == ""]
policy = pol[0]["model"]
ref_name = ref[0]["model"]
steps = np.array(sorted({int(r["step"]) for r in pol}))
problems = sorted({r["problem"] for r in rows})
n_problems = len(problems)
k_vals = {int(r["n_samples"]) for r in rows}
assert len(k_vals) == 1, "plot assumes one k for every row"
k = k_vals.pop()


def acc(rs):
    p1 = 100 * np.mean([int(r["n_correct"]) / int(r["n_samples"]) for r in rs])
    mv = 100 * np.mean([int(r["majority_correct"]) for r in rs])
    return p1, mv


curve = np.array([acc([r for r in pol if int(r["step"]) == s]) for s in steps])
ref_p1, ref_mv = acc(ref)

hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
c_p1, c_mv = hp[0], hp[3]          # blue #1F72AE, red #CC312C: both >= 4.5:1 on white as text
ink = "#1A1A1A"

house.apply_house_style(single_panel=True)
fig, ax = house.house_figure(cells=CELLS)
for j, (c, lab) in enumerate(((c_p1, "pass@1"), (c_mv, "Majority vote"))):
    ax.plot(steps, curve[:, j], color=c, lw=house.LW_PT["main"], zorder=3)
    ax.plot(steps, curve[:, j], ls="none", color=c, markerfacecolor=c, zorder=4, **house.POINT)
for yv, c in ((ref_p1, c_p1), (ref_mv, c_mv)):
    ax.axhline(yv, color=c, lw=house.LW_PT["minor"], ls=(0, (4, 2)), zorder=2)
# key block in the empty lower-right corner: coloured direct labels, no legend box
key = [
    (f"Majority vote of {k} samples", c_mv, FS_LAB),
    (f"pass@1, mean of {k} samples", c_p1, FS_LAB),
    (f"Dashed: {ref_name}, majority vote {ref_mv:.1f}", c_mv, FS_NOTE),
    (f"Dashed: {ref_name}, pass@1 {ref_p1:.1f}", c_p1, FS_NOTE),
]
yk = 0.15
for txt, c, fs in key[::-1]:
    ax.text(0.97, yk, txt, transform=ax.transAxes, color=c, fontsize=fs, ha="right", va="bottom")
    yk += 0.052 if fs == FS_NOTE else 0.06
ax.text(0.97, 0.03, f"Simulated data; {n_problems} problems,\n{k} samples per checkpoint", transform=ax.transAxes,
        color=grey["mid"], fontsize=FS_NOTE, ha="right", va="bottom", linespacing=1.15)
ax.set_xlim(-250, steps.max() + 250)
ax.set_ylim(0, 100)
ax.set_xticks(np.arange(0, steps.max() + 1, 2000))
ax.set_xlabel(X_LABEL)
ax.set_ylabel(Y_LABEL)
house.save_house(fig, HERE / "figure", bump=0)
print(f"n_problems = {n_problems}; k = {k}; checkpoints = {len(steps)}; final pass@1 = {curve[-1, 0]:.1f}, "
      f"majority = {curve[-1, 1]:.1f}; {ref_name} pass@1 = {ref_p1:.1f}, majority = {ref_mv:.1f}")
