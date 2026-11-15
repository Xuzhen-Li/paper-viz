"""Kaplan-Meier survival curves with Greenwood 95% CI bands, censoring ticks, a
number-at-risk table aligned to the time axis, and one two-sided log-rank test
across all groups. n and every number are computed from data.csv.
Run: python3 plot.py"""
import csv
import math
import sys
from pathlib import Path

import numpy as np
from scipy.stats import chi2

STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
sys.path.insert(0, str(STYLES))
import house  # noqa: E402

cells = "2x2"
risk_times = (0, 12, 24, 36)
x_label = "Time (months)"
y_label = "Survival probability"
TEXT = "#1A1A1A"


def lum(h):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def text_col(c, bg="#FFFFFF", need=3.0):
    a, b = sorted([lum(c), lum(bg)], reverse=True)
    return c if (a + 0.05) / (b + 0.05) >= need else TEXT


def kaplan_meier(time, event):
    """Step function (t, S), Greenwood 95% CI (plain, clipped to [0, 1])."""
    t_out, s_out, lo_out, hi_out = [0.0], [1.0], [1.0], [1.0]
    surv, var = 1.0, 0.0
    for t in np.unique(time):
        d = int(event[time == t].sum())
        n = int(np.sum(time >= t))
        if d == 0:
            continue
        surv *= 1.0 - d / n
        var += d / (n * (n - d)) if n > d else 0.0
        se = math.sqrt(var) * surv
        t_out.append(t)
        s_out.append(surv)
        lo_out.append(max(0.0, surv - 1.96 * se))
        hi_out.append(min(1.0, surv + 1.96 * se))
    return np.array(t_out), np.array(s_out), np.array(lo_out), np.array(hi_out)


def step_at(t, s, q):
    return s[np.searchsorted(t, q, side="right") - 1]


def logrank(groups):
    """k-group log-rank chi-square; returns (stat, df, two-sided P)."""
    ev = np.unique(np.concatenate([t[e == 1] for t, e in groups]))
    k = len(groups)
    o_e = np.zeros(k)
    V = np.zeros((k, k))
    for tau in ev:
        n_i = np.array([np.sum(t >= tau) for t, _ in groups], float)
        d_i = np.array([np.sum((t == tau) & (e == 1)) for t, e in groups], float)
        n, d = n_i.sum(), d_i.sum()
        if n <= 1:
            continue
        o_e += d_i - d * n_i / n
        f = d * (n - d) / (n - 1) / n
        V += f * (np.diag(n_i) - np.outer(n_i, n_i) / n)
    stat = float(o_e[:-1] @ np.linalg.solve(V[:-1, :-1], o_e[:-1]))
    return stat, k - 1, float(chi2.sf(stat, k - 1))


rows = list(csv.DictReader(Path(__file__).with_name("data.csv").open()))
names = list(dict.fromkeys(r["group"] for r in rows))
data = {g: (np.array([float(r["time"]) for r in rows if r["group"] == g]),
            np.array([int(r["event"]) for r in rows if r["group"] == g])) for g in names}
n_total = len(rows)
n_per = {g: len(data[g][0]) for g in names}
stat, df, p = logrank([data[g] for g in names])
p_txt = "P < 0.001" if p < 0.001 else f"P = {p:.3f}"
t_max = max(float(t.max()) for t, _ in data.values())

hp = house.pv_palette("house")
cols = {g: hp[[0, 2, 3][i % 3]] for i, g in enumerate(names)}
grey = house.pv_palette("house_grey")

house.apply_house_style()
fig, (ax, at) = house.house_figure(cells=cells, nrows=2, sharex=True,
                                   gridspec_kw={"height_ratios": [3.3, 1.0]})

ends = {}
for g in names:
    t, e = data[g]
    kt, ks, klo, khi = kaplan_meier(t, e)
    kt = np.append(kt, t_max)
    ks, klo, khi = np.append(ks, ks[-1]), np.append(klo, klo[-1]), np.append(khi, khi[-1])
    c = cols[g]
    ax.fill_between(kt, klo, khi, step="post", color=c, alpha=0.15, lw=0)
    ax.step(kt, ks, where="post", color=c, lw=house.LW_PT["main"])
    tc = np.sort(t[e == 0])
    ax.plot(tc, step_at(kt, ks, tc), ls="none", marker="|", markersize=3.0,
            markeredgewidth=0.6, color=c)
    ends[g] = ks[-1]

# direct labels right of the curve ends, kept >= 9 pt apart
order = sorted(names, key=lambda g: ends[g])
ys = [ends[g] for g in order]
for i in range(1, len(ys)):
    ys[i] = max(ys[i], ys[i - 1] + 0.075)
for g, y in zip(order, ys):
    ax.annotate(g, xy=(t_max, y), xytext=(3, 0), textcoords="offset points",
                ha="left", va="center", fontsize=7, color=text_col(cols[g]))

ax.set_ylim(-0.02, 1.03)
ax.set_xlim(-1.5, t_max + 13)
ax.set_xticks(risk_times)
ax.set_yticks([0, 0.25, 0.5, 0.75, 1.0])
ax.set_ylabel(y_label)
ax.tick_params(labelbottom=True)
ax.set_xlabel(x_label)

stats = (f"Log-rank test: {p_txt}\n"
         f"two-sided, {df} df; one test,\n"
         "no multiplicity correction\n"
         f"n = {n_total} (" + " / ".join(str(n_per[g]) for g in names) + ")")
ax.text(0.02, 0.165, stats, transform=ax.transAxes, ha="left", va="bottom",
        fontsize=6.5, color=TEXT, linespacing=1.15)
ax.text(0.02, 0.025, "Simulated data\nbands: 95% Greenwood CI\nticks: censored",
        transform=ax.transAxes, ha="left", va="bottom", fontsize=6,
        color=grey["mid"], linespacing=1.15)

# number-at-risk table (own framed axes, same time axis)
for i, g in enumerate(names):
    t, _ = data[g]
    for q in risk_times:
        at.text(q, i + 1, str(int(np.sum(t >= q))), ha="center", va="center",
                fontsize=7, color=TEXT)
at.text(-1.0, 0.05, "Number at risk", ha="left", va="center", fontsize=6.5, color=grey["mid"])
at.set_ylim(len(names) + 0.6, -0.55)
at.set_yticks(range(1, len(names) + 1))
at.set_yticklabels(names)
for lab, g in zip(at.get_yticklabels(), names):
    lab.set_color(text_col(cols[g]))
at.tick_params(axis="x", bottom=False, labelbottom=False)
at.tick_params(axis="y", left=False)

house.save_house(fig, "figure")
print(f"wrote figure.pdf, figure.png, preview.png; logrank chi2={stat:.2f} df={df} p={p:.2e}")
