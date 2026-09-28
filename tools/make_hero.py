#!/usr/bin/env python3
"""Build docs/hero.png: white-background contact sheet of figures/**/preview.png."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUT = REPO_ROOT / "docs" / "hero.png"
FONT_CANDIDATES = [
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    Path("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"),
]


def find_previews(root: Path) -> list[Path]:
    return sorted(root.joinpath("figures").rglob("preview.png"))


def load_font(size: int) -> ImageFont.ImageFont:
    for path in FONT_CANDIDATES:
        if path.is_file():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def fit_thumb(im: Image.Image, box_w: int, box_h: int) -> Image.Image:
    im = im.convert("RGBA")
    scale = min(box_w / im.width, box_h / im.height)
    new_size = (max(1, int(im.width * scale)), max(1, int(im.height * scale)))
    return im.resize(new_size, Image.Resampling.LANCZOS)


def build_hero(
    root: Path,
    out: Path,
    cols: int = 11,
    cell_w: int = 160,
    cell_h: int = 110,
    label_h: int = 16,
    pad: int = 8,
    margin: int = 16,
) -> dict:
    previews = find_previews(root)
    if not previews:
        raise SystemExit("no figures/**/preview.png found")

    n = len(previews)
    rows = (n + cols - 1) // cols
    tile_h = cell_h + label_h
    width = margin * 2 + cols * cell_w + (cols - 1) * pad
    height = margin * 2 + rows * tile_h + (rows - 1) * pad

    canvas = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(canvas)
    font = load_font(11)

    for i, path in enumerate(previews):
        r, c = divmod(i, cols)
        x0 = margin + c * (cell_w + pad)
        y0 = margin + r * (tile_h + pad)
        with Image.open(path) as src:
            thumb = fit_thumb(src, cell_w, cell_h)
        tx = x0 + (cell_w - thumb.width) // 2
        ty = y0 + (cell_h - thumb.height) // 2
        if thumb.mode == "RGBA":
            canvas.paste(thumb, (tx, ty), thumb)
        else:
            canvas.paste(thumb, (tx, ty))
        slug = path.parent.name
        # Center slug under the cell
        bbox = draw.textbbox((0, 0), slug, font=font)
        tw = bbox[2] - bbox[0]
        lx = x0 + max(0, (cell_w - tw) // 2)
        ly = y0 + cell_h + 2
        draw.text((lx, ly), slug, fill=(80, 80, 80), font=font)

    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, format="PNG", optimize=True)
    size_b = out.stat().st_size
    if size_b >= 8 * 1024 * 1024:
        # Re-save smaller by slightly reducing cell size once
        raise SystemExit(f"hero.png is {size_b} bytes (>= 8MB); reduce cell size")
    return {
        "count": n,
        "cols": cols,
        "rows": rows,
        "out": str(out.relative_to(root)),
        "bytes": size_b,
        "width": width,
        "height": height,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=REPO_ROOT,
        help="repository root (default: parent of tools/)",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=None,
        help="output path (default: <root>/docs/hero.png)",
    )
    parser.add_argument("--cols", type=int, default=11)
    parser.add_argument("--cell-w", type=int, default=160)
    parser.add_argument("--cell-h", type=int, default=110)
    args = parser.parse_args()
    root = args.root.resolve()
    out = args.out.resolve() if args.out else root / "docs" / "hero.png"
    info = build_hero(root, out, cols=args.cols, cell_w=args.cell_w, cell_h=args.cell_h)
    print(
        f"wrote {info['out']} ({info['bytes']} bytes, "
        f"{info['width']}x{info['height']}, {info['count']} tiles, "
        f"{info['cols']}x{info['rows']})"
    )


if __name__ == "__main__":
    main()
