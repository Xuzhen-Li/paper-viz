#!/usr/bin/env python3
"""selective-sweep-concept: one spec -> figure.svg + template.drawio + preview.png (600 dpi).

Self-contained generator. Run from any directory:
    python3 figures/schematic/selective-sweep-concept/build.py
Needs Python >= 3.8, Pillow, the Arial or Liberation Sans font (same widths; set PV_FONT_DIR
if it is not found) and rsvg-convert (librsvg2-bin) for the PNG. Outputs are written next to
this file. Exits non-zero if any label leaves the canvas or its box, labels overlap, or a
font size is below 6 pt.
"""
import html, itertools, math, os, random, re, subprocess, sys
from xml.sax.saxutils import quoteattr
from PIL import Image, ImageFont

# ======================================================================= drawing kit

PT = 25.4 / 72          # mm per pt
K = 72 / 25.4           # draw.io units (pt) per mm
SW = 0.5 * PT           # 0.5 pt stroke in mm
# Arial for text metrics; Liberation Sans has the same widths and is the fallback.
_FONT_CANDIDATES = {
    False: ['Arial.TTF', 'Arial.ttf', 'arial.ttf', 'LiberationSans-Regular.ttf'],
    True: ['Arialbd.TTF', 'Arial_Bold.ttf', 'arialbd.ttf', 'LiberationSans-Bold.ttf'],
}
_FONT_DIRS = [os.environ.get('PV_FONT_DIR', ''), os.path.expanduser('~/.local/share/fonts'),
              '/usr/share/fonts/truetype/msttcorefonts', '/usr/share/fonts/truetype/liberation',
              '/usr/share/fonts/truetype/liberation2', '/usr/share/fonts/liberation-sans',
              '/Library/Fonts', '/System/Library/Fonts/Supplemental', 'C:/Windows/Fonts']
_F = {}
def _font(bold, italic=False):
    bold = bool(bold)
    if bold not in _F:
        for d in _FONT_DIRS:
            for n in _FONT_CANDIDATES[bold]:
                p = os.path.join(d, n) if d else ''
                if p and os.path.exists(p):
                    _F[bold] = ImageFont.truetype(p, 1000)
                    break
            if bold in _F:
                break
        else:
            raise SystemExit('Arial or Liberation Sans not found (set PV_FONT_DIR)')
    return _F[bold]

PALETTE = set(x.upper() for x in '''#1F72AE #F77E12 #119B76 #CC312C #595594 #62B4E7 #E6C32A #A8127F #8A4C38
#1D7CBB #4A82B0 #8EBDDA #DEE4F0 #F7F7F7 #F6DEDE #E19193 #C4454B #CB2223
#000000 #3A9CFE #F79423 #FD3B3B #9C2125 #FBD6A0 #F5BA7A #F38F64 #CC635F #965459
#333333 #6B6B6B #757575 #BFBFBF #E0E0E0 #F0F0F0'''.split())

def R(text, **kw):            # rich-text run
    return (text, kw)

def run_width_mm(runs, size_pt, bold=False):
    w = 0
    for t, kw in runs:
        s = size_pt * (0.7 if kw.get('sup') else 1)
        f = _font(kw.get('bold', bold), kw.get('italic', False))
        w += f.getlength(t) / 1000 * s * PT
    return w

class Fig:
    def __init__(self, name, w, h):
        self.name, self.w, self.h = name, w, h
        self.items = []
        self.textboxes = []   # (bbox, label, container)

    def rect(self, x, y, w, h, stroke='#000000', fill=None, dash=False, sw=0.5):
        self.items.append(dict(k='rect', x=x, y=y, w=w, h=h, stroke=stroke, fill=fill, dash=dash, sw=sw))
        return (x, y, w, h)

    def line(self, pts, stroke='#333333', dash=False, arrow=False, sw=0.5):
        self.items.append(dict(k='line', pts=pts, stroke=stroke, dash=dash, arrow=arrow, sw=sw))

    def text(self, x, y, runs, size, anchor='start', color='#000000', bold=False,
             rotate=0, inside=None, check=True):
        """x,y: anchor point on baseline (rotate=0) or line-box centre (rotate=-90)."""
        if isinstance(runs, str):
            runs = [R(runs)]
        em = size * PT
        tw = run_width_mm(runs, size, bold)
        self.items.append(dict(k='text', x=x, y=y, runs=runs, size=size, anchor=anchor,
                               color=color, bold=bold, rotate=rotate, tw=tw))
        if rotate == 0:
            x0 = {'start': x, 'middle': x - tw/2, 'end': x - tw}[anchor]
            bb = (x0, y - 0.74*em, x0 + tw, y + 0.21*em)
        else:   # -90 about centre (x,y): width runs vertically
            bb = (x - 0.48*em, y - tw/2, x + 0.48*em, y + tw/2)
        if check:
            self.textboxes.append((bb, ''.join(t for t, _ in runs), inside))
        return tw

    # ------------------------------------------------------------ checks
    def check(self):
        errs = []
        for bb, lab, box in self.textboxes:
            if bb[0] < 0 or bb[1] < 0 or bb[2] > self.w or bb[3] > self.h:
                errs.append(f'outside canvas: {lab!r} {bb}')
            if box:
                bx, by, bw, bh = box
                if bb[0] < bx + 0.3 or bb[2] > bx + bw - 0.3 or bb[1] < by + 0.2 or bb[3] > by + bh - 0.2:
                    errs.append(f'outside its box: {lab!r} bb={tuple(round(v,2) for v in bb)} box={box}')
        for (a, la, _), (b, lb, _) in itertools.combinations(self.textboxes, 2):
            if a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]:
                errs.append(f'overlap: {la!r} x {lb!r}')
        return errs

    # ------------------------------------------------------------ SVG
    def svg(self):
        o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w:.3f}mm" height="{self.h:.3f}mm" '
             f'viewBox="0 0 {self.w:.3f} {self.h:.3f}" font-family="Arial, Helvetica, sans-serif">',
             f'<title>{self.name}</title>']
        da = f' stroke-dasharray="{0.6:.3f} {0.6:.3f}"'
        for it in self.items:
            if it['k'] == 'rect':
                fill = it['fill'] or 'none'
                o.append(f'<rect x="{it["x"]:.3f}" y="{it["y"]:.3f}" width="{it["w"]:.3f}" height="{it["h"]:.3f}" '
                         f'fill="{fill}" stroke="{it["stroke"] or "none"}" stroke-width="{it["sw"]*PT:.4f}"'
                         + (da if it['dash'] else '') + '/>')
            elif it['k'] == 'line':
                pts = list(it['pts'])
                head = None
                if it['arrow']:
                    (x1, y1), (x2, y2) = pts[-2], pts[-1]
                    L = ((x2-x1)**2 + (y2-y1)**2) ** .5
                    ux, uy = (x2-x1)/L, (y2-y1)/L
                    k_ = max(1.0, it['sw'] / 0.5) ** 0.5
                    al, aw = 1.2 * k_, 0.45 * k_
                    bx, by = x2 - ux*al, y2 - uy*al
                    head = [(x2, y2), (bx - uy*aw, by + ux*aw), (bx + uy*aw, by - ux*aw)]
                    pts[-1] = (x2 - ux*al*0.8, y2 - uy*al*0.8)
                d = ' '.join(f'{x:.3f},{y:.3f}' for x, y in pts)
                o.append(f'<polyline points="{d}" fill="none" stroke="{it["stroke"]}" stroke-width="{it["sw"]*PT:.4f}" stroke-linejoin="round"'
                         + (da if it['dash'] else '') + '/>')
                if head:
                    d = ' '.join(f'{x:.3f},{y:.3f}' for x, y in head)
                    o.append(f'<polygon points="{d}" fill="{it["stroke"]}" stroke="none"/>')
            else:
                em = it['size'] * PT
                x, y = it['x'], it['y']
                tr = ''
                if it['rotate']:
                    tr = f' transform="rotate({it["rotate"]} {x:.3f} {y:.3f})"'
                    y = y + 0.3465*em
                attrs = (f'x="{x:.3f}" y="{y:.3f}" font-size="{em:.4f}" fill="{it["color"]}" '
                         f'text-anchor="{it["anchor"]}"' + (' font-weight="bold"' if it['bold'] else '') + tr)
                spans = []
                for t, kw in it['runs']:
                    a = ''
                    if kw.get('italic'): a += ' font-style="italic"'
                    if 'bold' in kw: a += f' font-weight="{"bold" if kw["bold"] else "normal"}"'
                    if kw.get('color'): a += f' fill="{kw["color"]}"'
                    if kw.get('sup'):
                        a += f' font-size="{em*0.7:.4f}" baseline-shift="super"'
                    spans.append(f'<tspan{a}>{html.escape(t, quote=False)}</tspan>')
                o.append(f'<text {attrs} xml:space="preserve">' + ''.join(spans) + '</text>')
        o.append('</svg>')
        return '\n'.join(o)

    # ------------------------------------------------------------ draw.io
    def drawio(self):
        cells = []
        n = itertools.count(2)
        def dash_style(d):
            return 'dashed=1;dashPattern=3.4 3.4;' if d else ''
        for it in self.items:
            i = next(n)
            if it['k'] == 'rect':
                st = (f'rounded=0;whiteSpace=wrap;html=1;fillColor={it["fill"] or "none"};'
                      f'strokeColor={it["stroke"] or "none"};strokeWidth={it["sw"]:g};' + dash_style(it['dash']))
                cells.append(f'<mxCell id="c{i}" value="" style="{st}" vertex="1" parent="1">'
                             f'<mxGeometry x="{it["x"]*K:.2f}" y="{it["y"]*K:.2f}" width="{it["w"]*K:.2f}" '
                             f'height="{it["h"]*K:.2f}" as="geometry"/></mxCell>')
            elif it['k'] == 'line':
                pts = it['pts']
                st = (f'endArrow={"block;endFill=1;endSize=3.4" if it["arrow"] else "none"};startArrow=none;html=1;'
                      f'rounded=0;strokeColor={it["stroke"]};strokeWidth={it["sw"]:g};' + dash_style(it['dash']))
                mids = ''.join(f'<mxPoint x="{x*K:.2f}" y="{y*K:.2f}"/>' for x, y in pts[1:-1])
                cells.append(f'<mxCell id="c{i}" value="" style="{st}" edge="1" parent="1">'
                             f'<mxGeometry relative="1" as="geometry">'
                             f'<mxPoint x="{pts[0][0]*K:.2f}" y="{pts[0][1]*K:.2f}" as="sourcePoint"/>'
                             f'<mxPoint x="{pts[-1][0]*K:.2f}" y="{pts[-1][1]*K:.2f}" as="targetPoint"/>'
                             + (f'<Array as="points">{mids}</Array>' if mids else '') +
                             '</mxGeometry></mxCell>')
            else:
                em = it['size'] * PT
                w = it['tw'] + 0.8  # small slack for browser metrics
                h = 1.2 * em
                if it['rotate']:
                    cx, cy = it['x'], it['y']
                else:
                    x0 = {'start': it['x'] - 0.4, 'middle': it['x'] - w/2, 'end': it['x'] - w + 0.4}[it['anchor']]
                    cx, cy = x0 + w/2, it['y'] - 0.9465*em + h/2
                val = ''
                for t, kw in it['runs']:
                    s = html.escape(t, quote=False)
                    if kw.get('sup'): s = f'<sup>{s}</sup>'
                    if kw.get('italic'): s = f'<i>{s}</i>'
                    if kw.get('bold'): s = f'<b>{s}</b>'
                    if kw.get('bold') is False and it['bold']: s = f'<span style="font-weight:normal">{s}</span>'
                    if kw.get('color'): s = f'<font color="{kw["color"]}">{s}</font>'
                    val += s
                align = {'start': 'left', 'middle': 'center', 'end': 'right'}[it['anchor']]
                st = (f'text;html=1;whiteSpace=nowrap;fontFamily=Arial;fontSize={it["size"]:g};'
                      f'fontColor={it["color"]};align={align};verticalAlign=middle;spacing=0;'
                      f'strokeColor=none;fillColor=none;fontStyle={1 if it["bold"] else 0};'
                      + (f'rotation={it["rotate"]};' if it['rotate'] else ''))
                cells.append(f'<mxCell id="c{i}" value={quoteattr(val)} style="{st}" vertex="1" parent="1">'
                             f'<mxGeometry x="{(cx-w/2)*K:.2f}" y="{(cy-h/2)*K:.2f}" width="{w*K:.2f}" '
                             f'height="{h*K:.2f}" as="geometry"/></mxCell>')
        pw, ph = round(self.w*K), round(self.h*K)
        return ('<mxfile host="paper-viz" type="device">\n'
                f'<diagram id="{self.name}" name="{self.name}">\n'
                f'<mxGraphModel dx="{pw}" dy="{ph}" grid="0" gridSize="1" guides="1" tooltips="1" connect="0" arrows="1" '
                f'fold="1" page="1" pageScale="1" pageWidth="{pw}" pageHeight="{ph}" math="0" shadow="0">\n'
                '<root>\n<mxCell id="0"/>\n<mxCell id="1" parent="0"/>\n'
                + '\n'.join(cells) +
                '\n</root>\n</mxGraphModel>\n</diagram>\n</mxfile>\n')


# ======================================================================= figure

OUT = os.path.dirname(os.path.abspath(__file__))   # writes next to this script

W, H = 183, 89                       # 4 x 2 cells
f = Fig('selective-sweep-concept', W, H)
RED = '#CC312C'
INK, GREY = '#333333', '#6B6B6B'
BAR, FOUNDER_BG = '#E0E0E0', '#F6DEDE'
SITE_COLS = ['#1F72AE', '#F77E12', '#119B76', '#595594', '#62B4E7', '#E6C32A', '#A8127F', '#8A4C38']

rng = random.Random(7)
NH, NS = 8, 16                       # haplotypes, neutral segregating sites
BW = 62.0                            # bar length (mm)
L0, R0 = 8.0, 119.0                  # left x of before / after bars
BH, PITCH, Y0 = 2.0, 3.3, 9.0        # bar height, pitch, first bar top
SITE = 0.5                           # selected site, fraction along bar

# neutral sites: fractional positions, avoid the selected site itself
pos = [0.03 + 0.94 * (i + 0.5 + rng.uniform(-0.3, 0.3)) / NS for i in range(NS)]   # spread, jittered
pos = [p if abs(p - SITE) > 0.02 else p + 0.04 for p in pos]
col = [SITE_COLS[i % len(SITE_COLS)] for i in range(NS)]
# before: each haplotype carries a distinct random set of derived alleles
before = [[rng.random() < 0.42 for _ in range(NS)] for _ in range(NH)]
FOUNDER = 2                          # haplotype on which the favourable mutation arose

# after: founder block around the site; beyond a recombination breakpoint each haplotype
# carries the alleles of some other pre-sweep background
after = []
blocks = []
left_d = [0.10, 0.22, 0.15, 0.35, 0.12, 0.27, 0.18, 0.31]
right_d = [0.24, 0.13, 0.30, 0.17, 0.36, 0.11, 0.21, 0.28]
for h in range(NH):
    a, b = SITE - left_d[h], SITE + right_d[h]
    bgL = (h + 3) % NH if (h + 3) % NH != FOUNDER else (h + 4) % NH
    bgR = (h + 5) % NH if (h + 5) % NH != FOUNDER else (h + 6) % NH
    row = []
    for i, p in enumerate(pos):
        src = FOUNDER if a <= p <= b else (bgL if p < a else bgR)
        row.append(before[src][i])
    after.append(row)
    blocks.append((a, b))

def haps(x0, rows, founder_blocks=None, selected=False):
    for h, row in enumerate(rows):
        y = Y0 + h * PITCH
        f.rect(x0, y, BW, BH, stroke=None, fill=BAR)
        if founder_blocks:
            a, b = founder_blocks[h]
            if b > a:
                f.rect(x0 + a * BW, y, (b - a) * BW, BH, stroke=None, fill=FOUNDER_BG)
        for i, p in enumerate(pos):
            if row[i]:
                f.rect(x0 + p * BW - 0.3, y - 0.25, 0.6, BH + 0.5, stroke=None, fill=col[i])
        if selected:
            f.rect(x0 + SITE * BW - 0.4, y - 0.45, 0.8, BH + 0.9, stroke=None, fill=RED)

# ---------------------------------------------------------------- top row
f.text(L0, 5.0, 'Before sweep', 8, bold=True)
f.text(R0, 5.0, 'After sweep', 8, bold=True)
haps(L0, before, [(0.0, 1.0) if h == FOUNDER else (0.0, 0.0) for h in range(NH)])
haps(R0, after, blocks, selected=True)
f.text(L0 + BW / 2, Y0 + NH * PITCH + 2.6, 'High haplotype diversity', 7, anchor='middle', color=GREY)

# identical block bracket above the after panel
ia = max(a for a, _ in blocks); ib = min(b for _, b in blocks)
xa, xb, yb = R0 + ia * BW, R0 + ib * BW, Y0 - 1.6
f.line([(xa, yb + 0.8), (xa, yb), (xb, yb), (xb, yb + 0.8)], stroke=INK)
f.text((xa + xb) / 2, yb - 0.9, 'Identical block', 7, anchor='middle')
# selected-site marker below the after panel
xs = R0 + SITE * BW
ybot = Y0 + (NH - 1) * PITCH + BH
f.line([(xs, ybot + 3.4), (xs, ybot + 0.6)], stroke=RED, arrow=True, sw=0.7)
f.text(xs, ybot + 6.2, 'Selected site', 7, anchor='middle', color=RED)

# ---------------------------------------------------------------- middle: process
mx0, mx1 = L0 + BW + 5.0, R0 - 5.0
# frequency trajectory inset (qualitative)
ax0, ax1, ay0, ay1 = mx0 + 4.0, mx1 - 1.0, 9.5, 24.0
f.line([(ax0, ay0), (ax0, ay1), (ax1, ay1)], stroke=INK)
f.text(ax0 - 1.6, (ay0 + ay1) / 2, 'Frequency', 7, anchor='middle', rotate=-90)
f.text((ax0 + ax1) / 2, ay1 + 3.0, 'Time', 7, anchor='middle')
pts = []
for k in range(61):
    t = k / 60
    v = 1 / (1 + math.exp(-11 * (t - 0.5)))
    v = (v - 1 / (1 + math.exp(5.5))) / (1 - 2 / (1 + math.exp(5.5)))
    pts.append((ax0 + 0.6 + t * (ax1 - ax0 - 1.2), ay1 - 0.6 - v * (ay1 - ay0 - 2.0)))
f.line(pts, stroke=RED, sw=1.2)
# main arrow + steps
yA = 31.5
f.line([(mx0, yA), (mx1, yA)], stroke=INK, arrow=True, sw=1.0)
steps = ['Favourable mutation arises', 'Selected', 'Rises in frequency']
for k, s in enumerate(steps):
    f.text((mx0 + mx1) / 2, yA + 4.0 + k * 3.3, s, 7, anchor='middle', color=RED if k == 0 else '#000000')

# ---------------------------------------------------------------- bottom: pi vs position
PY0, PY1 = 51.0, 79.0                # plot area top / bottom
PI0 = PY0 + 5.0                      # pre-sweep pi level (y)
def axes(x0):
    f.line([(x0, PY0), (x0, PY1), (x0 + BW, PY1)], stroke=INK)
    f.text(x0 - 1.6, (PY0 + PY1) / 2, 'Diversity (π)', 8, anchor='middle', rotate=-90)
    f.text(x0 + BW / 2, PY1 + 3.6, 'Position along chromosome', 8, anchor='middle')

def noise(x, seed):
    return 0.45 * math.sin(x * 0.9 + seed) + 0.3 * math.sin(x * 2.3 + 2 * seed)

axes(L0)
pts = [(L0 + 0.8 + t * (BW - 1.6), PI0 + noise(t * 40, 1)) for t in [k / 120 for k in range(121)]]
f.line(pts, stroke=INK, sw=1.5)

axes(R0)
f.line([(R0 + 0.5, PI0), (R0 + BW, PI0)], stroke='#757575', dash=True)
f.text(R0 + 1.2, PI0 - 1.4, 'Pre-sweep level', 7, anchor='start', color=GREY)
f.line([(xs, PY0 + 1.2), (xs, PY1)], stroke=RED, dash=True)
LSC = 0.11 * BW
pts = []
for k in range(241):
    t = k / 240
    x = R0 + 0.8 + t * (BW - 1.6)
    d = abs(x - xs)
    v = 1 - math.exp(-(d / LSC) ** 1.3)
    y = PY1 - 0.8 - v * (PY1 - 0.8 - PI0) + noise(t * 40, 4) * v
    pts.append((x, y))
f.line(pts, stroke=INK, sw=1.5)
f.text(xs, PY0 + 0.2, 'Trough at selected site', 7, anchor='middle', color=RED)
f.text(R0 + BW * 0.84, PY1 - 6.0, 'Recovers via', 7, anchor='middle', color=GREY)
f.text(R0 + BW * 0.84, PY1 - 3.3, 'recombination', 7, anchor='middle', color=GREY)

# ---------------------------------------------------------------- legend (middle bottom)
lx, ly = mx0 + 0.5, PY0 + 1.0
def key_tick(y, c, label):
    f.rect(lx, y - 1.9, 0.6, 2.4, stroke=None, fill=c)
    f.text(lx + 2.2, y, label, 7)
key_tick(ly + 2.0, SITE_COLS[0], 'Neutral variant')
key_tick(ly + 5.6, RED, 'Favourable allele')
f.rect(lx - 0.2, ly + 7.3, 1.6, 2.2, stroke=None, fill=FOUNDER_BG)
f.text(lx + 2.2, ly + 9.2, 'Founder haplotype', 7)
f.rect(lx - 0.2, ly + 10.9, 1.6, 2.2, stroke=None, fill=BAR)
f.text(lx + 2.2, ly + 12.8, 'Other backgrounds', 7)

# ---------------------------------------------------------------- write
errs = f.check()
for e in errs:
    print('CHECK', e)
sizes = [it['size'] for it in f.items if it['k'] == 'text']
widths = [it['sw'] for it in f.items if it['k'] in ('rect', 'line') and (it['k'] == 'line' or it['stroke'])]
print(f'text {min(sizes):g}-{max(sizes):g} pt, lines {min(widths):g}-{max(widths):g} pt')
if errs or min(sizes) < 6:
    sys.exit(1)
svg_p, dio_p, png_p = (os.path.join(OUT, n) for n in ('figure.svg', 'template.drawio', 'preview.png'))
open(svg_p, 'w').write(f.svg())
open(dio_p, 'w').write(f.drawio())
subprocess.run(['rsvg-convert', '-d', '600', '-p', '600', '-b', 'white', '-o', png_p, svg_p], check=True)
Image.open(png_p).save(png_p, dpi=(600, 600), optimize=True)
print('wrote figure.svg, template.drawio, preview.png', Image.open(png_p).size)
