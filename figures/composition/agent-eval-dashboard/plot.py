"""Agent evaluation dashboard (house style), three panels from one table (data.csv):
a  accuracy vs total API cost per run (log x), Pareto front = agents no other agent beats on both
   lower cost and higher accuracy; b  mean cost per run split into prompt / completion /
   retry-and-tool parts, stacked so the parts sum to the printed total; c  accuracy per agent,
   mean of runs with a 95% Student t interval (df = runs - 1) and the individual runs.
v2: panel-a labels for Retry x3, Retry x5, Tree search, Debate x3, Self-reflect and Planner-executor
moved clear of the grey CI bars, points and Pareto line; data, seed, CIs, costs and front unchanged.
Simulated data. Run from this directory: python3 plot.py"""
import csv
import sys
from pathlib import Path

import matplotlib as mpl
import numpy as np
from matplotlib.ticker import FixedLocator, FuncFormatter, NullLocator
from scipy import stats

HERE = Path(__file__).resolve().parent
STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

# Parameters ---------------------------------------------------------------------------
cells = "4x2"                     # 183 x 89 mm
conf_level = 0.95
footnote = "Simulated data"
pal = house.pv_palette("house")
grey = house.pv_palette("house_grey")
part_cols = {"cost_prompt_usd": pal[0], "cost_completion_usd": pal[1], "cost_retry_tool_usd": pal[2]}
part_names = {"cost_prompt_usd": "Prompt", "cost_completion_usd": "Completion", "cost_retry_tool_usd": "Retry / tool"}
front_col, front_text = pal[0], "#1F72AE"
# label offsets (points) for panel a, by agent; (dx, dy, ha). Tuned for this data.csv so every label
# clears the grey CI bars, the points and the Pareto line; crowded agents sit at an end of their own CI bar.
offsets = {
    "Single call": (4, 5, "left"), "Retry x3": (-6, 0, "right"), "Retry x5": (4, -7, "left"),
    "Escalate model": (-4, 3, "right"), "Self-reflect": (0, 33, "center"), "Debate x3": (4, -25, "left"),
    "Tree search": (12, 37, "right"), "Planner-executor": (0, -28, "center"),
}


def lum(c):
    f = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = mpl.colors.to_rgb(c)
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(a, b="#FFFFFF"):
    x, y = sorted([lum(a), lum(b)], reverse=True)
    return (x + 0.05) / (y + 0.05)


def usd(v, _=None):
    return f"{v:g}"


# Data ---------------------------------------------------------------------------------
with open(HERE / "data.csv", newline="") as fh:
    rows = list(csv.DictReader(fh))
agents = list(dict.fromkeys(r["agent"] for r in rows))
parts = list(part_cols)
S = {}
for a in agents:
    rr = [r for r in rows if r["agent"] == a]
    acc = np.array([int(r["n_solved"]) / int(r["n_tasks"]) for r in rr]) * 100
    cost = {p: np.array([float(r[p]) for r in rr]) for p in parts}
    total = sum(cost.values())
    k = len(rr)
    tq = stats.t.ppf(0.5 + conf_level / 2, df=k - 1)
    half = tq * acc.std(ddof=1) / np.sqrt(k)
    S[a] = dict(acc=acc, mean=acc.mean(), half=half, tq=tq, runs=k,
                tasks=sorted({int(r["n_tasks"]) for r in rr}),
                part_mean={p: cost[p].mean() for p in parts}, total=total.mean())
runs = sorted({S[a]["runs"] for a in agents})
tasks = sorted({t for a in agents for t in S[a]["tasks"]})
assert len(runs) == 1 and len(tasks) == 1, (runs, tasks)
n_runs, n_tasks = runs[0], tasks[0]
for a in agents:   # stacked parts must sum to the printed total
    assert abs(sum(S[a]["part_mean"].values()) - S[a]["total"]) < 1e-9

# Pareto front: sort by cost; keep agents whose accuracy beats every cheaper agent
order_cost = sorted(agents, key=lambda a: S[a]["total"])
front, best = [], -np.inf
for a in order_cost:
    if S[a]["mean"] > best:
        front.append(a)
        best = S[a]["mean"]
order_acc = sorted(agents, key=lambda a: S[a]["mean"])   # bottom -> top in b, c

# Figure -------------------------------------------------------------------------------
house.apply_house_style()
fig, (ax_a, ax_b, ax_c) = house.house_figure(cells=cells, ncols=3, gridspec_kw={"width_ratios": [1.3, 1.0, 0.8]})

# a  Pareto
x = np.array([S[a]["total"] for a in agents])
y = np.array([S[a]["mean"] for a in agents])
fx = [S[a]["total"] for a in front]
fy = [S[a]["mean"] for a in front]
ax_a.step(fx + [x.max() * 1.6], fy + [fy[-1]], where="post", color=front_col, lw=house.LW_PT["minor"], zorder=2)
for a in agents:
    on = a in front
    ax_a.errorbar(S[a]["total"], S[a]["mean"], yerr=S[a]["half"], fmt="none",
                  ecolor=grey["ref"], elinewidth=house.LW_PT["errorbar"], capsize=0, zorder=2)
    ax_a.plot(S[a]["total"], S[a]["mean"], ls="none", marker="o", ms=house.POINT["markersize"],
              mew=house.POINT["markeredgewidth"], mec="#000000", mfc=front_col if on else grey["ci"], zorder=3)
    dx, dy, ha = offsets[a]
    ax_a.annotate(a, (S[a]["total"], S[a]["mean"]), xytext=(dx, dy), textcoords="offset points",
                  ha=ha, va="center", fontsize=6.5, color=front_text if on else grey["mid"])
ax_a.set_xscale("log")
ax_a.set_xlim(x.min() / 1.6, x.max() * 1.6)
ax_a.xaxis.set_major_locator(FixedLocator([0.1, 0.3, 1, 3, 10]))
ax_a.xaxis.set_minor_locator(NullLocator())
ax_a.xaxis.set_major_formatter(FuncFormatter(usd))
ax_a.set_xlabel("Mean total cost per run (USD, log scale)")
ax_a.set_ylabel("Accuracy (% tasks solved)")
ylo = min(S[a]["mean"] - S[a]["half"] for a in agents)
yhi = max(S[a]["mean"] + S[a]["half"] for a in agents)
ax_a.set_ylim(ylo - 3, yhi + 2.5)
ax_a.text(0.97, 0.05, f"Blue: Pareto front ({len(front)} agents)\nGrey: dominated\nBars: {int(conf_level*100)}% t CI\n{footnote}",
          transform=ax_a.transAxes, ha="right", va="bottom", fontsize=6, color=grey["mid"], linespacing=1.15)
house.add_house_tag(ax_a, "a")

# b  stacked cost breakdown
yy = np.arange(len(order_acc))
left = np.zeros(len(order_acc))
for p in parts:
    v = np.array([S[a]["part_mean"][p] for a in order_acc])
    ax_b.barh(yy, v, left=left, height=0.7, color=part_cols[p], edgecolor="white", lw=0.3, label=part_names[p])
    left += v
tot = np.array([S[a]["total"] for a in order_acc])
for i, t in enumerate(tot):
    ax_b.text(t + tot.max() * 0.02, i, f"{t:.2f}", va="center", ha="left", fontsize=6.5)
ax_b.set_yticks(yy)
ax_b.set_yticklabels(order_acc)
ax_b.set_ylim(-0.6, len(order_acc) - 0.4)
ax_b.set_xlim(0, tot.max() * 1.22)
ax_b.set_xlabel("Mean cost per run (USD)")
ax_b.tick_params(axis="y", length=0)
ax_b.text(0.97, 0.40, "Stacked parts sum to\nthe printed total", transform=ax_b.transAxes, ha="right", va="top",
          fontsize=6, color=grey["mid"])
ax_b.legend(loc="center right", bbox_to_anchor=(1.0, 0.56), fontsize=6.5, handlelength=1.2, handleheight=0.9,
            labelspacing=0.3, borderaxespad=0.4, title="Cost part", title_fontsize=6.5, alignment="right")
house.add_house_tag(ax_b, "b")

# c  accuracy with t CI
for i, a in enumerate(order_acc):
    jit = np.linspace(-0.18, 0.18, S[a]["runs"])
    ax_c.plot(S[a]["acc"], i + jit, ls="none", marker="o", ms=1.6, mew=0, mfc=grey["ref"], zorder=1)   # #757575: >= 4.5:1 on white
    ax_c.plot([S[a]["mean"] - S[a]["half"], S[a]["mean"] + S[a]["half"]], [i, i], color="#000000",
              lw=house.LW_PT["errorbar"] * 1.4, zorder=2, solid_capstyle="butt")
    ax_c.plot(S[a]["mean"], i, ls="none", marker="o", ms=house.POINT["markersize"],
              mew=house.POINT["markeredgewidth"], mec="#000000", mfc=front_col if a in front else "white", zorder=3)
ax_c.set_yticks(yy)
ax_c.set_yticklabels([])
ax_c.tick_params(axis="y", length=0)
ax_c.set_ylim(-0.6, len(order_acc) - 0.4)
lo = min(S[a]["acc"].min() for a in agents)
hi = max(S[a]["acc"].max() for a in agents)
ax_c.set_xlim(lo - 13, hi + 2)
ax_c.set_xlabel("Accuracy (%)")
tq = S[agents[0]]["tq"]
ax_c.text(0.04, 0.97, f"Dot: mean of runs\nLine: {int(conf_level*100)}% CI,\nStudent t, df = {n_runs - 1}\n(t = {tq:.3f})\n"
          f"Blue fill: Pareto front\nGrey: single runs\nn = {n_runs} runs x\n{n_tasks} tasks per agent",
          transform=ax_c.transAxes, ha="left", va="top", fontsize=6, color=grey["mid"], linespacing=1.15)
house.add_house_tag(ax_c, "c")

house.save_house(fig, HERE / "figure", bump=0)

# Report -------------------------------------------------------------------------------
print("agents:", len(agents), "runs:", n_runs, "tasks/run:", n_tasks, "t:", round(tq, 4))
print("front:", front)
for a in order_acc[::-1]:
    print(f"  {a:18s} acc {S[a]['mean']:.2f} +/- {S[a]['half']:.2f}  total {S[a]['total']:.4f}")
for c in sorted({front_text, grey["mid"], "#000000"}):
    print("text contrast on white", c, round(contrast(c), 2))
