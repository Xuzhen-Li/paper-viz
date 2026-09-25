"""Small matplotlib helpers for publication panels."""

from __future__ import annotations

from matplotlib.axes import Axes


def despine(ax: Axes, *, top: bool = True, right: bool = True, left: bool = False, bottom: bool = False) -> None:
    if top:
        ax.spines["top"].set_visible(False)
    if right:
        ax.spines["right"].set_visible(False)
    if left:
        ax.spines["left"].set_visible(False)
    if bottom:
        ax.spines["bottom"].set_visible(False)


def label_outer(axes) -> None:
    """Hide inner x/y labels on a grid of axes."""
    try:
        for ax in axes.flat:
            ax.label_outer()
    except AttributeError:
        for ax in axes:
            ax.label_outer()


def add_panel_tag(ax: Axes, tag: str, *, x: float = -0.12, y: float = 1.05, fontsize: float = 9) -> None:
    ax.text(
        x,
        y,
        tag,
        transform=ax.transAxes,
        fontsize=fontsize,
        fontweight="bold",
        va="bottom",
        ha="right",
    )


def annotate_points(ax: Axes, xs, ys, labels, *, offset=(4, 4), fontsize: float = 7) -> None:
    for x, y, lab in zip(xs, ys, labels):
        ax.annotate(
            lab,
            (x, y),
            textcoords="offset points",
            xytext=offset,
            fontsize=fontsize,
            color="#111827",
        )
