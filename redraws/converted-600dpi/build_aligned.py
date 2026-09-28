"""Put editable text back on the original figure, in the original places.

The page artwork stays the raster from converted-600dpi.pdf. Each recognized
label is painted out and replaced by an SVG text element at that same box.
"""

from __future__ import annotations

import base64
import io
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFont

HERE = Path(__file__).resolve().parent
SOURCE_PDF = HERE / "source.pdf"
OUTPUT = HERE / "figure.svg"
FONT_PATH = "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf"

PAGE_W, PAGE_H = 4096, 2308


def load_page() -> Image.Image:
    import pymupdf

    doc = pymupdf.open(SOURCE_PDF)
    pix = pymupdf.Pixmap(doc, doc[0].get_images(full=True)[0][0])
    return Image.frombytes("RGB", (pix.width, pix.height), pix.samples)


def ocr_boxes(image: Image.Image) -> list[dict]:
    cache = HERE / "_ocr_boxes.json"
    if cache.exists():
        return json.loads(cache.read_text(encoding="utf-8"))
    from rapidocr_onnxruntime import RapidOCR

    ocr = RapidOCR()
    width, height = image.size
    found = []
    for row in range(4):
        for col in range(3):
            x0 = max(0, col * width // 3 - 100)
            y0 = max(0, row * height // 4 - 80)
            x1 = min(width, (col + 1) * width // 3 + 100)
            y1 = min(height, (row + 1) * height // 4 + 80)
            tile = image.crop((x0, y0, x1, y1))
            buf = io.BytesIO()
            tile.save(buf, format="PNG")
            result, _ = ocr(buf.getvalue())
            if not result:
                continue
            for box, text, score in result:
                if score < 0.6 or not str(text).strip():
                    continue
                xs = [p[0] + x0 for p in box]
                ys = [p[1] + y0 for p in box]
                found.append({
                    "x0": int(min(xs)), "y0": int(min(ys)),
                    "x1": int(max(xs)), "y1": int(max(ys)),
                    "text": str(text).strip(), "score": float(score),
                })
    cache.write_text(json.dumps(found, ensure_ascii=False), encoding="utf-8")
    return found


def _center_inside(inner: dict, outer: dict) -> bool:
    cx = (inner["x0"] + inner["x1"]) / 2
    cy = (inner["y0"] + inner["y1"]) / 2
    return outer["x0"] - 8 <= cx <= outer["x1"] + 8 and outer["y0"] - 8 <= cy <= outer["y1"] + 8


def _near(a: dict, b: dict, dx: int = 40, dy: int = 24) -> bool:
    return abs((a["x0"] + a["x1"]) / 2 - (b["x0"] + b["x1"]) / 2) < max(dx, (a["x1"] - a["x0"])) and abs(a["y0"] - b["y0"]) < dy


def select_labels(raw: list[dict]) -> list[dict]:
    """Drop split fragments and noise. Keep one box per real label."""
    noise = {"9", "8", "日", "目", "一三", "Ada", "PE:", "SE", "dup", "ern", "tion", "ls", "alling", "on", "CF", "descri", "sites", "Ancestry", "PROCESSIL", "ESSING", "GrapeAncestr"}
    items = [dict(item) for item in raw if item["text"] not in noise and item["score"] >= 0.75]
    # The second base on row 2 is a low-confidence "c".
    for item in raw:
        if item["text"].lower() == "c" and item["x0"] < 500 and item["y0"] > 1700:
            fixed = dict(item)
            fixed["text"] = "C"
            items.append(fixed)

    def union_text(text: str, parts: list[str]) -> dict | None:
        hits = [item for item in raw if item["text"] in parts]
        if len(hits) < 2:
            return None
        return {
            "x0": min(item["x0"] for item in hits),
            "y0": min(item["y0"] for item in hits),
            "x1": max(item["x1"] for item in hits),
            "y1": max(item["y1"] for item in hits),
            "text": text,
            "score": 1.0,
        }

    for merged in (
        union_text("PROCESSING", ["PROCESSIL", "ESSING"]),
        union_text("GrapeAncestry", ["GrapeAncestr", "Ancestry"]),
    ):
        if merged:
            items.append(merged)
    # The processing-column VCF was only read as "CF".
    for item in raw:
        if item["text"] == "CF" and 1100 < item["x0"] < 1600:
            fixed = dict(item)
            fixed["text"] = "VCF"
            fixed["x0"] = max(0, item["x0"] - 40)
            items.append(fixed)
    for item in items:
        if item["text"] == "PCA/ ADMIXTURE":
            item["text"] = "PCA/ADMIXTURE"

    items.sort(key=lambda item: (-len(item["text"]), -item["score"]))
    kept: list[dict] = []
    for item in items:
        if any(_center_inside(item, other) and len(other["text"]) >= len(item["text"]) for other in kept):
            continue
        if any(item["text"] in other["text"] and _near(item, other) for other in kept):
            continue
        kept.append(item)
    kept.sort(key=lambda item: (item["y0"], item["x0"]))
    return kept


def _background(arr: np.ndarray, box: dict) -> np.ndarray:
    height, width = arr.shape[:2]
    x0 = max(0, box["x0"] - 12)
    y0 = max(0, box["y0"] - 12)
    x1 = min(width, box["x1"] + 12)
    y1 = min(height, box["y1"] + 12)
    ring = arr[y0:y1, x0:x1]
    inner = np.zeros(ring.shape[:2], dtype=bool)
    ix0, iy0 = box["x0"] - x0, box["y0"] - y0
    ix1, iy1 = box["x1"] - x0, box["y1"] - y0
    inner[iy0:iy1, ix0:ix1] = True
    samples = ring[~inner]
    if len(samples) < 10:
        samples = ring.reshape(-1, 3)
    return np.median(samples, axis=0)


def _paint_color(image: np.ndarray, box: dict, background: np.ndarray) -> np.ndarray:
    """Median of the quiet pixels inside the box. The ring can mix in a neighboring panel."""
    x0, y0, x1, y1 = box["x0"], box["y0"], box["x1"], box["y1"]
    patch = image[y0:y1, x0:x1].astype(np.int16)
    if patch.size == 0:
        return background
    distance = np.abs(patch - background.astype(np.int16)).sum(axis=2)
    quiet = patch[distance <= 80]
    if len(quiet) < 30:
        return background
    return np.median(quiet, axis=0)


def _hex(color: np.ndarray) -> str:
    return "#{:02X}{:02X}{:02X}".format(*(int(max(0, min(255, v))) for v in color))


def paint_out_text(image: Image.Image, labels: list[dict]) -> Image.Image:
    arr = np.array(image).copy()
    for label in labels:
        color = label["paint"]
        x0 = max(0, label["x0"] - 2)
        y0 = max(0, label["y0"] - 2)
        x1 = min(arr.shape[1], label["x1"] + 2)
        y1 = min(arr.shape[0], label["y1"] + 2)
        arr[y0:y1, x0:x1] = color
    return Image.fromarray(arr)


def _ink_color(image: np.ndarray, box: dict, background: np.ndarray) -> str:
    x0, y0, x1, y1 = box["x0"], box["y0"], box["x1"], box["y1"]
    patch = image[y0:y1, x0:x1].astype(np.int16)
    if patch.size == 0:
        return "#17315C"
    distance = np.abs(patch - background.astype(np.int16)).sum(axis=2)
    ink = patch[distance > 80]
    if len(ink) < 8:
        # White type on a colored header: ink is lighter than the bar.
        light = patch[patch.mean(axis=2) > background.mean() + 40]
        ink = light if len(light) >= 8 else patch.reshape(-1, 3)
    color = np.median(ink, axis=0)
    return _hex(color)


def place_text(text: str, box_w: int, box_h: int) -> tuple[int, float, float]:
    """Font size and offsets from the box origin. The glyph bbox stays inside the box."""
    size = max(8, int(box_h * 0.98))
    while size > 8:
        font = ImageFont.truetype(FONT_PATH, size)
        # anchor "ls" is the baseline, which is what SVG and PDF use.
        left, top, right, bottom = font.getbbox(text, anchor="ls")
        if (right - left) <= box_w and (bottom - top) <= box_h:
            return size, float(-left), float(-top)
        size -= 1
    font = ImageFont.truetype(FONT_PATH, 8)
    left, top, _, _ = font.getbbox(text, anchor="ls")
    return 8, float(-left), float(-top)


def _font_face() -> str:
    data = base64.b64encode(Path(FONT_PATH).read_bytes()).decode("ascii")
    return (
        "<defs><style><![CDATA[\n"
        "@font-face{font-family:'Noto Sans';font-weight:700;"
        f"src:url(data:font/ttf;base64,{data}) format('truetype');}}\n"
        "]]></style></defs>\n"
    )


def compose(page: Image.Image | None = None, labels: list[dict] | None = None):
    """Return the artwork with letters painted out, and the replacement labels."""
    page = load_page() if page is None else page
    original = np.array(page)
    raw = ocr_boxes(page) if labels is None else labels
    labels = select_labels(raw) if labels is None else labels
    # Ink and paint colors have to be measured before the letters are painted out.
    for label in labels:
        background = _background(original, label)
        label["color"] = _ink_color(original, label, background)
        label["paint"] = _paint_color(original, label, background)
        label["size"], label["dx"], label["dy"] = place_text(
            label["text"], label["x1"] - label["x0"], label["y1"] - label["y0"]
        )
    return paint_out_text(page, labels), labels


def _svg_text(labels: list[dict]) -> str:
    texts = []
    for label in labels:
        x = label["x0"] + label["dx"]
        y = label["y0"] + label["dy"]
        body = label["text"].replace("&", "&amp;").replace("<", "&lt;")
        texts.append(
            f'<text x="{x:.1f}" y="{y:.1f}" font-family="Noto Sans" font-weight="700" '
            f'font-size="{label["size"]}" fill="{label["color"]}">{body}</text>'
        )
    return "\n".join(texts)


def svg_from(cleaned: Image.Image, labels: list[dict], image_href: str = "figure.png") -> str:
    """SVG whose picture is a sibling file. A data-URI image is stripped when the file is opened on GitHub."""
    width, height = cleaned.size
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{width}" height="{height}" viewBox="0 0 {width} {height}">\n'
        "<title>可编辑文字</title>\n"
        "<desc>Same figure as converted-600dpi.pdf. Labels are text elements. Keep figure.png beside this file.</desc>\n"
        + _font_face()
        + f'<image width="{width}" height="{height}" href="{image_href}" xlink:href="{image_href}"/>\n'
        + _svg_text(labels)
        + "\n</svg>\n"
    )


def build_svg(page: Image.Image | None = None, labels: list[dict] | None = None, image_href: str = "figure.png") -> str:
    cleaned, labels = compose(page, labels)
    return svg_from(cleaned, labels, image_href)


def _rgb(hex_color: str) -> tuple[float, float, float]:
    value = hex_color.lstrip("#")
    return tuple(int(value[i:i + 2], 16) / 255 for i in (0, 2, 4))


def write_pdf(cleaned: Image.Image, labels: list[dict], path: Path) -> None:
    import pymupdf

    width, height = cleaned.size
    doc = pymupdf.open()
    page = doc.new_page(width=width, height=height)
    buf = io.BytesIO()
    cleaned.save(buf, format="PNG")
    page.insert_image(page.rect, stream=buf.getvalue())
    page.insert_font(fontname="NotoSans", fontfile=FONT_PATH)
    for label in labels:
        page.insert_text(
            pymupdf.Point(label["x0"] + label["dx"], label["y0"] + label["dy"]),
            label["text"],
            fontname="NotoSans",
            fontsize=label["size"],
            color=_rgb(label["color"]),
        )
    doc.save(path, deflate=True, garbage=4)
    doc.close()


def main() -> None:
    import zipfile

    cleaned, labels = compose()
    png_path = HERE / "figure.png"
    pdf_path = HERE / "figure.pdf"
    zip_path = HERE / "figure.zip"
    cleaned.save(png_path, format="PNG", optimize=True)
    svg = svg_from(cleaned, labels)
    OUTPUT.write_text(svg, encoding="utf-8")
    write_pdf(cleaned, labels, pdf_path)
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        bundle.write(png_path, "figure.png")
        bundle.write(OUTPUT, "figure.svg")
    print(
        f"wrote {OUTPUT.name} {OUTPUT.stat().st_size} bytes, "
        f"png {png_path.stat().st_size}, pdf {pdf_path.stat().st_size}, "
        f"zip {zip_path.stat().st_size}, texts {svg.count('<text')}"
    )


if __name__ == "__main__":
    main()
