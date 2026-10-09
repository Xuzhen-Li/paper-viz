"""paper-viz house style (default for NEW figures) — matplotlib.

Same numbers as ``styles/r/theme_house.R``: 7 pt ticks, 8 pt axis titles, 10 pt bold
lowercase panel tags, four-sided 0.5 pt frame, ticks outward 1 mm, no grid; main data
lines 1.5 pt, point outline 0.3 pt. Figure sizes snap to the house grid (``cells``; 43 mm
cell, 3 mm gap, 1-4 cells per side; see ``house_canvas``). Only a single-column figure holding
exactly one 2x2 (89 x 89 mm) panel gets +2 pt on all text (ticks 9, axis titles 10).

Usage, from a figure folder (same import pattern as ``style.py``)::

    STYLES = Path(__file__).resolve().parents[3] / "styles" / "python"
    sys.path.insert(0, str(STYLES))
    import house

    house.apply_house_style()
    fig, ax = house.house_figure(cells="2x1")    # 89 x 43 mm
    ax.plot(x, y, color=house.pv_palette("house")[0])
    house.save_house(fig, "figure")       # figure.pdf + figure.png (600 dpi) + preview.png

Old interfaces (``style.apply_style``, ``style.PALETTES["categorical"]`` chip eight) are unchanged.
"""

from __future__ import annotations

import re
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.layout_engine import ConstrainedLayoutEngine
from matplotlib.text import Text

MM = 1 / 25.4  # inches per mm
PT_PER_MM = 72 / 25.4

# --- grid (same rule as styles/r/theme_house.R) ---------------------------------------
# 43 mm cell, 3 mm gap (horizontal and vertical), 1-4 cells per side.
#   span(n) = 43 n + 3 (n - 1)  ->  43 / 89 / 135 / 181 mm
# Canvas (= the exported page) is the span on a side of 1-3 cells, with NO outer margin: a
# figure is a tile. The 1 mm outer margin belongs to the page and is added only on a side that
# spans all 4 cells: 1 + 181 + 1 = 183 mm (double column); content goes in the centred 181 mm
# box. Tiles of column c then start at 1 + 46 (c - 1) mm of a 183 mm page, so 1+1+1+1, 1+1+2,
# 2+2, 1+3 and 4 with 3 mm gaps rebuild 183 mm exactly and line up with a 4-cell figure.
CELL_MM = 43.0
GAP_MM = 3.0
PAGE_MARGIN_MM = 1.0
MAX_CELLS = 4
PRESETS_MM = {"single": 89.0, "double": 183.0}  # canvas mm, kept for old calls
PRESETS_CELLS = {"single": 2, "double": 4}

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
# Points (STYLE §5): same physical size as R HOUSE_POINT (ggplot shape 21, size 2.3, stroke 0.3,
# the locked demo A). ggplot draws the circle path with diameter 0.75 * (size * .pt + stroke * .stroke / 2)
# pt and an outline of stroke * .stroke / 2 lwd (1 lwd = 0.75 pt). That gives a 1.88 mm path,
# a 0.43 pt outline and a 2.04 mm outer diameter; matplotlib markersize is the path diameter in pt.
_GG_PT = 72.27 / 25.4
_GG_STROKE = 96 / 25.4


def ggplot_point_pt(size: float = 2.3, stroke: float = 0.3) -> tuple[float, float]:
    """(path diameter, outline width) in pt of a ggplot2 shape-21 point."""
    stroke_lwd = stroke * _GG_STROKE / 2
    return 0.75 * (size * _GG_PT + stroke_lwd), stroke_lwd * 0.75


_POINT_D_PT, _POINT_EDGE_PT = ggplot_point_pt(2.3, 0.3)
POINT = {"marker": "o", "markersize": _POINT_D_PT, "markeredgewidth": _POINT_EDGE_PT, "markeredgecolor": "#000000"}
SCATTER = {"s": _POINT_D_PT**2, "linewidths": _POINT_EDGE_PT, "edgecolors": "#000000"}

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


def grid_span(n: int) -> float:
    """Span of ``n`` cells in mm (no margin): 43 / 89 / 135 / 181."""
    return n * CELL_MM + (n - 1) * GAP_MM


def grid_canvas(n: int) -> float:
    """Canvas mm of an ``n``-cell side: the span, plus 1 mm each end when ``n`` = 4 (183)."""
    return grid_span(n) + (2 * PAGE_MARGIN_MM if n == MAX_CELLS else 0.0)


def house_cells(cells) -> tuple[int, int]:
    """``(w, h)`` or ``"WxH"`` (also ``X`` / ``×``) -> ``(w, h)`` ints; ValueError off the grid."""
    if isinstance(cells, str):
        m = re.fullmatch(r"\s*([0-9]+)\s*[xX\u00d7]\s*([0-9]+)\s*", cells)
        if not m:
            raise ValueError(f'cells = {cells!r}: use (w, h) or "WxH", e.g. "2x1"')
        cells = (int(m.group(1)), int(m.group(2)))
    try:
        vals = [float(c) for c in cells]
    except TypeError:
        vals = []
    if len(vals) != 2 or any(v != int(v) or not 1 <= v <= MAX_CELLS for v in vals):
        raise ValueError(f"cells = {cells!r} is off the house grid: width and height must each be 1-{MAX_CELLS} whole cells")
    return int(vals[0]), int(vals[1])


def _mm_to_cells(mm: float, what: str) -> int:
    allowed = [grid_canvas(n) for n in range(1, MAX_CELLS + 1)]
    for n, a in enumerate(allowed, start=1):
        if abs(a - mm) < 1e-6:
            return n
    near = min(allowed, key=lambda a: abs(a - mm))
    raise ValueError(
        f"{what} = {mm:g} mm is off the house grid (allowed canvas: {', '.join(f'{a:g}' for a in allowed)} mm). "
        f"Use cells=(w, h); nearest grid size: {near:g} mm."
    )


def house_canvas(cells) -> dict:
    """Canvas / content geometry in mm for a cells spec (see the grid rule above)."""
    w, h = house_cells(cells)
    mx = PAGE_MARGIN_MM if w == MAX_CELLS else 0.0
    my = PAGE_MARGIN_MM if h == MAX_CELLS else 0.0
    return {
        "cells": (w, h),
        "width_mm": grid_canvas(w),
        "height_mm": grid_canvas(h),
        "content_width_mm": grid_span(w),
        "content_height_mm": grid_span(h),
        "margin_x_mm": mx,
        "margin_y_mm": my,
    }


def _resolve_cells(cells=None, width=None, height_mm=None) -> tuple[int, int]:
    """cells, or the old width ("single" / "double" / grid mm) + height_mm (grid mm). Off grid -> error.

    Off-grid mm is an error, not a warning: every house caller is on the grid, and a warning
    would let an off-grid figure pass CI. height_mm defaults to 1 cell.
    """
    if cells is not None:
        if width is not None or height_mm is not None:
            raise ValueError("give either cells or width/height_mm, not both")
        return house_cells(cells)
    if width is None:
        raise ValueError('give cells=(w, h), e.g. cells="2x1"')
    if isinstance(width, str):
        if width not in PRESETS_CELLS:
            raise ValueError(f'width = {width!r}: use "single", "double" or cells=(w, h)')
        w = PRESETS_CELLS[width]
    else:
        w = _mm_to_cells(float(width), "width")
    h = 1 if height_mm is None else _mm_to_cells(float(height_mm), "height_mm")
    return w, h


def _apply_canvas(fig, cells) -> dict:
    geo = house_canvas(cells)
    fig.set_size_inches(geo["width_mm"] * MM, geo["height_mm"] * MM)
    W, H = geo["width_mm"], geo["height_mm"]
    rect = (geo["margin_x_mm"] / W, geo["margin_y_mm"] / H, geo["content_width_mm"] / W, geo["content_height_mm"] / H)
    engine = fig.get_layout_engine()
    if isinstance(engine, ConstrainedLayoutEngine):
        engine.set(rect=rect)  # house default: content drawn in the inner (margin-free) box
    fig._pv_cells = geo["cells"]
    return geo


def house_figure(width=None, height_mm: float | None = None, nrows: int = 1, ncols: int = 1, *, cells=None, **kw):
    """``plt.subplots`` on the house grid: ``cells=(w, h)`` or ``"WxH"``.

    Old calls ``house_figure("single" | "double" | mm, height_mm=mm)`` still work when the sizes
    are on the grid ("single" = 2 cells, "double" = 4 cells); anything else raises ValueError.
    """
    c = _resolve_cells(cells, width, height_mm)
    geo = house_canvas(c)
    fig, axes = plt.subplots(nrows, ncols, figsize=(geo["width_mm"] * MM, geo["height_mm"] * MM), **kw)
    _apply_canvas(fig, c)
    return fig, axes


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
    cells=None,
    bump: float | None = None,
    dpi: int = 600,
    preview: bool = True,
) -> dict:
    """Write ``<path>.pdf`` (TrueType text) and ``<path>.png`` at ``dpi``; optionally ``preview.png`` (1200 px).

    ``cells``: grid size; defaults to the one given to ``house_figure``, else it is read from the
    figure size, which must then be a grid canvas (ValueError otherwise). The canvas is saved
    as-is (no tight bbox) so grid sizes stay exact. Only a 2x2 (89 x 89 mm) figure with a single
    data axes gets 9 pt ticks / 10 pt axis titles (+2 pt over the 7 pt default; computed from the
    current tick size, so never applied twice).
    """
    if cells is None:
        cells = getattr(fig, "_pv_cells", None)
    if cells is None:
        w_in, h_in = fig.get_size_inches()
        cells = (_mm_to_cells(float(w_in) / MM, "figure width"), _mm_to_cells(float(h_in) / MM, "figure height"))
    geo = _apply_canvas(fig, cells)
    width_in = geo["width_mm"] * MM
    if bump is None:
        bump = max(0.0, 9 - _tick_size(fig)) if geo["cells"] == (2, 2) and len(_data_axes(fig)) == 1 else 0.0
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
        "cells": geo["cells"],
        "width_mm": geo["width_mm"],
        "height_mm": geo["height_mm"],
        "content_width_mm": geo["content_width_mm"],
        "content_height_mm": geo["content_height_mm"],
        "bump": bump,
    }


__all__ = [
    "CELL_MM",
    "GAP_MM",
    "HOUSE_PALETTES",
    "MAX_CELLS",
    "PAGE_MARGIN_MM",
    "PRESETS_CELLS",
    "LW_PT",
    "POINT",
    "PRESETS_MM",
    "SCATTER",
    "add_house_tag",
    "apply_house_style",
    "bump_text",
    "grid_canvas",
    "grid_span",
    "house_canvas",
    "house_cells",
    "house_cmap",
    "house_figure",
    "house_rc",
    "ggplot_point_pt",
    "pv_palette",
    "save_house",
]
