"""Turn a VTracer SVG into fewer, page-absolute paths.

VTracer (the same visioncortex approach as vectorizer.ai) emits stacked
filled shapes, but most of its cubic segments are already straight and every
shape sits on its own translate(). This module bakes those translates into
the path and replaces near-straight cubics with line segments so the file is
smaller and the nodes are easier to edit.

The curve-to-chord error is bounded by ``eps`` pixels: a cubic is kept
whenever a control point leaves that corridor.
"""

from __future__ import annotations

import math
import re

_TOKEN = re.compile(r"[MLCZ]|[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?")
_PATH = re.compile(
    r"<path\b([^>]*?)\bd=\"([^\"]*)\"([^>]*)/>",
    re.DOTALL,
)
_FILL = re.compile(r"\bfill=\"(#[0-9A-Fa-f]{6})\"")
_TRANSLATE = re.compile(
    r"""transform="translate\(\s*([-+0-9.eE]+)(?:[,\s]+([-+0-9.eE]+))?\s*\)\""""
)


def _dist_to_line(px: float, py: float, x0: float, y0: float, x1: float, y1: float) -> float:
    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy)
    if length < 1e-9:
        return math.hypot(px - x0, py - y0)
    return abs(dy * px - dx * py + x1 * y0 - y1 * x0) / length


def _rdp(points: list[tuple[float, float]], eps: float) -> list[tuple[float, float]]:
    if len(points) < 3:
        return points
    x0, y0 = points[0]
    x1, y1 = points[-1]
    split_at = 0
    farthest = 0.0
    for i in range(1, len(points) - 1):
        d = _dist_to_line(points[i][0], points[i][1], x0, y0, x1, y1)
        if d > farthest:
            farthest = d
            split_at = i
    if farthest <= eps:
        return [points[0], points[-1]]
    left = _rdp(points[: split_at + 1], eps)
    right = _rdp(points[split_at:], eps)
    return left[:-1] + right


def _fmt(n: float) -> str:
    rounded = round(n, 2)
    if abs(rounded - round(rounded)) < 1e-9:
        return str(int(round(rounded)))
    return f"{rounded:.2f}".rstrip("0").rstrip(".")


def parse_path(d: str) -> list[list[tuple]]:
    tokens = _TOKEN.findall(d)
    subpaths: list[list[tuple]] = []
    current: list[tuple] | None = None
    i = 0
    while i < len(tokens):
        kind = tokens[i]
        if kind == "M":
            current = [("M", float(tokens[i + 1]), float(tokens[i + 2]))]
            subpaths.append(current)
            i += 3
        elif kind == "L":
            if current is None:
                raise ValueError("lineto before moveto")
            current.append(("L", float(tokens[i + 1]), float(tokens[i + 2])))
            i += 3
        elif kind == "C":
            if current is None:
                raise ValueError("cubic before moveto")
            vals = tuple(float(v) for v in tokens[i + 1 : i + 7])
            current.append(("C",) + vals)
            i += 7
        elif kind == "Z":
            if current is None:
                raise ValueError("closepath before moveto")
            current.append(("Z",))
            i += 1
        else:
            raise ValueError(f"unexpected path token {kind}")
    return subpaths


def _translate_subpaths(subpaths: list[list[tuple]], tx: float, ty: float) -> list[list[tuple]]:
    if tx == 0 and ty == 0:
        return subpaths
    moved: list[list[tuple]] = []
    for sub in subpaths:
        out = []
        for cmd in sub:
            if cmd[0] == "Z":
                out.append(cmd)
            elif cmd[0] == "M":
                out.append(("M", cmd[1] + tx, cmd[2] + ty))
            else:
                out.append(
                    (
                        "C",
                        cmd[1] + tx,
                        cmd[2] + ty,
                        cmd[3] + tx,
                        cmd[4] + ty,
                        cmd[5] + tx,
                        cmd[6] + ty,
                    )
                )
        moved.append(out)
    return moved


def simplify_subpath(cmds: list[tuple], eps: float) -> list[tuple]:
    out: list[tuple] = [cmds[0]]
    cx, cy = cmds[0][1], cmds[0][2]
    start = (cx, cy)
    line_run: list[tuple[float, float]] = [(cx, cy)]

    def flush_lines() -> None:
        nonlocal line_run
        if len(line_run) >= 2:
            for x, y in _rdp(line_run, eps)[1:]:
                if abs(x - out[-1][-2]) < 1e-6 and abs(y - out[-1][-1]) < 1e-6:
                    continue
                out.append(("L", x, y))
            line_run = [line_run[-1]]

    for cmd in cmds[1:]:
        kind = cmd[0]
        if kind == "C":
            x1, y1, x2, y2, x, y = cmd[1:]
            deviation = max(
                _dist_to_line(x1, y1, cx, cy, x, y),
                _dist_to_line(x2, y2, cx, cy, x, y),
            )
            if deviation <= eps:
                line_run.append((x, y))
            else:
                flush_lines()
                out.append(cmd)
                line_run = [(x, y)]
            cx, cy = x, y
        elif kind == "Z":
            if len(line_run) >= 2 and math.hypot(line_run[-1][0] - start[0], line_run[-1][1] - start[1]) <= 0.05:
                line_run.pop()
            flush_lines()
            out.append(("Z",))
        elif kind == "M":
            flush_lines()
            out.append(cmd)
            cx, cy = cmd[1], cmd[2]
            start = (cx, cy)
            line_run = [(cx, cy)]
        else:
            raise ValueError(kind)
    flush_lines()
    return out


def commands_to_d(cmds: list[tuple]) -> str:
    parts: list[str] = []
    for cmd in cmds:
        if cmd[0] == "Z":
            parts.append("Z")
        elif cmd[0] == "M":
            parts.append(f"M{_fmt(cmd[1])} {_fmt(cmd[2])}")
        elif cmd[0] == "L":
            parts.append(f"L{_fmt(cmd[1])} {_fmt(cmd[2])}")
        else:
            parts.append(
                "C"
                + " ".join(_fmt(v) for v in cmd[1:])
            )
    return " ".join(parts)


def simplify_path_d(d: str, tx: float = 0.0, ty: float = 0.0, eps: float = 0.6) -> str:
    subpaths = _translate_subpaths(parse_path(d), tx, ty)
    pieces: list[tuple] = []
    for sub in subpaths:
        pieces.extend(simplify_subpath(sub, eps))
    return commands_to_d(pieces)


def _translate_of(attrs: str) -> tuple[float, float]:
    match = _TRANSLATE.search(attrs)
    if not match:
        return 0.0, 0.0
    tx = float(match.group(1))
    ty = float(match.group(2) or 0.0)
    return tx, ty


def simplify_svg(svg: str, eps: float = 0.6) -> str:
    """Bake translates and straighten near-linear cubics. Paint order is unchanged."""

    def replace(match: re.Match[str]) -> str:
        attrs = match.group(1) + match.group(3)
        fill_match = _FILL.search(attrs)
        if not fill_match:
            raise ValueError("path is missing a fill")
        tx, ty = _translate_of(attrs)
        d = simplify_path_d(match.group(2), tx, ty, eps)
        return f'<path fill="{fill_match.group(1).upper()}" d="{d}"/>'

    body, n = _PATH.subn(replace, svg)
    if n == 0:
        raise ValueError("SVG contains no paths")
    return body
