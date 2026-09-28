"""Rebuild the figure as a few clean shapes and real text.

The traced SVG was thousands of overlapping paths, so letters and borders
looked dirty. This file draws each box once, and each label is a text
element you can edit. The report column is the original artwork, cropped
and embedded as a single image, so that dashboard is not redrawn from guesswork.
"""

from __future__ import annotations

import base64
import io
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
SOURCE_PDF = HERE / "source.pdf"
OUTPUT = HERE / "figure.svg"

INK = "#17315C"
MUTED = "#3E5674"
ARROW = "#1B4F8A"
CARD = "#FFFFFF"
LINE = "#D5E1EA"

PAGE_W, PAGE_H = 1900, 1080
PANEL_Y, PANEL_H, HEADER_H = 28, 1024, 58

COLUMNS = {
    "input": {"x": 36, "w": 250, "fill": "#D7ECFB", "head": "#4C96D0", "label": "INPUT"},
    "proc": {"x": 302, "w": 500, "fill": "#E5F7EA", "head": "#6AA572", "label": "PROCESSING"},
    "ana": {"x": 818, "w": 560, "fill": "#FDF1E2", "head": "#C4A36E", "label": "ANALYSIS"},
    "rep": {"x": 1394, "w": 470, "fill": "#FDE8E6", "head": "#D06568", "label": "REPORT"},
}

FONT = "Noto Sans, DejaVu Sans, Arial, sans-serif"


def _esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;")


def _panel(spec: dict) -> str:
    x, y, w, h = spec["x"], PANEL_Y, spec["w"], PANEL_H
    head = HEADER_H
    return f"""
    <g id="panel-{spec['label'].lower()}">
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="{spec['fill']}"/>
      <rect x="{x}" y="{y}" width="{w}" height="{head}" rx="18" fill="{spec['head']}"/>
      <rect x="{x}" y="{y + head - 18}" width="{w}" height="18" fill="{spec['head']}"/>
      <text x="{x + w / 2}" y="{y + 37}" text-anchor="middle" font-family="{FONT}" font-size="20" font-weight="700" fill="#FFFFFF" letter-spacing="1.5">{spec['label']}</text>
    </g>"""


def _card(x: float, y: float, w: float, h: float, fill: str = CARD) -> str:
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{fill}" stroke="{LINE}" stroke-width="1.25"/>'


def _text(x: float, y: float, body: str, size: float = 18, weight: str = "700", fill: str = INK, anchor: str = "start") -> str:
    return (
        f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="{FONT}" '
        f'font-size="{size}" font-weight="{weight}" fill="{fill}">{_esc(body)}</text>'
    )


def _icon_file(x: float, y: float, color: str) -> str:
    return f"""
    <g transform="translate({x} {y})" fill="none" stroke="{color}" stroke-width="2.2" stroke-linejoin="round">
      <path d="M6 4 H18 L26 12 V32 H6 Z" fill="#F7FBFE"/>
      <path d="M18 4 V12 H26"/>
      <path d="M10 18 H22 M10 23 H22 M10 28 H17" stroke-linecap="round"/>
    </g>"""


def _icon_scissors(x: float, y: float) -> str:
    return f"""
    <g transform="translate({x} {y})" fill="none" stroke="{INK}" stroke-width="2.3" stroke-linecap="round">
      <circle cx="9" cy="8" r="4.2" fill="#FFFFFF"/>
      <circle cx="9" cy="28" r="4.2" fill="#FFFFFF"/>
      <path d="M12.2 10.6 L30 30 M12.2 25.4 L30 6"/>
    </g>"""


def _icon_bars(x: float, y: float) -> str:
    return f"""
    <g transform="translate({x} {y})" fill="{INK}">
      <rect x="4" y="6" width="26" height="4" rx="2"/>
      <rect x="4" y="14" width="20" height="4" rx="2"/>
      <rect x="4" y="22" width="14" height="4" rx="2"/>
    </g>"""


def _icon_layers(x: float, y: float) -> str:
    return f"""
    <g transform="translate({x} {y})" fill="{INK}">
      <rect x="6" y="18" width="22" height="7" rx="2"/>
      <rect x="8" y="12" width="22" height="7" rx="2" fill="#4C96D0"/>
      <rect x="10" y="6" width="22" height="7" rx="2" fill="#6AA572"/>
    </g>"""


def _icon_bases(x: float, y: float) -> str:
    dots = [(6, 8), (16, 8), (26, 8), (11, 18), (21, 18), (8, 28), (18, 28), (28, 28)]
    circles = "".join(f'<circle cx="{cx}" cy="{cy}" r="2.3" fill="{INK}"/>' for cx, cy in dots)
    return f'<g transform="translate({x} {y})">{circles}</g>'


def _icon_doc(x: float, y: float) -> str:
    return f"""
    <g transform="translate({x} {y})" fill="none" stroke="{INK}" stroke-width="2.2" stroke-linejoin="round">
      <path d="M8 4 H20 L28 12 V32 H8 Z" fill="#FFFFFF"/>
      <path d="M20 4 V12 H28"/>
      <path d="M12 20 H24 M12 25 H20" stroke-linecap="round"/>
    </g>"""


def _icon_target(x: float, y: float) -> str:
    return f"""
    <g transform="translate({x} {y})" fill="none" stroke="{INK}" stroke-width="2.2">
      <circle cx="18" cy="18" r="10"/>
      <circle cx="18" cy="18" r="3" fill="{INK}" stroke="none"/>
      <path d="M18 4 V8 M18 28 V32 M4 18 H8 M28 18 H32" stroke-linecap="round"/>
    </g>"""


def _icon_chromosome(x: float, y: float) -> str:
    return f"""
    <g transform="translate({x} {y})" fill="none" stroke="#2E6EAB" stroke-width="5" stroke-linecap="round">
      <path d="M8 6 C8 18 28 14 28 30"/>
      <path d="M28 6 C28 18 8 14 8 30"/>
    </g>"""


def _arrow(cx: float, y: float, h: float) -> str:
    return f"""
    <g>
      <rect x="{cx - 4}" y="{y}" width="8" height="{h - 12}" rx="3" fill="{ARROW}"/>
      <polygon points="{cx - 9},{y + h - 13} {cx + 9},{y + h - 13} {cx},{y + h}" fill="{ARROW}"/>
    </g>"""


def _input_column() -> str:
    col = COLUMNS["input"]
    x, w = col["x"], col["w"]
    files = [
        (128, "FASTQ", "#4C96D0"),
        (430, "BAM", "#4C96D0"),
        (700, "VCF", "#4C96D0"),
    ]
    parts = ['<g id="input-files">']
    for y, label, color in files:
        parts.append(f'<g id="input-{label.lower()}">')
        parts.append(_card(x + 22, y, w - 44, 150))
        parts.append(_icon_file(x + 40, y + 52, color))
        parts.append(_text(x + w / 2, y + 92, label, 26, "700", INK, "middle"))
        parts.append("</g>")
    y = 900
    parts.append('<g id="input-bases">')
    parts.append(_card(x + 22, y, w - 44, 120))
    rows = [("1", "A", "G"), ("2", "T", "C"), ("3", "G", "A")]
    colors = {"A": "#2E9D57", "T": "#D06568", "C": "#3D7EBE", "G": "#C4A36E"}
    for i, (n, left, right) in enumerate(rows):
        yy = y + 36 + i * 28
        parts.append(_text(x + 48, yy, n, 15, "600", MUTED))
        parts.append(_text(x + 100, yy, left, 16, "700", colors[left], "middle"))
        parts.append(_text(x + 150, yy, right, 16, "700", colors[right], "middle"))
    parts.append("</g></g>")
    return "\n".join(parts)


def _chip(x: float, y: float, w: float, h: float, lines: list[str], fill: str) -> str:
    body = [_card(x, y, w, h, fill)]
    if len(lines) == 1:
        body.append(_text(x + 16, y + h / 2 + 6, lines[0], 15, "600", INK))
    else:
        body.append(_text(x + 16, y + 28, lines[0], 15, "600", INK))
        body.append(_text(x + 16, y + 52, lines[1], 15, "700", INK))
    return "\n".join(body)


def _step(gid: str, x: float, y: float, w: float, h: float, title: str, icon: str, subtitle: str | None = None) -> str:
    parts = [f'<g id="{gid}">', _card(x, y, w, h), icon]
    if subtitle:
        parts.append(_text(x + 62, y + 34, title, 20))
        parts.append(_text(x + 62, y + 58, subtitle, 15, "600", MUTED))
    else:
        parts.append(_text(x + 62, y + 46, title, 22))
    parts.append("</g>")
    return "\n".join(parts)


def _processing() -> str:
    col = COLUMNS["proc"]
    x = col["x"] + 18
    w = 268
    cx = x + w / 2
    # y, height, id, title, icon builder, optional subtitle
    steps = [
        (116, 78, "step-trim", "Trim", _icon_scissors, None),
        (264, 78, "step-map", "MAP", _icon_bars, None),
        (412, 78, "step-markdup", "Markdup", _icon_layers, None),
        (560, 86, "step-snp", "bcftools", _icon_bases, "SNP calling"),
        (716, 78, "step-vcf", "VCF", _icon_doc, None),
        (864, 86, "step-grape", "GrapeAncestry", _icon_target, "target sites"),
    ]
    parts = ['<g id="processing-steps">']
    for (y, h, *_), (y2, *_) in zip(steps, steps[1:]):
        parts.append(_arrow(cx, y + h + 4, y2 - (y + h) - 6))
    for y, h, gid, title, icon, subtitle in steps:
        parts.append(_step(gid, x, y, w, h, title, icon(x + 16, y + 18), subtitle))
    chip_x = x + w + 16
    chip_w = col["x"] + col["w"] - chip_x - 16
    parts.append('<g id="step-trim-notes">')
    parts.append(_chip(chip_x, 116, chip_w, 44, ["PE: fastp"], "#E7F3FC"))
    parts.append(_chip(chip_x, 168, chip_w, 66, ["SE (aDNA):", "AdapterRemoval"], "#FFFFFF"))
    parts.append("</g>")
    parts.append('<g id="step-map-notes">')
    parts.append(_card(chip_x, 268, chip_w, 96, "#E7F3FC"))
    parts.append(_icon_chromosome(chip_x + 10, 286))
    parts.append(_text(chip_x + 52, 310, "VS-1", 16))
    parts.append(_text(chip_x + 52, 334, "genome", 16, "600", MUTED))
    parts.append("</g></g>")
    return "\n".join(parts)


def _mini(kind: str, x: float, y: float) -> str:
    ink = INK
    if kind == "qc":
        return f'<g transform="translate({x} {y})" fill="none" stroke="{ink}" stroke-width="2" stroke-linecap="round"><circle cx="14" cy="14" r="10"/><path d="M9 14.5 L12.5 18 L19.5 10"/></g>'
    if kind == "link":
        return f'<g transform="translate({x} {y})" fill="{ink}"><circle cx="8" cy="16" r="3.2"/><circle cx="22" cy="10" r="3.2"/><path d="M10.5 14.5 L19.5 11.5" fill="none" stroke="{ink}" stroke-width="2"/></g>'
    if kind == "scatter":
        pts = [(6, 18), (12, 12), (16, 16), (20, 8), (24, 14)]
        return "<g>" + "".join(f'<circle cx="{x+px}" cy="{y+py}" r="2.1" fill="{ink}"/>' for px, py in pts) + "</g>"
    if kind == "stack":
        return f'<g transform="translate({x} {y})"><rect x="4" y="8" width="8" height="16" rx="1" fill="#4C96D0"/><rect x="4" y="16" width="8" height="8" fill="#C4A36E"/><rect x="16" y="12" width="8" height="12" rx="1" fill="#4C96D0"/><rect x="16" y="18" width="8" height="6" fill="#D06568"/></g>'
    if kind == "tree":
        return f'<g transform="translate({x} {y})" fill="none" stroke="{ink}" stroke-width="2" stroke-linecap="round"><path d="M8 24 V12 H20 V6 M14 12 V18 H22"/></g>'
    if kind == "curve":
        return f'<g transform="translate({x} {y})" fill="none" stroke="{ink}" stroke-width="2" stroke-linecap="round"><path d="M4 8 C10 8 12 22 26 24"/><path d="M4 26 H26" stroke="{LINE}"/></g>'
    if kind == "hits":
        return f'<g transform="translate({x} {y})" stroke="{LINE}" stroke-width="1.5"><path d="M4 16 H26"/><circle cx="8" cy="20" r="2" fill="{ink}" stroke="none"/><circle cx="14" cy="10" r="2" fill="{ink}" stroke="none"/><circle cx="22" cy="18" r="2" fill="{ink}" stroke="none"/></g>'
    if kind == "stat":
        return f'<g transform="translate({x} {y})" font-family="{FONT}" font-size="13" font-weight="700" fill="{ink}"><text x="2" y="18">f</text><text x="12" y="14" font-size="9">3</text><text x="18" y="18">f</text><text x="26" y="14" font-size="9">4</text></g>'
    if kind == "tag":
        return f'<g transform="translate({x} {y})" fill="none" stroke="{ink}" stroke-width="2" stroke-linejoin="round"><path d="M4 10 H16 L24 16 L16 22 H4 Z"/><circle cx="10" cy="16" r="1.4" fill="{ink}" stroke="none"/></g>'
    return f'<g transform="translate({x} {y})" fill="none" stroke="{ink}" stroke-width="2"><circle cx="11" cy="16" r="7"/><circle cx="19" cy="16" r="7"/></g>'


def _analysis() -> str:
    col = COLUMNS["ana"]
    x, w = col["x"], col["w"]
    rows = [
        ("qc", "QC"),
        ("link", "Relatedness"),
        ("scatter", "PCA"),
        ("stack", "ADMIXTURE"),
        ("tree", "NJ"),
        ("curve", "Damage pattern"),
        ("hits", "GWAS / Selection"),
        ("stat", "f3 / f4"),
        ("tag", "Site annotation"),
        ("overlap", "Overlapped"),
    ]
    parts = ['<g id="analysis-list">']
    top, row_h = 108, 70
    for i, (kind, label) in enumerate(rows):
        y = top + i * row_h
        parts.append(f'<g id="analysis-{label.lower().split()[0]}">')
        parts.append(_card(x + 18, y, w - 36, 58))
        parts.append(_mini(kind, x + 34, y + 14))
        parts.append(_text(x + 78, y + 36, label, 18))
        parts.append("</g>")
    y = 820
    parts.append('<g id="reference-data">')
    parts.append(_card(x + 18, y, w - 36, 200, "#E7F3FC"))
    parts.append(_text(x + 36, y + 32, "Reference data (used in analysis)", 15, "700"))
    cells = [
        ("core", "genotypes"),
        ("PCA / ADMIXTURE", "references"),
        ("VIVC", "passport"),
        ("OIV", "descriptors"),
    ]
    cw = (w - 36 - 32) / 4
    for i, (a, b) in enumerate(cells):
        cx = x + 34 + i * cw
        parts.append(_card(cx, y + 52, cw - 10, 128))
        parts.append(_text(cx + (cw - 10) / 2, y + 108, a, 12, "700", INK, "middle"))
        parts.append(_text(cx + (cw - 10) / 2, y + 132, b, 12, "600", MUTED, "middle"))
    parts.append("</g></g>")
    return "\n".join(parts)


def _report(png: bytes) -> str:
    col = COLUMNS["rep"]
    x, y = col["x"] + 16, PANEL_Y + HEADER_H + 14
    w = col["w"] - 32
    h = PANEL_H - HEADER_H - 28
    encoded = base64.b64encode(png).decode("ascii")
    return f"""
    <g id="report-view">
      <clipPath id="report-clip"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14"/></clipPath>
      <image x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid meet" clip-path="url(#report-clip)" href="data:image/png;base64,{encoded}"/>
    </g>"""


def report_png() -> bytes:
    import pymupdf

    doc = pymupdf.open(SOURCE_PDF)
    pix = pymupdf.Pixmap(doc, doc[0].get_images(full=True)[0][0])
    src = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
    crop = src.crop((3048, 228, 4016, 2168))
    buf = io.BytesIO()
    crop.save(buf, format="PNG", optimize=True)
    return buf.getvalue()


def build_svg(report: bytes) -> str:
    body = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{PAGE_W}" height="{PAGE_H}" viewBox="0 0 {PAGE_W} {PAGE_H}">',
        "<title>可编辑示意图</title>",
        "<desc>Clean editable redraw. Boxes are rectangles and labels are text. The report column is one embedded image of the original dashboard.</desc>",
        f'<rect width="{PAGE_W}" height="{PAGE_H}" fill="#F7F8F6"/>',
    ]
    for spec in COLUMNS.values():
        body.append(_panel(spec))
    body.append(_input_column())
    body.append(_processing())
    body.append(_analysis())
    body.append(_report(report))
    body.append("</svg>\n")
    return "\n".join(body)


def main() -> None:
    svg = build_svg(report_png())
    OUTPUT.write_text(svg, encoding="utf-8")
    print(f"wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
