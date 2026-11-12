"""Scaling-envelope mosaic (house style). Simulated data; reads data.csv only.
a: training-curve envelope (minimum loss per FLOP over all runs); b: isoFLOP curves with fitted minima;
c: compute-optimal model size from both approaches, power-law fits, and extrapolation to a larger budget.
v2: panel c target-budget dashed line now stops above the lower-right footnote (gap >= 1 mm);
data, seed, fits and printed numbers unchanged.
Run from this directory: python plot.py"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib.ticker import FixedLocator, FuncFormatter, NullFormatter
from matplotlib.transforms import blended_transform_factory

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "4x2"
target_flops = 1e24            # extrapolation target (illustrative)
fit_range = (1e18, 1e21)       # FLOP range used for the envelope fit
footnote = "Simulated data"
line_gap_mm = 1.0             # clear space between the target line's lower end and the panel-c footnote

house.apply_house_style()
hp = house.pv_palette("house")
grey = house.pv_palette("house_grey")
C_ENV, C_ISO = hp[0], hp[1]                 # #1F72AE envelope, #F77E12 isoFLOP (points / lines)
T_ENV, T_ISO = "#1F72AE", "#B95E0E"         # text colours (dark variant for #F77E12)
RUN_GREY = "#8C8C8C"

d = pd.read_csv(Path(__file__).with_name("data.csv"))
runs = d[d.kind == "run"].copy()
iso = d[d.kind == "isoflop"].copy()
runs["flops"] = 6 * runs.params * runs.tokens
iso["flops"] = iso.budget_flops
n_runs = runs.run_id.nunique()
n_sizes = runs.params.nunique()
n_cycles = runs.groupby("params").cycle_tokens.nunique().max()
budgets = sorted(iso.budget_flops.unique())
n_budgets = len(budgets)
n_iso_pts = len(iso)


def sci(v):
    """1e19-style plain-text label (no mathtext)."""
    e = int(np.floor(np.log10(v) + 1e-9))
    m = v / 10**e
    return f"1e{e}" if abs(m - 1) < 1e-6 else f"{m:g}e{e}"


def params_label(v, _=None):
    if v >= 1e9:
        return f"{v / 1e9:.3g}B"
    return f"{v / 1e6:.3g}M"


def log_axis(axis, majors, fmt):
    axis.set_major_locator(FixedLocator(majors))
    axis.set_major_formatter(FuncFormatter(lambda v, _: fmt(v)))
    axis.set_minor_formatter(NullFormatter())


# --- approach 1: envelope of minimum loss per FLOP across all runs ---------------------------
grid = np.geomspace(runs.flops.min(), runs.flops.max(), 160)
env_loss, env_n = [], []
for c in grid:
    best, best_n = np.inf, np.nan
    for _, r in runs.groupby("run_id"):
        f, y = r.flops.to_numpy(), r.loss.to_numpy()
        if f.min() <= c <= f.max():
            yc = np.interp(np.log(c), np.log(f), y)
            if yc < best:
                best, best_n = yc, r.params.iloc[0]
    env_loss.append(best)
    env_n.append(best_n)
env = pd.DataFrame({"flops": grid, "loss": env_loss, "params": env_n})
env_fit = env[(env.flops >= fit_range[0]) & (env.flops <= fit_range[1])]
a1, b1 = np.polyfit(np.log10(env_fit.flops), np.log10(env_fit.params), 1)

# --- approach 2: isoFLOP minima (quadratic in log N per budget) -------------------------------
mins = []
for c in budgets:
    s = iso[iso.budget_flops == c].sort_values("params")
    q = np.polyfit(np.log10(s.params), s.loss, 2)
    x0 = -q[1] / (2 * q[0])
    mins.append(dict(budget=c, params=10**x0, loss=np.polyval(q, x0), q=q, s=s))
mins_df = pd.DataFrame([{k: m[k] for k in ("budget", "params", "loss")} for m in mins])
a2, b2 = np.polyfit(np.log10(mins_df.budget), np.log10(mins_df.params), 1)

fig, (ax_a, ax_b, ax_c) = house.house_figure(cells=cells, ncols=3,
                                             gridspec_kw={"width_ratios": [1.2, 1.0, 1.0]})

# a ------------------------------------------------------------------------------------------
for _, r in runs.groupby("run_id"):
    ax_a.plot(r.flops, r.loss, color=RUN_GREY, lw=0.5, zorder=1)
ax_a.plot(env.flops, env.loss, color=C_ENV, lw=1.5, zorder=3)
ax_a.set_xscale("log")
log_axis(ax_a.xaxis, [1e17, 1e18, 1e19, 1e20, 1e21, 1e22], sci)
ax_a.set_xlim(runs.flops.min() / 1.3, runs.flops.max() * 1.3)
ax_a.set_xlabel("Training FLOPs")
ax_a.set_ylabel("Training loss")
ylo, yhi = runs.loss.min(), runs.loss.max()
ax_a.set_ylim(ylo - 0.04 * (yhi - ylo), yhi + 0.04 * (yhi - ylo))
ax_a.text(0.97, 0.97, "Envelope:\nminimum loss per FLOP", transform=ax_a.transAxes, ha="right", va="top",
          fontsize=7, color=T_ENV, linespacing=1.2)
ax_a.text(0.97, 0.80, f"Grey: {n_runs} runs\n({n_sizes} sizes × {n_cycles} cosine cycles)",
          transform=ax_a.transAxes, ha="right", va="top", fontsize=6, color=grey["mid"], linespacing=1.2)
ax_a.text(0.03, 0.03, footnote, transform=ax_a.transAxes, ha="left", va="bottom", fontsize=6, color=grey["mid"])
house.add_house_tag(ax_a, "a")

# b ------------------------------------------------------------------------------------------
shades = np.linspace(0.55, 0.10, n_budgets)
for m, g in zip(mins, shades):
    col = (g, g, g)
    s = m["s"]
    xs = np.geomspace(s.params.min(), s.params.max(), 80)
    ax_b.plot(xs, np.polyval(m["q"], np.log10(xs)), color=col, lw=0.8, zorder=1)
    ax_b.scatter(s.params, s.loss, s=house.SCATTER["s"] * 0.55, color=col, linewidths=0, zorder=2)
    ax_b.text(s.params.max() * 1.12, s.loss.iloc[-1], sci(m["budget"]), ha="left", va="center", fontsize=6,
              color="#000000")
ax_b.scatter(mins_df.params, mins_df.loss, marker="D", s=14, color=C_ISO, edgecolors="#000000",
             linewidths=0.4, zorder=4)
ax_b.set_xscale("log")
log_axis(ax_b.xaxis, [1e8, 1e9, 1e10, 1e11], params_label)
ax_b.set_xlim(iso.params.min() / 1.4, iso.params.max() * 4.5)
ylo, yhi = iso.loss.min(), iso.loss.max()
ax_b.set_ylim(ylo - 0.04 * (yhi - ylo), yhi + 0.30 * (yhi - ylo))
ax_b.set_xlabel("Parameters")
ax_b.set_ylabel("Final loss")
ax_b.text(0.97, 0.97, f"{footnote}\nn = {n_budgets} budgets × {n_iso_pts // n_budgets} sizes\n"
          "Labels: FLOP budget\nDiamonds: fitted minimum", transform=ax_b.transAxes, ha="right", va="top",
          fontsize=6, color=grey["mid"], linespacing=1.3)
house.add_house_tag(ax_b, "b")

# c ------------------------------------------------------------------------------------------
xx = np.geomspace(1e17, target_flops * 1.6, 50)
fit_lo = np.log10(fit_range[0])
for a, b, col, x0 in ((a1, b1, C_ENV, fit_range[1]), (a2, b2, C_ISO, budgets[-1])):
    xin = xx[(xx <= x0) & (xx >= 10**fit_lo / 10)]
    xout = xx[xx >= x0]
    ax_c.plot(xin, 10 ** (a * np.log10(xin) + b), color=col, lw=1.0, zorder=2)
    ax_c.plot(xout, 10 ** (a * np.log10(xout) + b), color=col, lw=1.0, ls=(0, (3, 2)), zorder=2)
ax_c.scatter(env_fit.flops[::6], env_fit.params[::6], s=house.SCATTER["s"] * 0.7, color=C_ENV,
             edgecolors="#000000", linewidths=0.3, zorder=3)
ax_c.scatter(mins_df.budget, mins_df.params, marker="D", s=14, color=C_ISO, edgecolors="#000000",
             linewidths=0.4, zorder=4)
p1 = 10 ** (a1 * np.log10(target_flops) + b1)
p2 = 10 ** (a2 * np.log10(target_flops) + b2)
ax_c.set_xscale("log")
ax_c.set_yscale("log")
log_axis(ax_c.xaxis, [1e18, 1e20, 1e22, 1e24], sci)
log_axis(ax_c.yaxis, [1e8, 1e9, 1e10, 1e11], params_label)
ax_c.set_xlim(5e17, target_flops * 4.0)
ax_c.set_ylim(4e7, 4e11)
ax_c.set_xlabel("Compute budget (FLOPs)")
ax_c.set_ylabel("Compute-optimal parameters")
ax_c.text(0.03, 0.97, f"Envelope (a): slope {a1:.2f}", transform=ax_c.transAxes, ha="left", va="top",
          fontsize=7, color=T_ENV)
ax_c.text(0.03, 0.89, f"IsoFLOP (b): slope {a2:.2f}", transform=ax_c.transAxes, ha="left", va="top",
          fontsize=7, color=T_ISO)
ax_c.text(target_flops * 1.25, 1.5e9, f"Target budget {sci(target_flops)} (illustrative)", rotation=90,
          ha="left", va="center", fontsize=6, color=grey["mid"])
hi_p, lo_p = max(p1, p2), min(p1, p2)
hi_t, lo_t = (T_ENV, T_ISO) if p1 >= p2 else (T_ISO, T_ENV)
ax_c.scatter([target_flops] * 2, [p1, p2], s=10, facecolors="white", edgecolors=[C_ENV, C_ISO],
             linewidths=0.8, zorder=5)
ax_c.text(target_flops / 1.4, hi_p * 1.25, params_label(hi_p), ha="right", va="bottom", fontsize=6, color=hi_t)
ax_c.text(target_flops / 1.15, lo_p / 2.6, params_label(lo_p), ha="right", va="top", fontsize=6, color=lo_t)
fn_c = ax_c.text(0.97, 0.03, f"{footnote}\nLog-log least squares;\ndashed = extrapolation", transform=ax_c.transAxes,
                 ha="right", va="bottom", fontsize=6, color=grey["mid"], linespacing=1.2)
# Target-budget line: from the top of the axes down to line_gap_mm above the footnote's text box.
fig.canvas.draw()
fn_top_px = fn_c.get_window_extent().y1 + line_gap_mm / 25.4 * fig.dpi
line_y0 = ax_c.transAxes.inverted().transform((0, fn_top_px))[1]
ax_c.plot([target_flops, target_flops], [line_y0, 1.0], transform=blended_transform_factory(ax_c.transData, ax_c.transAxes),
          color=grey["ref"], lw=0.5, ls=(0, (1, 1.5)), zorder=0, solid_capstyle="butt", dash_capstyle="butt")
house.add_house_tag(ax_c, "c")

out = house.save_house(fig, "figure", cells=cells, bump=0)
print("canvas_mm", out["width_mm"], out["height_mm"])
print("n_runs", n_runs, "n_sizes", n_sizes, "n_cycles", n_cycles, "n_budgets", n_budgets, "n_iso_pts", n_iso_pts)
print("target_line_axes_y0", round(line_y0, 4))
print("slope_env", round(a1, 4), "slope_iso", round(a2, 4), "pred_target", f"{p1:.4g}", f"{p2:.4g}")
