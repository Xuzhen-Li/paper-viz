"""paper-viz house style (default for NEW figures) — matplotlib.

Same numbers as ``styles/r/theme_house.R``: 7 pt ticks, 8 pt axis titles, 10 pt bold
lowercase panel tags, four-sided 0.5 pt frame, ticks outward 1 mm, no grid; main data
lines 1.5 pt, point outline 0.3 pt. 89 mm (single) / 183 mm (double) presets. A
single-column single panel gets +2 pt on all text (ticks 9, axis titles 10).

Usage, from a figure folder (same import pattern as ``style.py``)::

    STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
    sys.path.insert(0, str(STYLES))
    import house

    house.apply_house_style()
    fig, ax = house.house_figure("single", height_mm=76)
    ax.plot(x, y, color=house.pv_palette("house")[0])
    house.save_house(fig, "figure")       # figure.pdf + figure.png (600 dpi) + preview.png

Old interfaces (``style.apply_style``, ``style.PALETTES["categorical"]`` chip eight) are unchanged.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.text import Text

MM = 1 / 25.4  # inches per mm
PT_PER_MM = 72 / 25.4

PRESETS_MM = {"single": 89.0, "double": 183.0}
DEFAULT_HEIGHT_MM = {"single": 76.0, "double": 118.0}

FONT_FAMILY = ["Arial", "Helvetica", "Liberation Sans", "DejaVu Sans"]

# Line widths in pt (STYLE §6).
LW_PT = {
    "frame": 0.5,
    "tick": 0.5,
    "main": 1.5,
    "emph": 2.0,
    "minor": 0.8,
    "ref": 0.5,
    "errorbar": 0.7,
}
# Points: filled circle with a thin dark outline; ~1.3 mm diameter (STYLE §5).
POINT = {"marker": "o", "markersize": 1.3 * PT_PER_MM, "markeredgewidth": 0.3, "markeredgecolor": "#000000"}
SCATTER = {"s": (1.3 * PT_PER_MM) ** 2, "linewidths": 0.3, "edgecolors": "#000000"}

HOUSE_PALETTES: dict[str, list[str] | dict[str, str]] = {
    "house": ["#1F72AE", "#F77E12", "#119B76", "#CC312C", "#595594", "#62B4E7", "#E6C32A", "#A8127F", "#8A4C38"],
    "house_div": ["#1D7CBB", "#4A82B0", "#8EBDDA", "#DEE4F0", "#F7F7F7", "#F6DEDE", "#E19193", "#C4454B", "#CB2223"],
    "ssp": {
        "Historical": "#000000",
        "SSP1-2.6": "#3A9CFE",
        "SSP2-4.5": "#F79423",
        "SSP3-7.0": "#FD3B3B",
        "SSP5-8.5": "#9C2125",
    },
    "house_warm": ["#FBD6A0", "#F5BA7A", "#F38F64", "#CC635F", "#965459"],
    "house_grey": {
        "text": "#000000",
        "dark": "#333333",
        "mid": "#6B6B6B",
        "ref": "#757575",
        "ci": "#BFBFBF",
        "light": "#E0E0E0",
        "bg": "#F0F0F0",
    },
}
_RAMPABLE = {"house_div", "house_warm"}


def _legacy_palettes() -> dict:
    try:
        from . import style as _style  # package import
    except ImportError:  # top-level import (sys.path points at styles/python)
        import style as _style  # type: ignore[no-redef]
    return _style.PALETTES


def pv_palette(name: str = "house", n: int | None = None):
    """House palettes plus the legacy ones from ``style.PALETTES`` (``categorical`` = chip eight).

    ``ssp`` and ``house_grey`` return a name -> hex dict when ``n`` is None.
    """
    if name in HOUSE_PALETTES:
        stops = HOUSE_PALETTES[name]
        if n is None:
            return dict(stops) if isinstance(stops, dict) else list(stops)
        cols = list(stops.values()) if isinstance(stops, dict) else list(stops)
        if n < 1:
            raise ValueError("n must be >= 1")
        if n <= len(cols):
            return cols[:n]
        if name in _RAMPABLE:
            cmap = mpl.colors.LinearSegmentedColormap.from_list(name, cols)
            return [mpl.colors.to_hex(cmap(i / (n - 1))) for i in range(n)]
        raise ValueError(f"pv_palette({name!r}) has {len(cols)} colours; n = {n} is too many (grey out the rest)")
    legacy = _legacy_palettes()
    if name not in legacy:
        raise KeyError(f"unknown palette {name!r}")
    cols = list(legacy[name])
    return cols if n is None else cols[:n]


def house_cmap(name: str = "house_div"):
    """Continuous colormap from ``house_div`` or ``house_warm``."""
    return mpl.colors.LinearSegmentedColormap.from_list(name, list(HOUSE_PALETTES[name]))


def house_rc(base_size: float = 7, title_size: float | None = None) -> dict:
    """rcParams for the house style. ``base_size`` = tick labels (7; 9 for a single-column single panel)."""
    title_size = base_size + 1 if title_size is None else title_size
    tick_len = 1.0 * PT_PER_MM
    return {
        "font.family": "sans-serif",
        "font.sans-serif": FONT_FAMILY,
        "font.size": base_size,
        "mathtext.fontset": "custom",  # italic P, R^2 etc. in the same sans font (STYLE §3)
        "mathtext.rm": "sans",
        "mathtext.it": "sans:italic",
        "mathtext.bf": "sans:bold",
        "mathtext.sf": "sans",
        "axes.labelsize": title_size,
        "axes.labelweight": "normal",
        "axes.titlesize": title_size,
        "axes.titleweight": "normal",
        "axes.titlelocation": "left",
        "axes.labelpad": 0.8 * PT_PER_MM,
        "axes.linewidth": LW_PT["frame"],
        "axes.edgecolor": "#000000",
        "axes.labelcolor": "#000000",
        "axes.spines.top": True,
        "axes.spines.right": True,
        "axes.spines.left": True,
        "axes.spines.bottom": True,
        "axes.grid": False,
        "axes.facecolor": "white",
        "axes.unicode_minus": True,
        "axes.prop_cycle": mpl.cycler(color=HOUSE_PALETTES["house"]),
        "axes.xmargin": 0.04,
        "axes.ymargin": 0.04,
        "xtick.labelsize": base_size,
        "ytick.labelsize": base_size,
        "xtick.direction": "out",
        "ytick.direction": "out",
        "xtick.major.size": tick_len,
        "ytick.major.size": tick_len,
        "xtick.major.width": LW_PT["tick"],
        "ytick.major.width": LW_PT["tick"],
        "xtick.major.pad": 0.7 * PT_PER_MM,
        "ytick.major.pad": 0.7 * PT_PER_MM,
        "xtick.minor.visible": False,
        "ytick.minor.visible": False,
        "xtick.color": "#000000",
        "ytick.color": "#000000",
        "lines.linewidth": LW_PT["main"],
        "lines.markersize": POINT["markersize"],
        "lines.markeredgewidth": POINT["markeredgewidth"],
        "scatter.edgecolors": "#000000",
        "patch.linewidth": LW_PT["frame"],
        "legend.frameon": False,
        "legend.fontsize": base_size,
        "legend.title_fontsize": base_size,
        "legend.loc": "upper right",
        "legend.handlelength": 3 * PT_PER_MM / base_size,  # key width <= 3 mm
        "legend.borderaxespad": 0.3,
        "figure.facecolor": "white",
        "figure.dpi": 150,
        "figure.constrained_layout.use": True,
        "figure.constrained_layout.h_pad": 0.5 * MM,
        "figure.constrained_layout.w_pad": 0.5 * MM,
        "figure.constrained_layout.hspace": 0.0,
        "figure.constrained_layout.wspace": 0.0,
        "savefig.dpi": 600,
        "savefig.bbox": None,  # keep the exact 89 / 183 mm canvas
        "savefig.facecolor": "white",
        "pdf.fonttype": 42,  # TrueType: text stays text in PDF
        "ps.fonttype": 42,
        "svg.fonttype": "none",
    }


def apply_house_style(base_size: float = 7, *, single_panel: bool = False) -> None:
    """Load the house rcParams. ``single_panel=True`` = single-column single panel (+2 pt)."""
    plt.rcParams.update(house_rc(base_size + (2 if single_panel else 0)))


def house_figure(width="double", height_mm: float | None = None, nrows: int = 1, ncols: int = 1, **kw):
    """``plt.subplots`` at a preset width ("single" 89 mm, "double" 183 mm) or a width in mm."""
    width_mm = PRESETS_MM[width] if isinstance(width, str) else float(width)
    if height_mm is None:
        height_mm = DEFAULT_HEIGHT_MM["single" if width_mm <= 89 else "double"]
    return plt.subplots(nrows, ncols, figsize=(width_mm * MM, height_mm * MM), **kw)


def add_house_tag(ax, letter: str, *, size: float = 10, x: float = 0.0, y: float = 1.0) -> Text:
    """Bold lowercase panel letter at the top-left corner of the axes' tight box."""
    return ax.annotate(
        letter.lower(),
        xy=(x, y),
        xycoords="axes fraction",
        xytext=(-3 * PT_PER_MM, 1 * PT_PER_MM),
        textcoords="offset points",
        fontsize=size,
        fontweight="bold",
        ha="right",
        va="bottom",
    )


def _data_axes(fig):
    return [ax for ax in fig.axes if ax.get_label() != "<colorbar>" and ax.get_visible()]


def _tick_size(fig) -> float:
    for ax in _data_axes(fig):
        labels = ax.xaxis.get_ticklabels() or ax.yaxis.get_ticklabels()
        if labels:
            return float(labels[0].get_fontsize())
    size = mpl.rcParams["xtick.labelsize"]
    return float(size) if not isinstance(size, str) else 7.0


def bump_text(fig, pt: float = 2) -> None:
    """Add ``pt`` points to every text in the figure (tick labels, labels, annotations, legends)."""
    if not pt:
        return
    tick_ids = set()
    for ax in fig.axes:
        for name, axis in (("x", ax.xaxis), ("y", ax.yaxis)):
            labels = axis.get_ticklabels()
            tick_ids.update(id(t) for t in labels)
            size = labels[0].get_fontsize() if labels else mpl.rcParams["font.size"]
            ax.tick_params(axis=name, labelsize=size + pt)
    seen = set()
    for t in fig.findobj(Text):
        if id(t) in seen or id(t) in tick_ids or not t.get_text():
            continue
        seen.add(id(t))
        t.set_fontsize(t.get_fontsize() + pt)


def save_house(
    fig,
    path,
    *,
    bump: float | None = None,
    dpi: int = 600,
    preview: bool = True,
) -> dict:
    """Write ``<path>.pdf`` (TrueType text) and ``<path>.png`` at ``dpi``; optionally ``preview.png`` (1200 px).

    The canvas is saved as-is (no tight bbox) so 89 / 183 mm stay exact. When the figure is at most
    89 mm wide and has a single data axes, text is raised to 9 pt ticks / 10 pt axis titles
    (+2 pt over the 7 pt default; computed from the current tick size, so never applied twice).
    """
    width_in, height_in = fig.get_size_inches()
    width_in, height_in = float(width_in), float(height_in)
    width_mm = width_in / MM
    if bump is None:
        bump = max(0.0, 9 - _tick_size(fig)) if width_mm <= 89 + 1e-6 and len(_data_axes(fig)) == 1 else 0.0
    bump_text(fig, bump)
    base = Path(path)
    if base.suffix.lower() in {".pdf", ".png", ".svg", ".tif", ".tiff"}:
        base = base.with_suffix("")
    base.parent.mkdir(parents=True, exist_ok=True)
    with mpl.rc_context({"pdf.fonttype": 42, "svg.fonttype": "none", "savefig.bbox": None}):
        fig.savefig(base.with_suffix(".pdf"), facecolor="white")
        fig.savefig(base.with_suffix(".png"), dpi=dpi, facecolor="white")
        if preview:
            fig.savefig(base.parent / "preview.png", dpi=1200 / width_in, facecolor="white")
    return {
        "pdf": base.with_suffix(".pdf"),
        "png": base.with_suffix(".png"),
        "width_mm": width_mm,
        "height_mm": height_in / MM,
        "bump": bump,
    }


__all__ = [
    "HOUSE_PALETTES",
    "LW_PT",
    "POINT",
    "PRESETS_MM",
    "SCATTER",
    "add_house_tag",
    "apply_house_style",
    "bump_text",
    "house_cmap",
    "house_figure",
    "house_rc",
    "pv_palette",
    "save_house",
]
