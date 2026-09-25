#!/usr/bin/env python3
"""Interactive scatter via Plotly CDN HTML. Requires: pip install plotly"""
from __future__ import annotations

from pathlib import Path

import numpy as np

try:
    import plotly.express as px
except ImportError as e:
    raise SystemExit("plotly required: pip install plotly") from e

rng = np.random.default_rng(0)
n = 200
df = {
    "x": rng.normal(size=n),
    "y": rng.normal(size=n),
    "group": rng.choice(["A", "B", "C"], size=n),
}
fig = px.scatter(df, x="x", y="y", color="group", title="Plotly scatter (CDN)")
out = Path(__file__).with_name("plotly_scatter.html")
fig.write_html(out, include_plotlyjs="cdn")
print(f"wrote {out}")
