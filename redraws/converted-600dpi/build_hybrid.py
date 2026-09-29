"""Hybrid editable SVG: native layout and text, cropped icons embedded inline.

The reference page is converted-600dpi.pdf at 4096 by 2308. Panels, cards,
arrows, and labels are SVG. Complex icons and report plots are cropped from
that page, with only the edge-connected background removed, then stored as
base64 PNG inside one file.
"""

from __future__ import annotations

import base64
import io
import xml.etree.ElementTree as ET
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFont

from build_aligned import ocr_boxes, select_labels

HERE = Path(__file__).resolve().parent
SOURCE_PDF = HERE / "source.pdf"
OUTPUT = HERE / "GrapeAncestry_Pixelmator_singlefile.svg"
PREVIEW = HERE / "GrapeAncestry_Pixelmator_singlefile_preview.png"
FONT_PATH = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
FONT_FAMILY = "Arial, Helvetica, Liberation Sans, sans-serif"

PAGE_W, PAGE_H = 4096, 2308
NAVY = "#04174F"
ARROW = "#033B7D"
WHITE = "#FFFFFF"


def load_page() -> Image.Image:
    cached = Path("/tmp/src2.png")
    if cached.exists():
        return Image.open(cached).convert("RGB")
    import pymupdf

    doc = pymupdf.open(SOURCE_PDF)
    pix = pymupdf.Pixmap(doc, doc[0].get_images(full=True)[0][0])
    image = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
    image.save(cached)
    return image


def remove_connected_background(image: Image.Image, tolerance: int = 28) -> Image.Image:
    """Drop only the background that touches the crop edge. Interior light pixels stay."""
    arr = np.array(image.convert("RGBA"))
    rgb = arr[:, :, :3].astype(np.int16)
    height, width = rgb.shape[:2]
    corners = np.array([rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1]])
    background = np.median(corners, axis=0)
    candidate = np.max(np.abs(rgb - background), axis=2) <= tolerance
    seen = np.zeros((height, width), dtype=bool)
    queue: deque[tuple[int, int]] = deque()
    for x in range(width):
        queue.append((0, x))
        queue.append((height - 1, x))
    for y in range(height):
        queue.append((y, 0))
        queue.append((y, width - 1))
    while queue:
        y, x = queue.popleft()
        if y < 0 or x < 0 or y >= height or x >= width or seen[y, x] or not candidate[y, x]:
            continue
        seen[y, x] = True
        arr[y, x, 3] = 0
        queue.append((y - 1, x))
        queue.append((y + 1, x))
        queue.append((y, x - 1))
        queue.append((y, x + 1))
    return Image.fromarray(arr)


def _trim(image: Image.Image) -> Image.Image:
    box = image.getbbox()
    return image.crop(box) if box else image


def _upscale(image: Image.Image) -> Image.Image:
    long_side = max(image.size)
    if long_side < 140:
        factor = 4
    elif long_side < 260:
        factor = 2
    else:
        factor = 1
    if factor == 1:
        return image
    return image.resize((image.width * factor, image.height * factor), Image.Resampling.LANCZOS)


def isolate(page: Image.Image, box: tuple[int, int, int, int], blanks: list[dict] | None = None, tolerance: int = 28) -> Image.Image:
    crop = page.crop(box).convert("RGBA")
    arr = np.array(crop)
    for label in blanks or []:
        x0 = max(0, label["x0"] - box[0] - 2)
        y0 = max(0, label["y0"] - box[1] - 2)
        x1 = min(arr.shape[1], label["x1"] - box[0] + 2)
        y1 = min(arr.shape[0], label["y1"] - box[1] + 2)
        if x1 > x0 and y1 > y0:
            arr[y0:y1, x0:x1] = (255, 255, 255, 255)
    cleaned = remove_connected_background(Image.fromarray(arr), tolerance)
    return _upscale(_trim(cleaned))


def _png_href(image: Image.Image) -> str:
    buf = io.BytesIO()
    image.save(buf, format="PNG", optimize=True)
    encoded = base64.b64encode(buf.getvalue()).decode("ascii")
    return f"data:image/png;base64,{encoded}"


def _place(text: str, box_w: int, box_h: int) -> tuple[int, float, float]:
    size = max(8, int(box_h * 0.92))
    while size > 8:
        font = ImageFont.truetype(FONT_PATH, size)
        left, top, right, bottom = font.getbbox(text, anchor="ls")
        if (right - left) <= box_w and (bottom - top) <= box_h:
            return size, float(-left), float(-top)
        size -= 1
    font = ImageFont.truetype(FONT_PATH, 8)
    left, top, _, _ = font.getbbox(text, anchor="ls")
    return 8, float(-left), float(-top)


def _text_fill(label: dict) -> str:
    if label["text"] in {"INPUT", "PROCESSING", "ANALYSIS", "REPORT", "Interactive"}:
        return "#F7FBFE"
    return NAVY


def _xml(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;")


def _image(element_id: str, image: Image.Image, x: float, y: float, width: float, height: float) -> str:
    href = _png_href(image)
    return (
        f'<image id="{element_id}" x="{x:.1f}" y="{y:.1f}" width="{width:.1f}" height="{height:.1f}" '
        f'preserveAspectRatio="xMidYMid meet" href="{href}" xlink:href="{href}"/>'
    )


def _rect(x, y, w, h, fill, rx=0, stroke="none", sw=0) -> str:
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" ry="{rx}" '
        f'fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
    )


def _header(x, y, w, h, fill, rx) -> str:
    """Rounded top, square bottom, so the header meets the panel body."""
    return (
        _rect(x, y, w, h, fill, rx)
        + _rect(x, y + h - rx, w, rx, fill)
    )


def _arrow(x1, y1, x2, y2, size=18) -> str:
    color = ARROW
    head = ""
    if abs(x2 - x1) >= abs(y2 - y1):
        direction = 1 if x2 > x1 else -1
        tip = x2
        base = x2 - direction * size
        head = f'<polygon fill="{color}" points="{tip:.1f},{y2:.1f} {base:.1f},{y2 - size * 0.55:.1f} {base:.1f},{y2 + size * 0.55:.1f}"/>'
        x2 = base
    else:
        direction = 1 if y2 > y1 else -1
        tip = y2
        base = y2 - direction * size
        head = f'<polygon fill="{color}" points="{x2:.1f},{tip:.1f} {x2 - size * 0.55:.1f},{base:.1f} {x2 + size * 0.55:.1f},{base:.1f}"/>'
        y2 = base
    line = f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{color}" stroke-width="14" stroke-linecap="round"/>'
    return line + head


def _labels_inside(labels: list[dict], box: tuple[int, int, int, int]) -> list[dict]:
    x0, y0, x1, y1 = box
    kept = []
    for label in labels:
        cx = (label["x0"] + label["x1"]) / 2
        cy = (label["y0"] + label["y1"]) / 2
        if x0 <= cx <= x1 and y0 <= cy <= y1:
            kept.append(label)
    return kept


ANALYSIS_ROWS = [
    ("qc", "QC", 276, 408),
    ("relatedness", "Relatedness", 429, 556),
    ("pca", "PCA", 579, 707),
    ("admixture", "ADMIXTURE", 730, 864),
    ("nj", "NJ", 887, 1023),
    ("damage", "Damage pattern", 1046, 1179),
    ("gwas", "GWAS / Selection", 1201, 1334),
    ("f3", "f3 / f4", 1356, 1490),
    ("site", "Site annotation", 1513, 1646),
    ("overlapped", "Overlapped", 1669, 1806),
]

REPORT_ROWS = [
    (370, 766),
    (788, 1151),
    (1173, 1467),
    (1488, 1784),
    (1807, 2168),
]
REPORT_LEFT = (3104, 3544)
REPORT_RIGHT = (3574, 4010)
REPORT_PLOTS = [
    "report-pca",
    "report-admixture",
    "report-heatmap",
    "report-tree",
    "report-manhattan",
    "report-damage",
    "report-tracks",
    "report-venn",
    "report-map",
    "report-regression",
]


def build_svg(page: Image.Image | None = None, labels: list[dict] | None = None) -> str:
    page = load_page() if page is None else page
    if labels is None:
        labels = select_labels(ocr_boxes(page))
    for label in labels:
        size, dx, dy = _place(label["text"], label["x1"] - label["x0"], label["y1"] - label["y0"])
        label["size"], label["dx"], label["dy"] = size, dx, dy
        label["fill"] = _text_fill(label)

    parts: list[str] = []
    parts.append(_rect(0, 0, PAGE_W, PAGE_H, WHITE))

    # Panels. Gaps measured on the source: 741-756, 1761-1777, 3004-3024.
    panels = [
        ("input-panel", 56, 748, "#D6ECFD", "#569DD5"),
        ("processing-panel", 757, 1769, "#E9FDEE", "#6AA571"),
        ("analysis-panel", 1778, 3004, "#FDF4E4", "#BF9D63"),
        ("report-panel", 3025, 4049, "#FFE7E6", "#CA5E60"),
    ]
    for panel_id, x0, x1, body, header in panels:
        width = x1 - x0
        parts.append(f'<g id="{panel_id}">')
        parts.append(_rect(x0, 89, width, 2112, body, 48))
        parts.append(_header(x0, 89, width, 163, header, 48))
        parts.append("</g>")

    # Input paper stacks. Letters are cleared and rewritten as text.
    stacks = [
        ("input-fastq", (150, 390, 530, 830)),
        ("input-bam", (150, 960, 530, 1400)),
        ("input-vcf", (150, 1540, 540, 2030)),
    ]
    parts.append('<g id="input-files">')
    for name, box in stacks:
        icon = isolate(page, box, _labels_inside(labels, box), tolerance=32)
        parts.append(_image(name, icon, box[0], box[1], box[2] - box[0], box[3] - box[1]))
    parts.append("</g>")

    # Processing cards and side notes.
    proc_cards = [
        ("step-trim", 864, 375, 465, 202, "#DDF5E2", "#3C8F44"),
        ("step-map", 864, 702, 466, 198, "#DDF5E2", "#3C8F44"),
        ("step-markdup", 865, 1004, 568, 197, "#DDF5E2", "#3C8F44"),
        ("step-bcftools", 866, 1308, 567, 208, "#DDF5E2", "#3C8F44"),
        ("step-vcf", 869, 1622, 644, 187, "#D7EEFF", "#5B9FD4"),
        ("step-grape", 875, 1908, 659, 202, "#DDF5E2", "#3C8F44"),
        ("note-trim", 1363, 373, 362, 214, "#D4EDFF", "#8EBFDF"),
        ("note-map", 1364, 702, 361, 198, "#D4EDFF", "#8EBFDF"),
    ]
    parts.append('<g id="processing-cards">')
    for name, x, y, w, h, fill, stroke in proc_cards:
        parts.append(f'<g id="{name}">' + _rect(x, y, w, h, fill, 26, stroke, 4) + "</g>")
    parts.append("</g>")

    proc_icons = [
        ("icon-trim", (860, 400, 1090, 560), 30),
        ("icon-map", (880, 720, 1095, 885), 30),
        ("icon-markdup", (880, 1020, 1090, 1185), 30),
        ("icon-bcftools", (890, 1335, 1095, 1495), 30),
        ("icon-vcf", (900, 1655, 1160, 1795), 26),
        ("icon-grape", (890, 1935, 1105, 2095), 30),
        ("icon-genome", (1395, 745, 1510, 875), 22),
    ]
    parts.append('<g id="processing-icons">')
    for name, box, tolerance in proc_icons:
        icon = isolate(page, box, tolerance=tolerance)
        parts.append(_image(name, icon, box[0], box[1], box[2] - box[0], box[3] - box[1]))
    parts.append("</g>")

    parts.append('<g id="arrows">')
    parts.append(_arrow(500, 486, 864, 486))
    parts.append(_arrow(500, 1110, 865, 1110))
    parts.append(_arrow(500, 1713, 869, 1713))
    parts.append(_arrow(1096, 577, 1096, 702))
    parts.append(_arrow(1096, 900, 1096, 1004))
    parts.append(_arrow(1096, 1201, 1096, 1308))
    parts.append(_arrow(1096, 1516, 1096, 1622))
    parts.append(_arrow(1191, 1908, 1191, 1809))
    parts.append(_arrow(1329, 476, 1363, 476, 14))
    parts.append(_arrow(1330, 801, 1364, 801, 14))
    parts.append(
        f'<path d="M1513 1713 H1868 V342" fill="none" stroke="{ARROW}" stroke-width="16" stroke-linejoin="round" stroke-linecap="round"/>'
    )
    for _, _, y0, y1 in ANALYSIS_ROWS:
        parts.append(_arrow(1868, (y0 + y1) / 2, 1992, (y0 + y1) / 2, 16))
    parts.append("</g>")

    parts.append('<g id="analysis-rows">')
    for name, _title, y0, y1 in ANALYSIS_ROWS:
        parts.append(f'<g id="analysis-{name}">')
        parts.append(_rect(1992, y0, 953, y1 - y0, "#FDF4E4", 18, "#E8C4A0", 3))
        icon_box = (2036, y0 + 10, 2232, y1 - 10)
        icon = isolate(page, icon_box, tolerance=26)
        parts.append(_image(f"analysis-{name}-icon", icon, icon_box[0], icon_box[1], icon_box[2] - icon_box[0], icon_box[3] - icon_box[1]))
        parts.append(f'<line x1="2264" y1="{y0 + 18}" x2="2264" y2="{y1 - 18}" stroke="#C8BEB4" stroke-width="3"/>')
        parts.append("</g>")
    parts.append("</g>")

    parts.append('<g id="reference-data">')
    parts.append(_rect(1810, 1836, 1160, 330, "#D6ECFD", 22))
    ref_cards = [
        ("ref-core", 1829, 1934, 269, 222),
        ("ref-pca", 2116, 1935, 293, 220),
        ("ref-vivc", 2428, 1934, 250, 222),
        ("ref-oiv", 2696, 1935, 254, 221),
    ]
    for name, x, y, w, h in ref_cards:
        parts.append(f'<g id="{name}">')
        parts.append(_rect(x, y, w, h, WHITE, 16))
        icon_box = (x + 8, y + 6, x + w - 8, y + int(h * 0.48))
        icon = isolate(page, icon_box, _labels_inside(labels, icon_box), tolerance=18)
        parts.append(_image(f"{name}-icon", icon, icon_box[0], icon_box[1], icon_box[2] - icon_box[0], icon_box[3] - icon_box[1]))
        parts.append("</g>")
    parts.append("</g>")

    parts.append('<g id="report-plots">')
    parts.append(_rect(3560, 258, 430, 86, "#9F262A", 43))
    cursor = isolate(page, (3888, 260, 4055, 390), tolerance=36)
    parts.append(_image("report-cursor", cursor, 3888, 260, 167, 130))
    plot_boxes = []
    for row_index, (y0, y1) in enumerate(REPORT_ROWS):
        for col_index, (x0, x1) in enumerate((REPORT_LEFT, REPORT_RIGHT)):
            plot_boxes.append((REPORT_PLOTS[row_index * 2 + col_index], (x0, y0, x1, y1)))
    for name, box in plot_boxes:
        parts.append(f'<g id="{name}">')
        icon = isolate(page, box, tolerance=30)
        parts.append(_image(name + "-plot", icon, box[0], box[1], box[2] - box[0], box[3] - box[1]))
        parts.append("</g>")
    parts.append("</g>")

    parts.append('<g id="labels">')
    for label in labels:
        x = label["x0"] + label["dx"]
        y = label["y0"] + label["dy"]
        parts.append(
            f'<text x="{x:.1f}" y="{y:.1f}" font-family="{FONT_FAMILY}" font-weight="700" '
            f'font-size="{label["size"]}" fill="{label["fill"]}">{_xml(label["text"])}</text>'
        )
    parts.append("</g>")

    body = "\n".join(parts)
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{PAGE_W}" height="{PAGE_H}" viewBox="0 0 {PAGE_W} {PAGE_H}">\n'
        "<title>GrapeAncestry</title>\n"
        "<desc>Hybrid editable SVG. Layout and text are vectors. Icons and report plots are embedded crops.</desc>\n"
        f"{body}\n</svg>\n"
    )


def assert_svg(svg: str) -> None:
    root = ET.fromstring(svg)
    ns = {"svg": "http://www.w3.org/2000/svg"}
    images = root.findall(".//svg:image", ns) or root.findall(".//image")
    texts = root.findall(".//svg:text", ns) or root.findall(".//text")
    if not images or not texts:
        raise SystemExit("svg is missing images or text")
    for image in images:
        href = image.get("href") or image.get("{http://www.w3.org/1999/xlink}href") or ""
        if not href.startswith("data:image/png;base64,"):
            raise SystemExit(f"image is not embedded: {href[:40]}")
        if 'width="4096"' in ET.tostring(image, encoding="unicode"):
            raise SystemExit("the whole reference page was embedded")
    if "assets/" in svg:
        raise SystemExit("external asset path leaked into the svg")


def main() -> None:
    svg = build_svg()
    assert_svg(svg)
    OUTPUT.write_text(svg, encoding="utf-8")
    print(f"wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes, images {svg.count('<image')}, texts {svg.count('<text')})")


if __name__ == "__main__":
    main()
