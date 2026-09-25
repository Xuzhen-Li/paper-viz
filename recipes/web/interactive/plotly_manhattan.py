#!/usr/bin/env python3
"""Toy Manhattan-style plot via Plotly. Requires: pip install plotly"""
from __future__ import annotations

from pathlib import Path

import numpy as np

try:
    import plotly.graph_objects as go
except ImportError as e:
    raise SystemExit("plotly required: pip install plotly") from e

rng = np.random.default_rng(1)
chroms = list(range(1, 6))
xs, ys, colors = [], [], []
offset = 0
palette = ["#0072B2", "#E69F00", "#009E73", "#D55E00", "#CC79A7"]
for i, c in enumerate(chroms):
    n = 80
    pos = rng.uniform(0, 1e7, size=n)
    p = rng.uniform(1e-8, 1.0, size=n)
    xs.extend(offset + pos)
    ys.extend(-np.log10(p))
    colors.extend([palette[i % len(palette)]] * n)
    offset += 1e7

fig = go.Figure(
    data=go.Scatter(
        x=xs,
        y=ys,
        mode="markers",
        marker=dict(size=5, color=colors, opacity=0.75),
        name="-log10(p)",
    )
)
fig.update_layout(
    title="Toy Manhattan (Plotly CDN)",
    xaxis_title="genomic position (concat)",
    yaxis_title="-log10(p)",
    template="simple_white",
)
out = Path(__file__).with_name("plotly_manhattan.html")
fig.write_html(out, include_plotlyjs="cdn")
print(f"wrote {out}")
