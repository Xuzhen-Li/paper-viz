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
# Chip-paper categorical order (same as R pv_palette("categorical")).
# Control / background point clouds (not a data category): #E0E0E0.
_CHIP_CATEGORICAL = [
    "#134aa3",
    "#f6a3b1",
    "#0b5475",
    "#dc1f26",
    "#835ca6",
    "#f7922c",
    "#fbee61",
    "#981b1e",
]

PALETTES = {
    "categorical": list(_CHIP_CATEGORICAL),
    "bio": list(_CHIP_CATEGORICAL),
    "contrast": list(_CHIP_CATEGORICAL),
    "muted": ["#E0E0E0", "#BDBDBD", "#9E9E9E", "#757575"],
}

INK = "#111827"
MUTED = "#E0E0E0"
ACCENT = "#134aa3"
CONTROL = "#E0E0E0"


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
                "font.sans-serif": ["Helvetica", "Arial", "DejaVu Sans"],
                "font.size": 11,
                "axes.titlesize": 12,
                "axes.labelsize": 12,
                "axes.linewidth": 0.5,
                "xtick.major.width": 0.5,
                "ytick.major.width": 0.5,
                "pdf.fonttype": 42,
                "svg.fonttype": "none",
                "axes.spines.top": True,
                "axes.spines.right": True,
                "axes.spines.left": True,
                "axes.spines.bottom": True,
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
