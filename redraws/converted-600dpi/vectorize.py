"""Trace a raster figure into an editable stacked SVG.

This follows the same idea as https://vectorizer.ai/ : cluster the bitmap
into filled regions, fit curves to their outlines, and stack those shapes
so each region stays a separate object. The tracer is visioncortex VTracer.
`simplify.py` then bakes each shape onto the page and drops curve handles
that are already straight, which is what you edit in Inkscape, Illustrator,
or Figma.

Text is outlined, as it is on vectorizer.ai. It scales cleanly, and the
glyphs are paths rather than a font.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import vtracer

from simplify import simplify_svg

HERE = Path(__file__).resolve().parent

# Tuned on this 4096×2308 figure: spline + stacked matches vectorizer.ai,
# and these precision settings kept text overlap with the source at ~0.88.
TRACE = dict(
    colormode="color",
    hierarchical="stacked",
    mode="spline",
    filter_speckle=3,
    color_precision=7,
    layer_difference=12,
    corner_threshold=70,
    length_threshold=3.5,
    max_iterations=10,
    splice_threshold=45,
    path_precision=2,
)


def extract_png(pdf: Path, png: Path) -> None:
    import pymupdf

    doc = pymupdf.open(pdf)
    page = doc[0]
    images = page.get_images(full=True)
    if not images:
        pix = page.get_pixmap(dpi=600)
    else:
        pix = pymupdf.Pixmap(doc, images[0][0])
        if pix.n >= 4 and pix.alpha:
            pix = pymupdf.Pixmap(pymupdf.csRGB, pix)
    pix.save(png)


def _wrap(simplified: str, width: int, height: int) -> str:
    start = simplified.find("<svg")
    end = simplified.find(">", start)
    body = simplified[end + 1 :]
    if "</svg>" in body:
        body = body[: body.rfind("</svg>")]
    header = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
<title>可编辑矢量图</title>
<desc>Stacked color trace of the source figure, in the manner of vectorizer.ai. Each path is one filled shape in page coordinates. Open this file in Inkscape, Illustrator, or Figma to recolor, delete, or reshape a region. Outlines are paths, not live text.</desc>
'''
    return header + body.strip() + "\n</svg>\n"


def vectorize(pdf: Path, svg_out: Path, eps: float = 0.6) -> None:
    png = svg_out.with_suffix(".source.png")
    raw = svg_out.with_suffix(".raw.svg")
    extract_png(pdf, png)
    vtracer.convert_image_to_svg_py(str(png), str(raw), **TRACE)
    from PIL import Image

    width, height = Image.open(png).size
    simplified = simplify_svg(raw.read_text(encoding="utf-8"), eps=eps)
    svg_out.write_text(_wrap(simplified, width, height), encoding="utf-8")
    raw.unlink()
    png.unlink()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "pdf",
        nargs="?",
        type=Path,
        default=HERE / "source.pdf",
        help="Raster PDF to trace (default: source.pdf next to this script)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=HERE / "figure.svg",
    )
    parser.add_argument("--eps", type=float, default=0.6, help="Max straighten error in pixels")
    args = parser.parse_args()
    vectorize(args.pdf, args.output, eps=args.eps)
    print(f"wrote {args.output} ({args.output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
