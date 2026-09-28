"""Compose the figure from the supplied icon artwork and editable text.

Icons are the screenshot sprites. Every label is an SVG text element, including
the words that were painted inside the FASTQ, BAM, and VCF pages.
"""

from __future__ import annotations

import base64
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ASSETS = HERE / "assets"
OUTPUT = HERE / "figure.svg"

INK = "#16315C"
MUTED = "#3E5674"
ARROW = "#1B4F8A"
CARD = "#FFFFFF"
LINE = "#D5E1EA"
FONT = "Noto Sans, DejaVu Sans, Arial, sans-serif"

PAGE_W, PAGE_H = 2040, 1180
PANEL_Y, PANEL_H, HEADER_H = 24, 1132, 56

COLUMNS = {
    "input": {"x": 24, "w": 300, "fill": "#D7ECFB", "head": "#4C96D0", "label": "INPUT"},
    "proc": {"x": 340, "w": 560, "fill": "#E5F7EA", "head": "#6AA572", "label": "PROCESSING"},
    "ana": {"x": 916, "w": 700, "fill": "#FDF1E2", "head": "#C4A36E", "label": "ANALYSIS"},
    "rep": {"x": 1632, "w": 384, "fill": "#FDE8E6", "head": "#D06568", "label": "REPORT"},
}

# Blank area left after the raster letters were removed, as fractions of the sprite.
FILE_TEXT = {
    "fastq": {"label": "FASTQ", "cx": 0.562, "cy": 0.40, "size": 0.115},
    "bam": {"label": "BAM", "cx": 0.542, "cy": 0.39, "size": 0.12},
    "vcf": {"label": "VCF", "cx": 0.55, "cy": 0.40, "size": 0.12},
}


def _esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;")


def _b64(name: str) -> tuple[str, int, int]:
    path = ASSETS / f"{name}.png"
    with Image.open(path) as image:
        width, height = image.size
    return base64.b64encode(path.read_bytes()).decode("ascii"), width, height


def _text(x, y, body, size=18, weight="700", fill=INK, anchor="start") -> str:
    return (
        f'<text x="{x:.1f}" y="{y:.1f}" text-anchor="{anchor}" font-family="{FONT}" '
        f'font-size="{size}" font-weight="{weight}" fill="{fill}">{_esc(body)}</text>'
    )


def _image(name: str, x: float, y: float, w: float, h: float) -> str:
    data, _, _ = _b64(name)
    return (
        f'<image x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" '
        f'href="data:image/png;base64,{data}"/>'
    )


def _fit(name: str, x: float, y: float, max_w: float, max_h: float) -> tuple[str, float, float]:
    _, sw, sh = _b64(name)
    scale = min(max_w / sw, max_h / sh)
    w, h = sw * scale, sh * scale
    ox = x + (max_w - w) / 2
    oy = y + (max_h - h) / 2
    return _image(name, ox, oy, w, h), w, h


def _panel(spec: dict) -> str:
    x, y, w, h = spec["x"], PANEL_Y, spec["w"], PANEL_H
    head = HEADER_H
    return f"""
    <g id="panel-{spec['label'].lower()}">
      <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="{spec['fill']}"/>
      <rect x="{x}" y="{y}" width="{w}" height="{head}" rx="18" fill="{spec['head']}"/>
      <rect x="{x}" y="{y + head - 18}" width="{w}" height="18" fill="{spec['head']}"/>
      {_text(x + w / 2, y + 36, spec['label'], 20, "700", "#FFFFFF", "middle")}
    </g>"""


def _card(x, y, w, h, fill=CARD) -> str:
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="14" fill="{fill}" stroke="{LINE}" stroke-width="1.25"/>'


def _arrow(cx, y, h) -> str:
    return f"""
    <g>
      <rect x="{cx - 4:.1f}" y="{y:.1f}" width="8" height="{h - 12:.1f}" rx="3" fill="{ARROW}"/>
      <polygon points="{cx - 9:.1f},{y + h - 13:.1f} {cx + 9:.1f},{y + h - 13:.1f} {cx:.1f},{y + h:.1f}" fill="{ARROW}"/>
    </g>"""


def _input_column() -> str:
    col = COLUMNS["input"]
    x = col["x"] + 24
    w = col["w"] - 48
    parts = ['<g id="input-files">']
    y = PANEL_Y + HEADER_H + 28
    order = ["fastq", "bam", "vcf"]
    gap = 18
    heights = []
    for name in order:
        _, sw, sh = _b64(name)
        heights.append(w * sh / sw)
    for name, h in zip(order, heights):
        meta = FILE_TEXT[name]
        parts.append(f'<g id="input-{name}">')
        parts.append(_image(name, x, y, w, h))
        parts.append(
            _text(x + w * meta["cx"], y + h * meta["cy"], meta["label"], max(22, h * meta["size"]), "700", INK, "middle")
        )
        if name == "vcf":
            rows = [("1", "A", "G"), ("2", "T", "C"), ("3", "G", "A")]
            colors = {"A": "#2E9D57", "T": "#D06568", "C": "#3D7EBE", "G": "#C4A36E"}
            for i, (n, left, right) in enumerate(rows):
                yy = y + h * (0.62 + i * 0.09)
                parts.append(_text(x + w * 0.38, yy, n, h * 0.055, "600", MUTED, "middle"))
                parts.append(_text(x + w * 0.50, yy, left, h * 0.06, "700", colors[left], "middle"))
                parts.append(_text(x + w * 0.64, yy, right, h * 0.06, "700", colors[right], "middle"))
        parts.append("</g>")
        y += h + gap
    parts.append("</g>")
    return "\n".join(parts)


def _processing() -> str:
    col = COLUMNS["proc"]
    x = col["x"] + 16
    card_w = 300
    steps = [
        ("trim", "scissors", "Trim", None),
        ("map", "bars", "MAP", None),
        ("markdup", "layers", "Markdup", None),
        ("snp", "clipboard", "bcftools", "SNP calling"),
        ("vcf", "doc", "VCF", None),
        ("grape", "target", "GrapeAncestry", "target sites"),
    ]
    top = PANEL_Y + HEADER_H + 18
    slot = (PANEL_H - HEADER_H - 36) / len(steps)
    card_h = slot - 28
    parts = ['<g id="processing-steps">']
    centers = []
    for i, (gid, icon, title, subtitle) in enumerate(steps):
        y = top + i * slot
        centers.append(y)
        parts.append(f'<g id="step-{gid}">')
        parts.append(_card(x, y, card_w, card_h))
        parts.append(_fit(icon, x + 10, y + 8, 86, card_h - 16)[0])
        if subtitle:
            parts.append(_text(x + 108, y + card_h * 0.42, title, 20))
            parts.append(_text(x + 108, y + card_h * 0.68, subtitle, 15, "600", MUTED))
        else:
            parts.append(_text(x + 108, y + card_h * 0.58, title, 22))
        parts.append("</g>")
    for y in centers[:-1]:
        parts.append(_arrow(x + card_w / 2, y + card_h + 2, slot - card_h - 4))

    chip_x = x + card_w + 14
    chip_w = col["x"] + col["w"] - chip_x - 14
    y0 = centers[0]
    parts.append('<g id="step-trim-notes">')
    parts.append(_card(chip_x, y0, chip_w, 40, "#E7F3FC"))
    parts.append(_text(chip_x + 12, y0 + 26, "PE: fastp", 15, "600"))
    parts.append(_card(chip_x, y0 + 48, chip_w, 58, "#FFFFFF"))
    parts.append(_text(chip_x + 12, y0 + 70, "SE (aDNA):", 14, "600"))
    parts.append(_text(chip_x + 12, y0 + 92, "AdapterRemoval", 14))
    parts.append("</g>")

    y1 = centers[1]
    parts.append('<g id="step-map-notes">')
    img, _, ih = _fit("browser", chip_x, y1, chip_w, card_h - 36)
    parts.append(img)
    parts.append(_text(chip_x + chip_w / 2, y1 + ih + 18, "VS-1 genome", 14, "700", INK, "middle"))
    parts.append("</g></g>")
    return "\n".join(parts)


def _analysis() -> str:
    col = COLUMNS["ana"]
    x, w = col["x"], col["w"]
    parts = ['<g id="analysis-list">']
    y = PANEL_Y + HEADER_H + 16
    parts.append(_card(x + 16, y, (w - 48) / 2, 42))
    parts.append(_text(x + 32, y + 27, "QC", 16))
    parts.append(_card(x + 32 + (w - 48) / 2, y, (w - 48) / 2, 42))
    parts.append(_text(x + 48 + (w - 48) / 2, y + 27, "f3 / f4", 16))

    charts = [
        ("pca", "PCA"),
        ("admixture", "ADMIXTURE"),
        ("tree", "NJ"),
        ("heatmap", "Relatedness"),
        ("coverage", "Damage pattern"),
        ("regress", "GWAS / Selection"),
        ("browser", "Site annotation"),
        ("venn", "Overlapped"),
    ]
    grid_y = y + 54
    cols, rows = 2, 4
    gap = 12
    cw = (w - 32 - gap) / cols
    ref_h = 132
    ref_y = PANEL_Y + PANEL_H - 16 - ref_h
    ch = (ref_y - 12 - grid_y - (rows - 1) * gap) / rows
    for i, (icon, label) in enumerate(charts):
        cx = x + 16 + (i % cols) * (cw + gap)
        cy = grid_y + (i // cols) * (ch + gap)
        parts.append(f'<g id="analysis-{label.lower().split()[0]}">')
        parts.append(_card(cx, cy, cw, ch))
        parts.append(_fit(icon, cx + 8, cy + 6, cw - 16, ch - 40)[0])
        parts.append(_text(cx + cw / 2, cy + ch - 12, label, 15, "700", INK, "middle"))
        parts.append("</g>")

    parts.append('<g id="reference-data">')
    parts.append(_card(x + 16, ref_y, w - 32, ref_h, "#E7F3FC"))
    parts.append(_text(x + 32, ref_y + 28, "Reference data (used in analysis)", 15))
    cells = [("core", "genotypes"), ("PCA / ADMIXTURE", "references"), ("VIVC", "passport"), ("OIV", "descriptors")]
    inner_w = (w - 32 - 28) / 4
    for i, (a, b) in enumerate(cells):
        cx = x + 28 + i * inner_w
        parts.append(_card(cx, ref_y + 42, inner_w - 8, ref_h - 56))
        parts.append(_text(cx + (inner_w - 8) / 2, ref_y + 78, a, 12, "700", INK, "middle"))
        parts.append(_text(cx + (inner_w - 8) / 2, ref_y + 98, b, 12, "600", MUTED, "middle"))
    parts.append("</g></g>")
    return "\n".join(parts)


def _report() -> str:
    col = COLUMNS["rep"]
    x, w = col["x"], col["w"]
    y = PANEL_Y + HEADER_H + 20
    parts = ['<g id="report-view">']
    parts.append(_text(x + w / 2, y + 8, "Interactive", 18, "700", INK, "middle"))
    img, _, _ = _fit("map", x + 20, y + 28, w - 40, PANEL_H - HEADER_H - 80)
    parts.append(img)
    parts.append("</g>")
    return "\n".join(parts)


def build_svg() -> str:
    body = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{PAGE_W}" height="{PAGE_H}" viewBox="0 0 {PAGE_W} {PAGE_H}">',
        "<title>可编辑示意图</title>",
        "<desc>Icons are artwork. Every label is editable text.</desc>",
        f'<rect width="{PAGE_W}" height="{PAGE_H}" fill="#F7F8F6"/>',
    ]
    for spec in COLUMNS.values():
        body.append(_panel(spec))
    body.append(_input_column())
    body.append(_processing())
    body.append(_analysis())
    body.append(_report())
    body.append("</svg>\n")
    return "\n".join(body)


def main() -> None:
    svg = build_svg()
    OUTPUT.write_text(svg, encoding="utf-8")
    print(f"wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
