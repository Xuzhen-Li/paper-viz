"""Shared publication-oriented matplotlib style for AI_lib visualization/.

Seeded from projects/autonomous-ai-research/scripts/fig_style.py (palette/rcParams ideas)
and journal-sizing practices documented by faridrashidi/cnsplots (https://cnsplots.farid.one/)
— cite those sources; this module does not vendor their code.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt

_HERE = Path(__file__).resolve().parent
_RC = _HERE / "matplotlibrc"

# Single-ink / CNS-friendly palette (inspired by fig_style.py + journal restraint)
PALETTES = {
    "bio": ["#1e3a5f", "#2A629A", "#D98324", "#518B60", "#C75050", "#6B6B6B"],
    "contrast": ["#111827", "#1e3a5f", "#9f1239", "#14532d", "#92400e", "#6b7280"],
    "muted": ["#6b7280", "#9ca3af", "#d1d5db", "#e5e7eb"],
}

INK = "#111827"
MUTED = "#6b7280"
ACCENT = "#1e3a5f"


def apply_style(base: str | Path | None = None) -> None:
    """Load shared matplotlibrc (or a path) and set unicode_minus."""
    path = Path(base) if base else _RC
    if path.exists():
        plt.style.use(str(path))
    else:
        plt.rcParams.update(
            {
                "figure.dpi": 150,
                "savefig.dpi": 600,
                "font.family": "sans-serif",
                "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
                "font.size": 7,
                "axes.titlesize": 7,
                "axes.labelsize": 7,
                "axes.linewidth": 0.8,
                "xtick.major.width": 0.8,
                "ytick.major.width": 0.8,
                "pdf.fonttype": 42,
                "svg.fonttype": "none",
                "axes.spines.top": False,
                "axes.spines.right": False,
            }
        )
    plt.rcParams["axes.unicode_minus"] = False
    plt.rcParams["pdf.fonttype"] = 42
    plt.rcParams["svg.fonttype"] = "none"
    plt.rcParams["figure.facecolor"] = "white"
    plt.rcParams["axes.facecolor"] = "white"
    plt.rcParams["savefig.facecolor"] = "white"


def save_fig(fig, path, *, dpi: int = 600, **kw) -> Path:
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    plt.rcParams["pdf.fonttype"] = 42
    plt.rcParams["svg.fonttype"] = "none"
    fig.savefig(out, dpi=dpi, bbox_inches="tight", pad_inches=0.08, **kw)
    return out
