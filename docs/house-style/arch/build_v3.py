"""Rebuild arch_v3.svg and arch_v3.png, then print the font-size / line-width check.

    python3 docs/house-style/arch/build_v3.py                      # rebuild in place
    python3 docs/house-style/arch/build_v3.py --vector-icons X.svg # also write a check copy with the vector icons shown
"""
import argparse, re, shutil, subprocess, sys
from pathlib import Path

import numpy as np

import helpers
from helpers import FS, HERE, LW, PX_PT, SCRIPT
import body


def report(svg_text):
    fig = svg_text.split('<g id="vector-icon-fallback"')[0]
    sizes = [float(s) for s in re.findall(r'<text [^>]*font-size="([\d.]+)"', fig)]
    math = [float(s) for s in re.findall(r'class="math"[^>]*data-size="([\d.]+)"', fig)]
    widths = [float(w) for w in re.findall(r'stroke-width="([\d.]+)"', re.sub(r'<path class="math"[^>]*>', '', fig))]
    rows = [('text, smallest', min(sizes)), ('text, largest', max(sizes)),
            ('formula base, smallest', min(math)), ('formula script (x%.1f), smallest' % SCRIPT, min(math) * SCRIPT),
            ('line width, smallest', min(widths)), ('line width, largest', max(widths))]
    print(f'canvas {helpers.W} px = {helpers.PRINT_MM:g} mm; 1 px = {PX_PT:.4f} pt')
    for name, px in rows:
        print(f'  {name:34s} {px:6.2f} px = {px * PX_PT:5.2f} pt')
    small = [s for s in sizes + [m * SCRIPT for m in math] if s * PX_PT < 6 - 1e-6]
    return small


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--vector-icons', metavar='SVG', help='also write a copy with the vector icon layer shown')
    args = ap.parse_args()
    body.draw(np.random.default_rng(3))
    problems = helpers.check_layout()
    svg = HERE / 'arch_v3.svg'
    helpers.finish(svg)
    if args.vector_icons:
        helpers.finish(args.vector_icons, vector_icons=True)
    small = report(svg.read_text())
    for p in problems:
        print('layout:', p)
    if small:
        print('text under 6 pt:', small)
    if shutil.which('rsvg-convert'):
        subprocess.run(['rsvg-convert', '-w', '2000', '-o', str(HERE / 'arch_v3.png'), str(svg)], check=True)
        if args.vector_icons:
            subprocess.run(['rsvg-convert', '-w', '2000', '-o', str(Path(args.vector_icons).with_suffix('.png')), args.vector_icons], check=True)
    else:
        print('rsvg-convert not found; arch_v3.png not rebuilt')
    sys.exit(1 if (problems or small) else 0)


if __name__ == '__main__':
    main()
