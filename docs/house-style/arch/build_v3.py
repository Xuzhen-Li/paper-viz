"""Rebuild arch_v3.svg and arch_v3.png, then print the font-size / line-width check.

    python3 docs/house-style/arch/build_v3.py                      # rebuild in place
    python3 docs/house-style/arch/build_v3.py --vector-icons X.svg # also write a check copy with the vector icons shown
"""
import argparse, io, re, shutil, subprocess, sys
from pathlib import Path

import numpy as np
from PIL import Image

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


ICON_TOL = 2.0   # px: max distance between vector twin and bitmap visible centre


def icon_overlap(svg_text, icons, scale=2):
    """Render only the vector icon layer and compare each twin with its bitmap's opaque box."""
    vec = svg_text.split('<g id="vector-icon-fallback"')[1].split('<g id="math-text-fallback"')[0]
    doc = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{helpers.W}" height="{helpers.H}" viewBox="0 0 {helpers.W} {helpers.H}">'
           f'<g>{vec.split(">", 1)[1]}</svg>')
    png = subprocess.run(['rsvg-convert', '-w', str(helpers.W * scale)], input=doc.encode(), capture_output=True, check=True).stdout
    al = Image.open(io.BytesIO(png)).getchannel('A').point(lambda v: 255 if v > helpers.ALPHA_MIN else 0)
    rows = []
    for name, (ix0, iy0, ix1, iy1), (ox0, oy0, ox1, oy1) in icons:
        m = 8
        win = (int((ix0 - m) * scale), int((iy0 - m) * scale), int((ix1 + m) * scale), int((iy1 + m) * scale))
        bb = al.crop(win).getbbox()
        vx0, vy0, vx1, vy1 = [(v + win[k % 2]) / scale for k, v in enumerate(bb)]
        dx = (vx0 + vx1) / 2 - (ox0 + ox1) / 2; dy = (vy0 + vy1) / 2 - (oy0 + oy1) / 2
        rows.append((name, dx, dy, (vx1 - vx0) / (ox1 - ox0), (vy1 - vy0) / (oy1 - oy0)))
    return rows


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
    bad_icons = []
    if shutil.which('rsvg-convert'):
        print('vector icon twin vs bitmap visible area (centre offset px, size ratio w, h):')
        for name, dx, dy, rw, rh in icon_overlap(svg.read_text(), helpers.ICONS):
            flag = '' if max(abs(dx), abs(dy)) <= ICON_TOL else '  <- off by more than %.0f px' % ICON_TOL
            print(f'  {name:10s} dx {dx:+5.1f}  dy {dy:+5.1f}  w {rw:4.2f}  h {rh:4.2f}{flag}')
            if flag:
                bad_icons.append(name)
        subprocess.run(['rsvg-convert', '-w', '2000', '-o', str(HERE / 'arch_v3.png'), str(svg)], check=True)
        if args.vector_icons:
            subprocess.run(['rsvg-convert', '-w', '2000', '-o', str(Path(args.vector_icons).with_suffix('.png')), args.vector_icons], check=True)
    else:
        print('rsvg-convert not found; arch_v3.png not rebuilt')
    sys.exit(1 if (problems or small or bad_icons) else 0)


if __name__ == '__main__':
    main()
