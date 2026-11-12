"""Simulated agent-evaluation runs for the agent-eval-dashboard figure.
One row per (agent, run): tasks attempted, tasks solved, and API cost split into three parts
(USD per run). Agent names are generic strategy labels, not real systems. Fixed seed; writes
data.csv once (refuses to overwrite). Run: python3 make_data.py"""
import csv

import numpy as np

SEED = 71050
N_TASKS = 150      # tasks per run
N_RUNS = 5         # repeated runs per agent
rng = np.random.default_rng(SEED)

# name, solve probability, mean cost (USD per run) of prompt tokens, completion tokens, retries/tools
agents = [
    ("Single call",      0.700, 0.06, 0.03, 0.00),
    ("Retry x3",         0.780, 0.12, 0.06, 0.05),
    ("Retry x5",         0.800, 0.17, 0.09, 0.10),
    ("Escalate model",   0.835, 0.30, 0.16, 0.08),
    ("Self-reflect",     0.815, 0.55, 0.30, 0.22),
    ("Debate x3",        0.825, 1.40, 0.85, 0.40),
    ("Tree search",      0.845, 3.20, 1.60, 1.90),
    ("Planner-executor", 0.790, 0.95, 0.40, 0.60),
]

rows = []
for name, p, c_in, c_out, c_tool in agents:
    for run in range(1, N_RUNS + 1):
        p_run = np.clip(p + rng.normal(0, 0.012), 0, 1)
        solved = int(rng.binomial(N_TASKS, p_run))
        noise = rng.lognormal(0, 0.08, size=3)
        rows.append({
            "agent": name,
            "run": run,
            "n_tasks": N_TASKS,
            "n_solved": solved,
            "cost_prompt_usd": round(c_in * noise[0], 4),
            "cost_completion_usd": round(c_out * noise[1], 4),
            "cost_retry_tool_usd": round(c_tool * noise[2], 4),
        })

with open("data.csv", "x", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0]))
    w.writeheader()
    w.writerows(rows)
print(f"wrote data.csv: {len(rows)} rows, seed {SEED}")
