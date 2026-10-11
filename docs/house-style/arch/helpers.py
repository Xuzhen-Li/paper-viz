"""Drawing helpers for the editable schematic example (layout in body.py, entry point build_v3.py).

All coordinates are SVG px on a W-px-wide canvas that prints at 183 mm (double column):
1 px = 183 / W mm, and 1 pt = 25.4 / 72 mm, so 1 px = PX_PT pt.
"""
import base64, colorsys, math, re
from pathlib import Path

import matplotlib
from matplotlib.font_manager import FontProperties, findSystemFonts
from matplotlib.textpath import TextPath
from PIL import Image, ImageFont

matplotlib.rcParams['mathtext.fontset'] = 'stix'

W, H = 1300, 860
PRINT_MM = 183.0
PX_PT = PRINT_MM / W / (25.4 / 72)          # pt per px (about 0.399)
HERE = Path(__file__).resolve().parent
ICON_DIR = HERE / 'icons'

# ---- named palette: one main colour per stage plus its tints (light card fill, mid fill)
PAL = {
    'ink': '#1c2430', 'grey': '#5b6878', 'rule': '#c9ced6', 'off': '#BFBFBF',
    'zone': '#f2f4f7', 'zone_alt': '#eef1f5', 'card': '#ffffff',
    'input': '#1F72AE', 'input_mid': '#8EBDDA', 'input_light': '#DEE4F0',     # house blue
    'heat': '#CC312C',                                                        # house red
    'geno': '#2aa198', 'geno_mid': '#a9d8d0', 'geno_light': '#e3f4f1',        # teal
    'env': '#9a5bd1', 'env_mid': '#d8c3ef', 'env_light': '#efe3f7',           # purple
    'fuse': '#e08a3a', 'fuse_light': '#fde8d4',                               # orange
    'eval': '#2e7d32', 'eval_light': '#e8f3ea', 'eval_rule': '#b9d3bf',       # green
}
# ---- named line widths in px (pt at 183 mm in the comment)
LW = {
    'zone': 1.25,     # 0.50 pt  zone outline
    'card': 2.0,      # 0.80 pt  module card outline
    'frame': 3.0,     # 1.20 pt  branch container outline
    'arrow': 3.0,     # 1.20 pt  main connectors
    'arrow_minor': 2.0,  # 0.80 pt  axes, labels-to-loss, minor connectors
    'data': 2.5,      # 1.00 pt  curves inside insets
    'fine': 1.25,     # 0.50 pt  network edges, token links (minimum)
}
# ---- named font sizes in px (pt at 183 mm in the comment)
FS = {'zone': 19.0, 'title': 16.5, 'body': 15.2, 'math': 21.6}   # 7.6 / 6.6 / 6.1 / 8.6 pt
SCRIPT = 0.7     # mathtext sub/superscript scale: 21.6 px x 0.7 = 15.1 px = 6.0 pt

SANS = "Arial, 'Liberation Sans', sans-serif"
SERIF = "'STIX Two Math', 'STIXGeneral', 'Times New Roman', serif"

out, defs, iconfb, mathfb = [], [], [], []
TEXTS, BOXES = [], []          # for the layout check in finish()


def a(s):
    out.append(s)


def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')


class group:
    """with group('zone-input'): ... wraps the elements in <g id="...">."""
    def __init__(self, gid):
        self.gid = gid
    def __enter__(self):
        a(f'<g id="{self.gid}">')
    def __exit__(self, *exc):
        a('</g>')


# ---- fonts: Arial, else Liberation Sans (metric-compatible); used to measure text
_FONT_FILES = {}
def _font_file(bold):
    key = 'bold' if bold else 'regular'
    if key not in _FONT_FILES:
        want = (['arialbd.ttf'] if bold else ['arial.ttf']) + \
               (['liberationsans-bold.ttf'] if bold else ['liberationsans-regular.ttf'])
        files = {Path(f).name.lower(): f for f in findSystemFonts()}
        hit = next((files[n] for n in want if n in files), None)
        if hit is None:
            raise SystemExit('Arial or Liberation Sans is required (e.g. the fonts-liberation package)')
        _FONT_FILES[key] = hit
    return _FONT_FILES[key]


_F = {}
def text_width(t, px, bold=False):
    k = (round(px * 10), bold)
    if k not in _F:
        _F[k] = ImageFont.truetype(_font_file(bold), k[0])
    return _F[k].getlength(t) / 10


def T(x, y, t, size='body', bold=None, anchor='middle', style='normal', fill=None, italic_head=None):
    """italic_head: a leading symbol set in italic (e.g. a variable), the rest upright."""
    px = FS[size] if isinstance(size, str) else float(size)
    bold = (size in ('zone', 'title')) if bold is None else bold
    fill = fill or PAL['ink']
    wdt = text_width(t, px, bold)
    x0 = {'middle': x - wdt / 2, 'start': x, 'end': x - wdt}[anchor]
    TEXTS.append((x0, y - 0.72 * px, x0 + wdt, y + 0.21 * px, t))
    body = esc(t)
    if italic_head and t.startswith(italic_head):
        body = f'<tspan font-style="italic">{esc(italic_head)}</tspan>{esc(t[len(italic_head):])}'
    a(f'<text x="{x}" y="{y}" font-family="{SANS}" font-size="{px:.1f}" font-weight="{"bold" if bold else "normal"}"'
      f' font-style="{style}" text-anchor="{anchor}" fill="{fill}">{body}</text>')


MP = FontProperties(family='STIXGeneral')
def M(x, y, t, tex, px=None, anchor='middle'):
    """Formula as vector paths; tex is the mathtext source (kept in data-tex), t is plain text."""
    px = px or FS['math']
    try:
        tp = TextPath((0, 0), f'${tex}$', size=px, prop=MP)
    except Exception as e:
        raise SystemExit(f'formula failed: {t}: {e}')
    ex = tp.get_extents()
    ox = {'middle': -ex.x1 / 2, 'start': 0, 'end': -ex.x1}[anchor]
    d = []
    for verts, code in tp.iter_segments():
        pts = [(verts[i], verts[i + 1]) for i in range(0, len(verts), 2)]
        c = {1: 'M', 2: 'L', 3: 'Q', 4: 'C', 79: 'Z'}[code]
        d.append('Z' if c == 'Z' else c + ' '.join(f'{px_ + ox:.2f},{-py:.2f}' for px_, py in pts))
    TEXTS.append((x + ox + ex.x0, y - ex.y1, x + ox + ex.x1, y - ex.y0, t))
    a(f'<path class="math" data-tex="{esc(tex)}" data-size="{px:.1f}" transform="translate({x},{y})" d="{" ".join(d)}"'
      f' fill="{PAL["ink"]}" stroke="{PAL["ink"]}" stroke-width="0.45" stroke-linejoin="round"><title>{esc(t)}</title></path>')
    mathfb.append(f'<text x="{x}" y="{y}" font-family="{SERIF}" font-style="italic" font-size="{px:.1f}" text-anchor="{anchor}">{esc(t)}</text>')


# ---- fills: light vertical gradient only, no shadows
def shade(hexc, f):
    h = hexc.lstrip('#')
    r, g, b = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    hh, l, s = colorsys.rgb_to_hls(r, g, b)
    l = min(1, max(0, l * f if f < 1 else l + (1 - l) * (f - 1)))
    r, g, b = colorsys.hls_to_rgb(hh, l, s)
    return '#%02x%02x%02x' % (int(r * 255), int(g * 255), int(b * 255))


_G = {}
def grad(c):
    if c not in _G:
        _G[c] = f'g{len(_G) + 1}'
        defs.append(f'<linearGradient id="{_G[c]}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{shade(c, 1.3)}"/>'
                    f'<stop offset="1" stop-color="{shade(c, 0.96)}"/></linearGradient>')
    return _G[c]


def R(x, y, w, h, fill, stroke, kind='card', dash=None, gid=None):
    """kind: zone (big tinted area), frame (branch container), card (module)."""
    sw = {'zone': LW['zone'], 'frame': LW['frame'], 'card': LW['card']}[kind]
    rx = {'zone': 13, 'frame': 10, 'card': 9}[kind]
    da = f' stroke-dasharray="{dash}"' if dash else ''
    idattr = f' id="{gid}"' if gid else ''
    BOXES.append((x, y, x + w, y + h, kind))
    a(f'<rect{idattr} x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="url(#{grad(fill)})" stroke="{shade(stroke, 0.85)}"'
      f' stroke-width="{sw}"{da}/>')


_M = {}
def marker(c):
    if c not in _M:
        _M[c] = f'ar{len(_M) + 1}'
        defs.append(f'<marker id="{_M[c]}" viewBox="0 0 12 10" refX="10" refY="5" markerWidth="3.8" markerHeight="3.8"'
                    f' orient="auto-start-reverse"><path d="M0,0 L12,5 L0,10 L2.5,5z" fill="{c}"/></marker>')
    return _M[c]


def L(pts, c=None, lw='arrow', arrow=True, dash=None):
    c = c or PAL['ink']
    p = ' '.join(f'{x},{y}' for x, y in pts)
    da = f' stroke-dasharray="{dash}"' if dash else ''
    mk = f' marker-end="url(#{marker(c)})"' if arrow else ''
    a(f'<polyline points="{p}" fill="none" stroke="{c}" stroke-width="{LW[lw]}" stroke-linejoin="round" stroke-linecap="round"{da}{mk}/>')


def curve(xs, ys, c, lw='data'):
    pts = ' '.join(f'{x:.1f},{y:.1f}' for x, y in zip(xs, ys))
    a(f'<polyline fill="none" stroke="{c}" stroke-width="{LW[lw]}" stroke-linejoin="round" stroke-linecap="round" points="{pts}"/>')


def axes(x, y, w, h):
    L([(x, y + h), (x, y - 4)], PAL['ink'], 'arrow_minor')
    L([(x, y + h), (x + w + 4, y + h)], PAL['ink'], 'arrow_minor')


# ---- icons: AI-generated bitmap in the figure, simplified vector fallback in a hidden layer.
# Each vector fallback icon is fitted to the bitmap's visible (opaque) box, not to the <image> box,
# so the two overlap even where the bitmap has transparent margins.
# Icon colours are PAL colours or light/dark variants of them made with shade().
ICONS = []          # (name, image box, opaque box) for the overlap check in build_v3.py
ALPHA_MIN = 40      # alpha above this counts as visible


def _opaque_box(p, x, y, w, h):
    with Image.open(p) as im:
        al = im.convert('RGBA').getchannel('A').point(lambda v: 255 if v > ALPHA_MIN else 0)
        bx = al.getbbox(); iw, ih = im.size
    return (x + bx[0] * w / iw, y + bx[1] * h / ih, x + bx[2] * w / iw, y + bx[3] * h / ih)


def _flake_lines():
    """Unit snowflake (arm length 1) as line segments."""
    segs = []
    for k in range(3):
        an = k * math.pi / 3 + math.pi / 2; dx, dy = math.cos(an), math.sin(an)
        segs.append((-dx, -dy, dx, dy))
        for sgn in (1, -1):
            bx, by = sgn * dx * 0.62, sgn * dy * 0.62
            for t in (0.7, -0.7):
                b2 = an + (0 if sgn > 0 else math.pi) + t
                segs.append((bx, by, bx + 0.3 * math.cos(b2), by + 0.3 * math.sin(b2)))
    return segs


def _vec_snowflake(x0, y0, x1, y1):
    segs = _flake_lines(); sw = 0.3                 # outer stroke in unit coordinates
    ex = max(max(abs(s[0]), abs(s[2])) for s in segs) + sw / 2
    ey = max(max(abs(s[1]), abs(s[3])) for s in segs) + sw / 2
    sx, sy = (x1 - x0) / 2 / ex, (y1 - y0) / 2 / ey
    g = [f'<g class="vec-snowflake" stroke-linecap="round" transform="translate({(x0 + x1) / 2:.2f},{(y0 + y1) / 2:.2f}) scale({sx:.3f},{sy:.3f})">']
    for col, wd in ((shade(PAL['input'], 1.25), sw), (shade(PAL['input'], 1.85), sw * 0.38)):
        for s in segs:
            g.append(f'<line x1="{s[0]:.3f}" y1="{s[1]:.3f}" x2="{s[2]:.3f}" y2="{s[3]:.3f}" stroke="{col}" stroke-width="{wd:.3f}"/>')
    g.append('</g>'); return ''.join(g)


# flame outline in a local frame; its drawn extent is about x -7.8..7.8, y -12..8.8
_FLAME = ('M0,-12 C7,-6 9,0 7,5 C5,10 -5,10 -7,5 C-9,0 -6,-4 -3,-7 C-2,-3 0,-2 1,-4 C2,-7 0,-10 0,-12Z',
          'M0,-3 C3.5,0.5 3.5,5 0,7.5 C-3.5,5 -3.5,1.5 0,-3Z')
def _vec_flame(x0, y0, x1, y1):
    sx, sy = (x1 - x0) / 15.6, (y1 - y0) / 20.8
    return (f'<g class="vec-flame" transform="translate({(x0 + x1) / 2:.2f},{y0 + 12 * sy:.2f}) scale({sx:.3f},{sy:.3f})">'
            f'<path d="{_FLAME[0]}" fill="{PAL["heat"]}"/><path d="{_FLAME[1]}" fill="{shade(PAL["fuse"], 1.15)}"/></g>')


def _vec_database(x0, y0, x1, y1):
    sw = 1.5; line = PAL['grey']
    rx = (x1 - x0) / 2 - sw / 2; ry = (y1 - y0) * 0.13; cx = (x0 + x1) / 2
    top, bot = y0 + sw / 2 + ry, y1 - sw / 2 - ry
    bands = ''.join(f'<path d="M{cx - rx:.1f},{top + (bot - top) * f:.1f} a{rx:.1f},{ry:.1f} 0 0 0 {2 * rx:.1f},0" fill="none" stroke="{line}" stroke-width="{sw}"/>'
                    for f in (1 / 3, 2 / 3))
    return (f'<g class="vec-database"><path d="M{cx - rx:.1f},{top:.1f} V{bot:.1f} a{rx:.1f},{ry:.1f} 0 0 0 {2 * rx:.1f},0 V{top:.1f}"'
            f' fill="{shade(line, 1.6)}" stroke="{line}" stroke-width="{sw}"/>{bands}'
            f'<ellipse cx="{cx:.1f}" cy="{top:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{shade(line, 1.8)}" stroke="{line}" stroke-width="{sw}"/></g>')


def _vec_gauge(x0, y0, x1, y1):
    cx = (x0 + x1) / 2
    r = (x1 - x0) / 2 / 1.15; sw = r * 0.3          # outer radius r + sw/2 = half the box width
    hub = 4.0
    yc = y1 - hub                                   # hub sits on the bottom of the box
    segs = []
    for k, f in enumerate((1.7, 1.4, 1.15, 1.0, 0.7)):
        a0, a1 = math.pi * (1 - k / 5), math.pi * (1 - (k + 1) / 5)
        segs.append(f'<path d="M{cx + r * math.cos(a0):.1f},{yc - r * math.sin(a0):.1f} A{r:.1f},{r:.1f} 0 0 1 {cx + r * math.cos(a1):.1f},{yc - r * math.sin(a1):.1f}"'
                    f' fill="none" stroke="{shade(PAL["eval"], f)}" stroke-width="{sw:.1f}"/>')
    an = math.radians(40)
    needle = (f'<path d="M{cx - 2.5 * math.sin(an):.1f},{yc - 2.5 * math.cos(an):.1f} L{cx + r * 0.95 * math.cos(an):.1f},{yc - r * 0.95 * math.sin(an):.1f}'
              f' L{cx + 2.5 * math.sin(an):.1f},{yc + 2.5 * math.cos(an):.1f}Z" fill="{PAL["ink"]}"/><circle cx="{cx:.1f}" cy="{yc:.1f}" r="{hub}" fill="{PAL["ink"]}"/>')
    # scale vertically so the arc top meets the box top
    top = yc - r - sw / 2; s = (y1 - y0) / (y1 - top)
    return f'<g class="vec-gauge" transform="translate(0,{y1:.2f}) scale(1,{s:.4f}) translate(0,{-y1:.2f})">{"".join(segs)}{needle}</g>'


_VEC = {'snowflake': _vec_snowflake, 'flame': _vec_flame, 'database': _vec_database, 'gauge': _vec_gauge}


def ICON(n, cx, cy, w):
    p = ICON_DIR / f'{n}.png'
    with Image.open(p) as im:
        h = w * im.height / im.width
    x, y = cx - w / 2, cy - h / 2
    ob = _opaque_box(p, x, y, w, h)
    ICONS.append((n, (x, y, x + w, y + h), ob))
    b64 = base64.b64encode(p.read_bytes()).decode()
    a(f'<image class="icon-bitmap icon-{n}" x="{x:.1f}" y="{y:.1f}" width="{w}" height="{h:.1f}" href="data:image/png;base64,{b64}"/>')
    iconfb.append(_VEC[n](*ob))


def static_defs():
    return (f'<radialGradient id="nodeg" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="{PAL["card"]}"/>'
            f'<stop offset="1" stop-color="{shade(PAL["grey"], 1.75)}"/></radialGradient>')


def check_layout():
    """Text must sit inside its innermost card/frame/zone and must not overlap other text."""
    problems = []
    for (x0, y0, x1, y1, t) in TEXTS:
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        inside = [b for b in BOXES if b[0] <= cx <= b[2] and b[1] <= cy <= b[3]]
        if inside:
            b = min(inside, key=lambda b: (b[2] - b[0]) * (b[3] - b[1]))
            if x0 < b[0] + 3 or x1 > b[2] - 3 or y0 < b[1] + 2 or y1 > b[3] - 2:
                problems.append(f'outside its box: {t!r}')
    for i in range(len(TEXTS)):
        for j in range(i + 1, len(TEXTS)):
            p, q = TEXTS[i], TEXTS[j]
            if p[0] < q[2] - 1 and q[0] < p[2] - 1 and p[1] < q[3] - 1 and q[1] < p[3] - 1:
                problems.append(f'overlap: {p[4]!r} / {q[4]!r}')
    return problems


def finish(path, vector_icons=False):
    """Write the SVG. vector_icons=True writes a check copy with the vector fallback icons shown instead of the bitmaps."""
    style = '<style>.icon-bitmap{display:none}</style>' if vector_icons else ''
    vis = 'visible' if vector_icons else 'hidden'
    s = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
         '<desc>AI-assisted icons: database (genotype data), flame and snowflake (environment data), gauge (accuracy).</desc>', style, '<defs>', static_defs(), *defs, '</defs>',
         f'<rect width="{W}" height="{H}" fill="{PAL["card"]}"/>', '<g id="figure">', *out, '</g>',
         f'<g id="vector-icon-fallback" visibility="{vis}">', *iconfb, '</g>',
         '<g id="math-text-fallback" visibility="hidden">', *mathfb, '</g>', '</svg>']
    Path(path).write_text('\n'.join(x for x in s if x) + '\n')
