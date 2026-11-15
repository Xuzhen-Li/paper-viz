"""Accuracy-compute Pareto front (house style), v2: every model as a grey point, the models that no
other model beats with less compute in colour, joined by a step line and named. Reads data.csv
only. v2 (layout review 1-5, 2-3): the 2x2 +2 pt text bump is applied BEFORE the labels are placed,
so the overlap / inside-the-frame checks use the printed size; every name must sit >= 2 pt inside
the frame (so it cannot touch a spine, tick or tick label), clear of points and the step line, and
>= 2 pt from other text; "Dominated" is written next to the grey points. Run: python3 plot.py"""
import csv
import sys
from pathlib import Path

import numpy as np
from matplotlib.ticker import LogLocator, LogFormatterMathtext, NullLocator

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

# Parameters ---------------------------------------------------------------------------
x_label = "Training compute (FLOPs)"
y_label = "Benchmark accuracy (%)"
label_front = True              # write model names next to the frontier points
footnote = "Simulated data"
cells = "2x2"
label_size = 6                  # before the 2x2 bump (printed at label_size + bump)
inset_pt = 2.0                  # labels keep this distance inside the frame
text_gap_pt = 2.0               # minimum gap between two labels

rows = list(csv.DictReader(open("data.csv")))
name = np.array([r["model"] for r in rows])
x = np.array([float(r["flops"]) for r in rows])
y = np.array([float(r["accuracy"]) for r in rows])

# Pareto front: sorted by compute, keep a model if it beats every cheaper model
o = np.argsort(x)
front, best = [], -np.inf
for i in o:
    if y[i] > best:
        front.append(i)
        best = y[i]
front = np.array(front)
on = np.zeros(len(x), bool)
on[front] = True

grey = house.pv_palette("house_grey")
blue = house.pv_palette("house")[0]
house.apply_house_style()
fig, ax = house.house_figure(cells=cells)
ax.plot(x[~on], y[~on], ls="none", color=grey["light"], markerfacecolor=grey["light"],
        **{**house.POINT, "markeredgecolor": grey["dark"]}, zorder=2)
fx = np.repeat(x[front], 2)[1:]
fy = np.repeat(y[front], 2)[:-1]
fx = np.append(fx, x.max() * 2)
fy = np.append(fy, y[front][-1])
ax.plot(fx, fy, color=blue, lw=house.LW_PT["main"], zorder=3)
ax.plot(x[front], y[front], ls="none", color=blue, markerfacecolor=blue, **house.POINT, zorder=4)
ax.set_xscale("log")
ax.xaxis.set_major_locator(LogLocator(base=10, numticks=10))
ax.xaxis.set_major_formatter(LogFormatterMathtext())   # 9 pt ticks -> exponents 6.3 pt (checked in the PDF)
ax.xaxis.set_minor_locator(NullLocator())
ax.set_xlim(x.min() / 2.5, x.max() * 2)
ax.set_ylim(min(y) - 4, max(y) + 4)
ax.set_xlabel(x_label)
ax.set_ylabel(y_label)
fixed = [
    ax.text(0.97, 0.05, f"Pareto front: {len(front)} of {len(x)} models", transform=ax.transAxes,
            color=blue, ha="right", va="bottom"),
    ax.text(0.03, 0.97, footnote, transform=ax.transAxes, color=grey["mid"], fontsize=6, ha="left", va="top"),
]

# Typography bump first (same rule as save_house: +2 pt only for one data axes on a 2x2 canvas),
# then place the labels at their printed size. save_house is called with bump=0 below.
bump = 2.0 if house.house_cells(cells) == (2, 2) and len(fig.axes) == 1 else 0.0
house.bump_text(fig, bump)
fig.canvas.draw()
rend = fig.canvas.get_renderer()
px_pt = fig.dpi / 72
frame = ax.get_window_extent()
inner = (frame.x0 + inset_pt * px_pt, frame.y0 + inset_pt * px_pt, frame.x1 - inset_pt * px_pt, frame.y1 - inset_pt * px_pt)
pts = ax.transData.transform(np.column_stack([x, y]))
r_px = house.POINT["markersize"] / 2 * px_pt + 1
# the step line, sampled densely in display space (log x)
seg = []
for (xa, ya), (xb, yb) in zip(zip(fx[:-1], fy[:-1]), zip(fx[1:], fy[1:])):
    t = np.linspace(0, 1, 40)
    seg.append(ax.transData.transform(np.column_stack([np.exp(np.log(xa) + t * (np.log(xb) - np.log(xa))), ya + t * (yb - ya)])))
line_px = np.vstack(seg)
lw_px = house.LW_PT["main"] / 2 * px_pt + 0.5
placed = [t.get_window_extent(rend) for t in fixed]


def free(bb, point_pad=r_px):
    if not (inner[0] < bb.x0 and bb.x1 < inner[2] and inner[1] < bb.y0 and bb.y1 < inner[3]):
        return False
    # distance from each marker centre to the text box (0 inside) must exceed the marker radius
    ddx = np.maximum(np.maximum(bb.x0 - pts[:, 0], 0), pts[:, 0] - bb.x1)
    ddy = np.maximum(np.maximum(bb.y0 - pts[:, 1], 0), pts[:, 1] - bb.y1)
    if np.any(np.hypot(ddx, ddy) < point_pad):
        return False
    if np.any((line_px[:, 0] > bb.x0 - lw_px) & (line_px[:, 0] < bb.x1 + lw_px)
              & (line_px[:, 1] > bb.y0 - lw_px) & (line_px[:, 1] < bb.y1 + lw_px)):
        return False
    gap = text_gap_pt * px_pt          # names may not touch each other ("A-4B-4")
    return not any(bb.x0 - gap < o.x1 and o.x0 < bb.x1 + gap and bb.y0 - gap < o.y1 and o.y0 < bb.y1 + gap for o in placed)


cands = [(-3, 3, "right", "bottom"), (-5, 0, "right", "center"), (4, -3, "left", "top"),
         (0, 5, "center", "bottom"), (5, 0, "left", "center"), (0, -5, "center", "top"),
         (-3, -3, "right", "top"), (3, 3, "left", "bottom"), (-5, 5, "right", "bottom"),
         (5, -5, "left", "top"), (0, 8, "center", "bottom"), (0, -8, "center", "top")]
labels = []
if label_front:
    for i in front:
        for dx, dy, ha, va in cands:
            t = ax.annotate(name[i], (x[i], y[i]), xytext=(dx, dy), textcoords="offset points",
                            ha=ha, va=va, color=blue, fontsize=label_size + bump)
            bb = t.get_window_extent(rend)
            if free(bb):
                placed.append(bb)
                labels.append(t)
                break
            t.remove()
        else:
            raise SystemExit(f"no free spot for {name[i]}")

# "Dominated": next to the grey points (2-3). Try grey points nearest the centre of the grey cloud.
g = np.flatnonzero(~on)
gc = pts[g].mean(axis=0)
dom = None
for i in g[np.argsort(np.hypot(*(pts[g] - gc).T))]:
    for dx, dy, ha, va in [(5, 0, "left", "center"), (-5, 0, "right", "center"), (0, -5, "center", "top"), (0, 5, "center", "bottom")]:
        t = ax.annotate("Dominated", (x[i], y[i]), xytext=(dx, dy), textcoords="offset points",
                        ha=ha, va=va, color=grey["mid"], fontsize=7 + bump)
        bb = t.get_window_extent(rend)
        if free(bb):
            placed.append(bb)
            dom = t
            break
        t.remove()
    if dom is not None:
        break
if dom is None:
    raise SystemExit("no free spot for Dominated")

house.save_house(fig, "figure", bump=0)

# Re-check after the final layout pass inside save_house (constrained layout may move the frame)
rend = fig.canvas.get_renderer()
frame = ax.get_window_extent()
ticks = [t.get_window_extent(rend) for t in ax.get_xticklabels() + ax.get_yticklabels() if t.get_visible() and t.get_text()]
worst = np.inf
for t in labels + [dom]:
    bb = t.get_window_extent(rend)
    gap = min(bb.x0 - frame.x0, frame.x1 - bb.x1, bb.y0 - frame.y0, frame.y1 - bb.y1) / px_pt
    worst = min(worst, gap)
    assert gap >= inset_pt - 0.01, (t.get_text(), gap)
    assert not any(bb.overlaps(k) for k in ticks), t.get_text()
print(f"labels: {len(labels)} + Dominated; min gap to frame {worst:.2f} pt; label size {label_size + bump} pt")
print("wrote figure.pdf, figure.png, preview.png")
