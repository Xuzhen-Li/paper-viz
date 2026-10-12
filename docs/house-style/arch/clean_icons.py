"""Remove stray near-transparent pixels from icons/*.png, keeping real anti-aliased edges.

A pixel is noise when its alpha is 1..NOISE_MAX and no visible pixel (alpha > helpers.ALPHA_MIN, the same
threshold the opaque box and the icon check use) lies within RADIUS px. Anti-aliased edge pixels always
sit next to the shape, so they are kept; isolated faint specks in the transparent margin are set to fully
transparent (alpha 0, RGB 0). The visible box (alpha > ALPHA_MIN) does not change.

    python3 docs/house-style/arch/clean_icons.py           # clean in place, print counts
    python3 docs/house-style/arch/clean_icons.py --check   # exit 1 if any icon still has noise
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
ICON_DIR = HERE / "icons"
ALPHA_MIN = 40      # keep in sync with helpers.ALPHA_MIN (visible threshold)
NOISE_MAX = 16      # alpha at or below this may be noise
RADIUS = 2          # px: a faint pixel within this distance of a visible pixel is an edge, not noise


def noise_mask(rgba: np.ndarray) -> np.ndarray:
    a = rgba[..., 3]
    vis = a > ALPHA_MIN
    near = np.zeros_like(vis)
    h, w = vis.shape
    for dy in range(-RADIUS, RADIUS + 1):
        for dx in range(-RADIUS, RADIUS + 1):
            sh = np.zeros_like(vis)
            sh[max(dy, 0):h + min(dy, 0), max(dx, 0):w + min(dx, 0)] = vis[max(-dy, 0):h + min(-dy, 0), max(-dx, 0):w + min(-dx, 0)]
            near |= sh
    return (a > 0) & (a <= NOISE_MAX) & ~near


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="report only; exit 1 if noise remains")
    args = ap.parse_args()
    dirty = 0
    for p in sorted(ICON_DIR.glob("*.png")):
        rgba = np.array(Image.open(p).convert("RGBA"))
        m = noise_mask(rgba)
        n = int(m.sum())
        print(f"{p.name:16s} stray pixels {n}")
        if n and not args.check:
            rgba[m] = 0
            Image.fromarray(rgba, "RGBA").save(p, optimize=True)
        dirty += n
    return 1 if (args.check and dirty) else 0


if __name__ == "__main__":
    sys.exit(main())
