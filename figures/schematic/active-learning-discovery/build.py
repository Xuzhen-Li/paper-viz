#!/usr/bin/env python3
"""active-learning-discovery (v2): one spec -> figure.svg + template.drawio + preview.png (600 dpi).

Active-learning discovery loop with two candidate routes (after the GNoME discovery overview,
TARGETS S41). Structure route: partial substitutions (SAPS) in known structures -> structure graph
network filter -> DFT. Composition route: new compositions (relaxed oxidation-state rules) ->
composition graph network filter on reduced formulas (no structure) -> AIRSS initialises 100 random
structures per kept composition -> DFT. Verified stable candidates are kept; all new DFT labels
retrain the filters and stable results seed new substitutions. Layout idea only; not traced from any
published figure. Generic labels only; no material or formula names; counts and hit rates omitted.

v2 changes against v1 (content only): composition-route order corrected (random structures now come
after the composition filter, via AIRSS); filter split into structure and composition models;
"partial substitutions (SAPS)" on the substitution card. Both feedback loops unchanged.

Self-contained generator (drawing kit copied from redraws/tree-of-thoughts-v2/build.py). Run:
    python3 build.py [OUTPUT_DIR]
OUTPUT_DIR defaults to the folder of this script. Outputs are WRITE-ONCE: the script refuses to
start if figure.svg, template.drawio or preview.png already exists there (it never replaces a
file), so give it a new empty folder to rebuild.
Needs Python >= 3.8, Pillow, the Arial or Liberation Sans font (same widths; set PV_FONT_DIR
if it is not found) and librsvg for the PNG (rsvg-convert from librsvg2-bin; if that command is
missing, the script calls the same librsvg library directly through ctypes). Exits non-zero if
any label leaves the canvas or its box, labels overlap, a font size is below 6 pt, a line width
is outside 0.5-1.6 pt or a label has contrast below 4.5:1 against its fill. Icons are simple
shapes drawn by this script (no bitmaps, no icon library, no journal images).
"""
# ======================================================================= drawing kit
# One spec -> figure.svg (editable vector text, no bitmaps) + template.drawio + preview.png (600 dpi).
# Coordinates in mm on a canvas that prints at its true size; font sizes and line widths in pt.
import ctypes, ctypes.util, html, itertools, math, os, subprocess, sys
from xml.sax.saxutils import quoteattr
from PIL import Image, ImageFont

PT = 25.4 / 72          # mm per pt
K = 72 / 25.4           # draw.io units (pt) per mm

# ---- named house colours (style-contract: one main colour per zone + light tints derived from it)
HOUSE = {'blue': '#1F72AE', 'orange': '#F77E12', 'green': '#119B76', 'red': '#CC312C',
         'purple': '#595594', 'sky': '#62B4E7', 'yellow': '#E6C32A', 'magenta': '#A8127F', 'brown': '#8A4C38'}
INK, GREY, RULE, ZONE = '#1A1A1A', '#595959', '#BFBFBF', '#F7F7F7'

def mix(c, f):
    """f in 0..1: share of white mixed into colour c (0 = c, 1 = white); f < 0 darkens towards black."""
    h = c.lstrip('#'); r, g, b = [int(h[i:i + 2], 16) for i in (0, 2, 4)]
    if f >= 0:
        r, g, b = [round(v + (255 - v) * f) for v in (r, g, b)]
    else:
        r, g, b = [round(v * (1 + f)) for v in (r, g, b)]
    return '#%02X%02X%02X' % (r, g, b)

def tint(c):  return mix(c, 0.86)     # card fill
def mid(c):   return mix(c, 0.55)     # mid tone
def dark(c):  return mix(c, -0.25)    # text-safe variant

# ---- named line widths (pt), style-contract schematic section
LW = {'zone': 0.5, 'card': 0.8, 'arrow': 1.2, 'minor': 0.8, 'icon': 0.8, 'fine': 0.5}
# ---- named font sizes (pt)
FS = {'zone': 7.5, 'title': 7.0, 'body': 6.5, 'small': 6.0}

_FONT_CANDIDATES = {
    False: ['Arial.TTF', 'Arial.ttf', 'arial.ttf', 'LiberationSans-Regular.ttf'],
    True: ['Arialbd.TTF', 'Arial_Bold.ttf', 'arialbd.ttf', 'LiberationSans-Bold.ttf'],
}
_FONT_DIRS = [os.environ.get('PV_FONT_DIR', ''), os.path.expanduser('~/.local/share/fonts'),
              '/usr/share/fonts/truetype/msttcorefonts', '/usr/share/fonts/truetype/liberation',
              '/usr/share/fonts/truetype/liberation2', '/usr/share/fonts/liberation-sans',
              '/Library/Fonts', '/System/Library/Fonts/Supplemental', 'C:/Windows/Fonts']
_F = {}
def _font(bold):
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

def text_w(t, size, bold=False):
    return _font(bold).getlength(t) / 1000 * size * PT

def _lum(c):
    h = c.lstrip('#'); v = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    v = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in v]
    return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]

def contrast(a, b):
    la, lb = sorted((_lum(a), _lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


class Fig:
    def __init__(self, name, w, h):
        self.name, self.w, self.h = name, w, h
        self.items, self.textboxes, self.fills = [], [], []
        self.gid = 'figure'

    def group(self, gid):
        self.gid = gid

    def rect(self, x, y, w, h, stroke=INK, fill=None, sw=LW['card'], r=1.2, dash=False):
        self.items.append(dict(k='rect', x=x, y=y, w=w, h=h, stroke=stroke, fill=fill, sw=sw, r=r, dash=dash, g=self.gid))
        if fill:
            self.fills.append(((x, y, x + w, y + h), fill))
        return (x, y, w, h)

    def ellipse(self, cx, cy, rx, ry, stroke=INK, fill=None, sw=LW['icon']):
        self.items.append(dict(k='ell', cx=cx, cy=cy, rx=rx, ry=ry, stroke=stroke, fill=fill, sw=sw, g=self.gid))
        if fill:
            self.fills.append(((cx - rx * 0.7, cy - ry * 0.7, cx + rx * 0.7, cy + ry * 0.7), fill))

    def line(self, pts, stroke=INK, sw=LW['arrow'], arrow=False, dash=False, cap='round'):
        self.items.append(dict(k='line', pts=[tuple(p) for p in pts], stroke=stroke, sw=sw, arrow=arrow, dash=dash, cap=cap, g=self.gid))

    def text(self, x, y, t, size=FS['body'], anchor='middle', color=INK, bold=False, inside=None, italic=False):
        em = size * PT
        tw = text_w(t, size, bold)
        self.items.append(dict(k='text', x=x, y=y, t=t, size=size, anchor=anchor, color=color, bold=bold,
                               italic=italic, tw=tw, g=self.gid))
        x0 = {'start': x, 'middle': x - tw / 2, 'end': x - tw}[anchor]
        self.textboxes.append(((x0, y - 0.74 * em, x0 + tw, y + 0.21 * em), t, inside, color))
        return tw

    def lines(self, x, ytop, rows, size=FS['body'], anchor='middle', color=INK, bold=False, inside=None, lead=1.22):
        """rows of text; ytop = top of the first line's cap height. Returns y after the last line."""
        y = ytop + 0.72 * size * PT
        for t in rows:
            self.text(x, y, t, size, anchor, color, bold, inside)
            y += lead * size * PT
        return y - lead * size * PT + 0.21 * size * PT

    # ------------------------------------------------------------ helpers
    def card(self, x, y, w, h, title, body=(), colour=HOUSE['blue'], fill=None, dash=False, tsize=None, bsize=None,
             title_colour=INK):
        b = self.rect(x, y, w, h, stroke=colour, fill=fill or tint(colour), sw=LW['card'], dash=dash)
        tsize = tsize or FS['title']; bsize = bsize or FS['body']
        n = len(body)
        tot = 0.72 * tsize * PT + (n * 1.22 * bsize * PT + 0.6 if n else 0)
        top = y + (h - tot) / 2
        self.text(x + w / 2, top + 0.72 * tsize * PT, title, tsize, bold=True, inside=b, color=title_colour)
        if n:
            self.lines(x + w / 2, top + 0.72 * tsize * PT + 0.6 + 0.5 * bsize * PT, body, bsize, inside=b)
        return b

    def zone(self, x, y, w, h, title, colour=GREY, fill=ZONE, anchor='start'):
        b = self.rect(x, y, w, h, stroke=mid(colour) if colour != GREY else RULE, fill=fill, sw=LW['zone'], r=1.8)
        tx = x + 2.0 if anchor == 'start' else x + w / 2
        self.text(tx, y + 3.6, title, FS['zone'], anchor=anchor, bold=True, inside=b, color=dark(colour) if colour != GREY else INK)
        return b

    def arrow(self, pts, colour=INK, sw=LW['arrow'], dash=False):
        self.line(pts, stroke=colour, sw=sw, arrow=True, dash=dash)

    def arc_pts(self, cx, cy, r, a0, a1, n=24, ry=None):
        ry = ry or r
        return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
                 cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]

    # ------------------------------------------------------------ script-drawn icons (primitives only)
    def icon(self, kind, cx, cy, s, c):
        """s = icon height in mm. Simple geometric icons built from rects, ellipses and lines."""
        sw = LW['icon']; fill = '#FFFFFF'
        if kind == 'doc':
            w = s * 0.76
            self.rect(cx - w / 2, cy - s / 2, w, s, stroke=c, fill=fill, sw=sw, r=0.4)
            for i in range(3):
                yy = cy - s * 0.22 + i * s * 0.2
                self.line([(cx - w * 0.3, yy), (cx + w * 0.3, yy)], stroke=c, sw=sw, cap='butt')
        elif kind == 'db':
            rx, ry = s * 0.42, s * 0.13
            self.rect(cx - rx, cy - s / 2 + ry, 2 * rx, s - 2 * ry, stroke=None, fill=fill, sw=sw, r=0)
            self.line([(cx - rx, cy - s / 2 + ry), (cx - rx, cy + s / 2 - ry)], stroke=c, sw=sw, cap='butt')
            self.line([(cx + rx, cy - s / 2 + ry), (cx + rx, cy + s / 2 - ry)], stroke=c, sw=sw, cap='butt')
            self.line(self.arc_pts(cx, cy + s / 2 - ry, rx, 0, 180, 16, ry), stroke=c, sw=sw, cap='butt')
            self.line(self.arc_pts(cx, cy, rx, 0, 180, 16, ry), stroke=c, sw=sw, cap='butt')
            self.ellipse(cx, cy - s / 2 + ry, rx, ry, stroke=c, fill=fill, sw=sw)
        elif kind == 'search':
            r = s * 0.3
            self.ellipse(cx - s * 0.1, cy - s * 0.1, r, r, stroke=c, fill=fill, sw=sw)
            self.line([(cx + s * 0.11, cy + s * 0.11), (cx + s * 0.4, cy + s * 0.4)], stroke=c, sw=LW['arrow'])
        elif kind == 'gear':
            r = s * 0.3
            for k in range(8):
                an = math.radians(k * 45)
                self.line([(cx + r * math.cos(an), cy + r * math.sin(an)),
                           (cx + s * 0.46 * math.cos(an), cy + s * 0.46 * math.sin(an))], stroke=c, sw=LW['arrow'], cap='butt')
            self.ellipse(cx, cy, r, r, stroke=c, fill=fill, sw=sw)
            self.ellipse(cx, cy, r * 0.38, r * 0.38, stroke=c, fill=fill, sw=sw)
        elif kind == 'chip':            # language model
            w = s * 0.8
            for i in range(3):
                xx = cx - w * 0.28 + i * w * 0.28
                self.line([(xx, cy - s / 2), (xx, cy + s / 2)], stroke=c, sw=sw, cap='butt')
                yy = cy - w * 0.28 + i * w * 0.28
                self.line([(cx - s / 2, yy), (cx + s / 2, yy)], stroke=c, sw=sw, cap='butt')
            self.rect(cx - w / 2, cy - w / 2, w, w, stroke=c, fill=fill, sw=sw, r=0.5)
            self.rect(cx - w * 0.22, cy - w * 0.22, w * 0.44, w * 0.44, stroke=None, fill=c, sw=sw, r=0.2)
        elif kind == 'globe':           # environment
            r = s * 0.46
            self.ellipse(cx, cy, r, r, stroke=c, fill=fill, sw=sw)
            self.ellipse(cx, cy, r * 0.42, r, stroke=c, fill=None, sw=sw)
            self.line([(cx - r, cy), (cx + r, cy)], stroke=c, sw=sw, cap='butt')
        elif kind == 'eye':             # observe / perceive
            self.line(self.arc_pts(cx, cy + s * 0.32, s * 0.5, 215, 325, 16), stroke=c, sw=sw)
            self.line(self.arc_pts(cx, cy - s * 0.32, s * 0.5, 35, 145, 16), stroke=c, sw=sw)
            self.ellipse(cx, cy, s * 0.17, s * 0.17, stroke=c, fill=c, sw=sw)
        elif kind == 'bulb':            # idea / hypothesis / thought
            r = s * 0.3
            self.ellipse(cx, cy - s * 0.15, r, r, stroke=c, fill=fill, sw=sw)
            self.rect(cx - r * 0.5, cy + s * 0.17, r, s * 0.25, stroke=c, fill=fill, sw=sw, r=0.2)
        elif kind == 'flask':
            w = s * 0.8
            self.line([(cx - w * 0.15, cy - s / 2), (cx - w * 0.15, cy - s * 0.1), (cx - w / 2, cy + s / 2),
                       (cx + w / 2, cy + s / 2), (cx + w * 0.15, cy - s * 0.1), (cx + w * 0.15, cy - s / 2)], stroke=c, sw=sw)
            self.line([(cx - w * 0.33, cy + s * 0.25), (cx + w * 0.33, cy + s * 0.25)], stroke=c, sw=sw, cap='butt')
        elif kind == 'bars':            # analysis
            w = s * 0.9
            for i, hh in enumerate((0.45, 0.8, 0.6)):
                self.rect(cx - w / 2 + i * w * 0.36, cy + s / 2 - s * hh, w * 0.26, s * hh, stroke=None, fill=c, sw=sw, r=0)
            self.line([(cx - w / 2 - 0.3, cy + s / 2), (cx + w / 2 + 0.3, cy + s / 2)], stroke=c, sw=sw, cap='butt')
        elif kind == 'person':
            self.ellipse(cx, cy - s * 0.24, s * 0.2, s * 0.2, stroke=c, fill=fill, sw=sw)
            self.line(self.arc_pts(cx, cy + s * 0.5, s * 0.34, 180, 360, 16), stroke=c, sw=sw)
        elif kind == 'check':
            self.line([(cx - s * 0.35, cy), (cx - s * 0.1, cy + s * 0.3), (cx + s * 0.4, cy - s * 0.35)], stroke=c, sw=LW['arrow'])
        elif kind == 'cross':
            d = s * 0.32
            self.line([(cx - d, cy - d), (cx + d, cy + d)], stroke=c, sw=LW['arrow'])
            self.line([(cx - d, cy + d), (cx + d, cy - d)], stroke=c, sw=LW['arrow'])
        elif kind == 'code':            # source code: < / >
            w, hh = s * 0.9, s * 0.42
            self.line([(cx - w * 0.22, cy - hh), (cx - w / 2, cy), (cx - w * 0.22, cy + hh)], stroke=c, sw=LW['arrow'])
            self.line([(cx + w * 0.22, cy - hh), (cx + w / 2, cy), (cx + w * 0.22, cy + hh)], stroke=c, sw=LW['arrow'])
            self.line([(cx + w * 0.1, cy - hh * 1.1), (cx - w * 0.1, cy + hh * 1.1)], stroke=c, sw=LW['icon'])
        else:
            raise SystemExit('unknown icon ' + kind)

    # ------------------------------------------------------------ checks
    def bg_at(self, x, y):
        hits = [(b, f) for b, f in self.fills if b[0] <= x <= b[2] and b[1] <= y <= b[3]]
        if not hits:
            return '#FFFFFF'
        return hits[-1][1]   # drawn last = on top

    def check(self):
        errs = []
        for bb, lab, box, col in self.textboxes:
            if bb[0] < 0.5 or bb[1] < 0.5 or bb[2] > self.w - 0.5 or bb[3] > self.h - 0.5:
                errs.append(f'outside canvas: {lab!r}')
            if box:
                bx, by, bw, bh = box
                if bb[0] < bx + 0.6 or bb[2] > bx + bw - 0.6 or bb[1] < by + 0.4 or bb[3] > by + bh - 0.4:
                    errs.append(f'outside its box: {lab!r} bb={tuple(round(v, 2) for v in bb)} box={box}')
            bg = self.bg_at((bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2)
            if contrast(col, bg) < 4.5:
                errs.append(f'contrast {contrast(col, bg):.2f} < 4.5: {lab!r} ({col} on {bg})')
        for (a, la, _, _), (b, lb, _, _) in itertools.combinations(self.textboxes, 2):
            if a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]:
                errs.append(f'overlap: {la!r} x {lb!r}')
        for it in self.items:
            if it['k'] in ('rect', 'ell', 'line') and it.get('stroke') and not (0.5 <= it['sw'] <= 1.6):
                errs.append(f'line width {it["sw"]} pt outside 0.5-1.6')
            if it['k'] == 'text' and it['size'] < 6:
                errs.append(f'text under 6 pt: {it["t"]!r}')
        return errs

    # ------------------------------------------------------------ SVG
    def svg(self, desc):
        o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w:.3f}mm" height="{self.h:.3f}mm" '
             f'viewBox="0 0 {self.w:.3f} {self.h:.3f}" font-family="Arial, \'Liberation Sans\', Helvetica, sans-serif">',
             f'<title>{self.name}</title>', f'<desc>{html.escape(desc, quote=False)}</desc>',
             f'<rect id="background" x="0" y="0" width="{self.w:.3f}" height="{self.h:.3f}" fill="#FFFFFF"/>']
        cur = None
        for it in self.items:
            if it['g'] != cur:
                if cur is not None:
                    o.append('</g>')
                cur = it['g']; o.append(f'<g id="{cur}">')
            sw = f'{it["sw"] * PT:.4f}' if 'sw' in it else ''
            da = f' stroke-dasharray="{1.2:.3f} {0.9:.3f}"' if it.get('dash') else ''
            if it['k'] == 'rect':
                o.append(f'<rect x="{it["x"]:.3f}" y="{it["y"]:.3f}" width="{it["w"]:.3f}" height="{it["h"]:.3f}" rx="{it["r"]:.3f}" '
                         f'fill="{it["fill"] or "none"}" stroke="{it["stroke"] or "none"}" stroke-width="{sw}"{da}/>')
            elif it['k'] == 'ell':
                o.append(f'<ellipse cx="{it["cx"]:.3f}" cy="{it["cy"]:.3f}" rx="{it["rx"]:.3f}" ry="{it["ry"]:.3f}" '
                         f'fill="{it["fill"] or "none"}" stroke="{it["stroke"] or "none"}" stroke-width="{sw}"/>')
            elif it['k'] == 'line':
                pts = list(it['pts']); head = None
                if it['arrow']:
                    (x1, y1), (x2, y2) = pts[-2], pts[-1]
                    L = math.hypot(x2 - x1, y2 - y1); ux, uy = (x2 - x1) / L, (y2 - y1) / L
                    k_ = max(1.0, it['sw'] / 0.5) ** 0.5
                    al, aw = 1.2 * k_, 0.5 * k_
                    bx, by = x2 - ux * al, y2 - uy * al
                    head = [(x2, y2), (bx - uy * aw, by + ux * aw), (x2 - ux * al * 0.75, y2 - uy * al * 0.75), (bx + uy * aw, by - ux * aw)]
                    pts[-1] = (x2 - ux * al * 0.7, y2 - uy * al * 0.7)
                d = ' '.join(f'{x:.3f},{y:.3f}' for x, y in pts)
                o.append(f'<polyline points="{d}" fill="none" stroke="{it["stroke"]}" stroke-width="{sw}" '
                         f'stroke-linejoin="round" stroke-linecap="{"butt" if it["arrow"] else it["cap"]}"{da}/>')
                if head:
                    o.append('<polygon points="' + ' '.join(f'{x:.3f},{y:.3f}' for x, y in head) + f'" fill="{it["stroke"]}"/>')
            else:
                em = it['size'] * PT
                o.append(f'<text x="{it["x"]:.3f}" y="{it["y"]:.3f}" font-size="{em:.4f}" fill="{it["color"]}" '
                         f'text-anchor="{it["anchor"]}"' + (' font-weight="bold"' if it['bold'] else '')
                         + (' font-style="italic"' if it['italic'] else '')
                         + f' xml:space="preserve">{html.escape(it["t"], quote=False)}</text>')
        if cur is not None:
            o.append('</g>')
        o.append('</svg>')
        return '\n'.join(o) + '\n'

    # ------------------------------------------------------------ draw.io
    def drawio(self):
        cells = []; n = itertools.count(2)
        def dash_style(d):
            return 'dashed=1;dashPattern=3.4 2.5;' if d else ''
        for it in self.items:
            i = next(n)
            if it['k'] in ('rect', 'ell'):
                if it['k'] == 'rect':
                    x, y, w, h = it['x'], it['y'], it['w'], it['h']
                    shape = f'rounded={1 if it["r"] > 0 else 0};absoluteArcSize=1;arcSize={2 * it["r"] * K:.1f};'
                else:
                    x, y, w, h = it['cx'] - it['rx'], it['cy'] - it['ry'], 2 * it['rx'], 2 * it['ry']
                    shape = 'ellipse;'
                st = (shape + f'whiteSpace=wrap;html=1;fillColor={it["fill"] or "none"};'
                      f'strokeColor={it["stroke"] or "none"};strokeWidth={it["sw"]:g};' + dash_style(it['dash'] if 'dash' in it else False))
                cells.append(f'<mxCell id="c{i}" value="" style="{st}" vertex="1" parent="1">'
                             f'<mxGeometry x="{x * K:.2f}" y="{y * K:.2f}" width="{w * K:.2f}" height="{h * K:.2f}" as="geometry"/></mxCell>')
            elif it['k'] == 'line':
                pts = it['pts']
                st = (f'endArrow={"block;endFill=1;endSize=4" if it["arrow"] else "none"};startArrow=none;html=1;'
                      f'rounded=0;strokeColor={it["stroke"]};strokeWidth={it["sw"]:g};' + dash_style(it['dash']))
                mids = ''.join(f'<mxPoint x="{x * K:.2f}" y="{y * K:.2f}"/>' for x, y in pts[1:-1])
                cells.append(f'<mxCell id="c{i}" value="" style="{st}" edge="1" parent="1"><mxGeometry relative="1" as="geometry">'
                             f'<mxPoint x="{pts[0][0] * K:.2f}" y="{pts[0][1] * K:.2f}" as="sourcePoint"/>'
                             f'<mxPoint x="{pts[-1][0] * K:.2f}" y="{pts[-1][1] * K:.2f}" as="targetPoint"/>'
                             + (f'<Array as="points">{mids}</Array>' if mids else '') + '</mxGeometry></mxCell>')
            else:
                em = it['size'] * PT; w = it['tw'] + 0.8; h = 1.2 * em
                x0 = {'start': it['x'] - 0.4, 'middle': it['x'] - w / 2, 'end': it['x'] - w + 0.4}[it['anchor']]
                cy = it['y'] - 0.9465 * em + h / 2
                align = {'start': 'left', 'middle': 'center', 'end': 'right'}[it['anchor']]
                fs = (1 if it['bold'] else 0) + (2 if it['italic'] else 0)
                st = (f'text;html=1;whiteSpace=nowrap;fontFamily=Arial;fontSize={it["size"]:g};fontColor={it["color"]};'
                      f'align={align};verticalAlign=middle;spacing=0;strokeColor=none;fillColor=none;fontStyle={fs};')
                cells.append(f'<mxCell id="c{i}" value={quoteattr(html.escape(it["t"], quote=False))} style="{st}" vertex="1" parent="1">'
                             f'<mxGeometry x="{x0 * K:.2f}" y="{(cy - h / 2) * K:.2f}" width="{w * K:.2f}" height="{h * K:.2f}" as="geometry"/></mxCell>')
        pw, ph = round(self.w * K), round(self.h * K)
        return ('<mxfile host="paper-viz" type="device">\n'
                f'<diagram id="{self.name}" name="{self.name}">\n'
                f'<mxGraphModel dx="{pw}" dy="{ph}" grid="0" gridSize="1" guides="1" tooltips="1" connect="0" arrows="1" '
                f'fold="1" page="1" pageScale="1" pageWidth="{pw}" pageHeight="{ph}" math="0" shadow="0">\n'
                '<root>\n<mxCell id="0"/>\n<mxCell id="1" parent="0"/>\n' + '\n'.join(cells) +
                '\n</root>\n</mxGraphModel>\n</diagram>\n</mxfile>\n')



def render_png(svg_p, png_p, dpi=600):
    """Render figure.svg with librsvg (rsvg-convert if installed, else libRSVG via ctypes) and write
    preview.png exactly once (mode 'xb'); the image is kept in memory, no temporary file."""
    import io as _io
    if os.path.exists(png_p):
        raise SystemExit('refusing to overwrite ' + png_p)
    try:
        r = subprocess.run(['rsvg-convert', '-d', str(dpi), '-p', str(dpi), '-b', 'white', svg_p],
                           check=True, stdout=subprocess.PIPE)
        im = Image.open(_io.BytesIO(r.stdout)).convert('RGB')
    except FileNotFoundError:
        rs = ctypes.CDLL(ctypes.util.find_library('rsvg-2') or 'librsvg-2.so.2')
        ca = ctypes.CDLL(ctypes.util.find_library('cairo') or 'libcairo.so.2')
        rs.rsvg_handle_new_from_file.restype = ctypes.c_void_p
        rs.rsvg_handle_new_from_file.argtypes = [ctypes.c_char_p, ctypes.c_void_p]
        rs.rsvg_handle_set_dpi.argtypes = [ctypes.c_void_p, ctypes.c_double]
        rs.rsvg_handle_get_intrinsic_size_in_pixels.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_double), ctypes.POINTER(ctypes.c_double)]
        class Rect(ctypes.Structure):
            _fields_ = [('x', ctypes.c_double), ('y', ctypes.c_double), ('width', ctypes.c_double), ('height', ctypes.c_double)]
        rs.rsvg_handle_render_document.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.POINTER(Rect), ctypes.c_void_p]
        ca.cairo_image_surface_create.restype = ctypes.c_void_p
        ca.cairo_image_surface_create.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int]
        ca.cairo_create.restype = ctypes.c_void_p; ca.cairo_create.argtypes = [ctypes.c_void_p]
        ca.cairo_set_source_rgb.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_double, ctypes.c_double]
        ca.cairo_paint.argtypes = [ctypes.c_void_p]
        ca.cairo_surface_flush.argtypes = [ctypes.c_void_p]
        ca.cairo_image_surface_get_data.restype = ctypes.c_void_p
        ca.cairo_image_surface_get_data.argtypes = [ctypes.c_void_p]
        ca.cairo_image_surface_get_stride.restype = ctypes.c_int
        ca.cairo_image_surface_get_stride.argtypes = [ctypes.c_void_p]
        ca.cairo_destroy.argtypes = [ctypes.c_void_p]; ca.cairo_surface_destroy.argtypes = [ctypes.c_void_p]
        h = rs.rsvg_handle_new_from_file(svg_p.encode(), None)
        if not h:
            raise SystemExit('librsvg could not read ' + svg_p)
        rs.rsvg_handle_set_dpi(h, float(dpi))
        w, hh = ctypes.c_double(), ctypes.c_double()
        rs.rsvg_handle_get_intrinsic_size_in_pixels(h, ctypes.byref(w), ctypes.byref(hh))
        W, H = math.ceil(w.value), math.ceil(hh.value)
        s = ca.cairo_image_surface_create(0, W, H); cr = ca.cairo_create(s)
        ca.cairo_set_source_rgb(cr, 1.0, 1.0, 1.0); ca.cairo_paint(cr)
        if not rs.rsvg_handle_render_document(h, cr, ctypes.byref(Rect(0, 0, w.value, hh.value)), None):
            raise SystemExit('librsvg render failed')
        ca.cairo_surface_flush(s)
        stride = ca.cairo_image_surface_get_stride(s)
        buf = ctypes.string_at(ca.cairo_image_surface_get_data(s), stride * H)
        im = Image.frombuffer('RGBA', (W, H), buf, 'raw', 'BGRA', stride, 1).convert('RGB')
        ca.cairo_destroy(cr); ca.cairo_surface_destroy(s)
    with open(png_p, 'xb') as fh:
        im.save(fh, format='PNG', dpi=(dpi, dpi), optimize=True)


def write_all(f, desc):
    errs = f.check()
    for e in errs:
        print('CHECK', e)
    sizes = [it['size'] for it in f.items if it['k'] == 'text']
    widths = [it['sw'] for it in f.items if it['k'] in ('rect', 'ell', 'line') and it.get('stroke')]
    print(f'{f.name}: {f.w:g} x {f.h:g} mm; text {min(sizes):g}-{max(sizes):g} pt; lines {min(widths):g}-{max(widths):g} pt')
    if errs:
        sys.exit(1)
    svg = f.svg(desc)
    if '<image' in svg or 'data:image/' in svg or '<foreignObject' in svg:
        sys.exit('figure.svg must not embed images or HTML')
    paths = [os.path.join(OUT, n) for n in ('figure.svg', 'template.drawio', 'preview.png')]
    clash = [p for p in paths if os.path.exists(p)]
    if clash:
        sys.exit('refusing to overwrite: ' + ', '.join(clash))
    svg_p, dio_p, png_p = paths
    with open(svg_p, 'x', encoding='utf-8') as fh:
        fh.write(svg)
    with open(dio_p, 'x', encoding='utf-8') as fh:
        fh.write(f.drawio())
    render_png(svg_p, png_p)
    print('wrote figure.svg, template.drawio, preview.png', Image.open(png_p).size)


OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
if not os.path.isdir(OUT):
    sys.exit('output folder does not exist: ' + OUT)
DESC = ('Script-drawn schematic: layout, text and icons are generated by build.py as vector shapes '
        '(no bitmaps, no AI-generated icons).')


# ======================================================================= figure

def icard(f, x, y, w, h, icon, title, body=(), colour=HOUSE['blue'], dash=False, fill=None, isize=5.0):
    """card with a script-drawn icon on top, then a bold title and body lines, centred."""
    b = f.rect(x, y, w, h, stroke=colour, fill=fill or tint(colour), sw=LW['card'], dash=dash)
    ts, bs = FS['title'], FS['body']
    tot = (isize + 1.4 if icon else 0) + 0.72 * ts * PT + (len(body) * 1.22 * bs * PT + 0.5 if body else 0)
    top = y + (h - tot) / 2
    if icon:
        f.icon(icon, x + w / 2, top + isize / 2, isize, dark(colour))
        top += isize + 1.4
    f.text(x + w / 2, top + 0.72 * ts * PT, title, ts, bold=True, inside=b)
    if body:
        f.lines(x + w / 2, top + 0.72 * ts * PT + 0.5 + 0.5 * bs * PT, body, bs, inside=b)
    return b

def label(f, x, y, t, colour=GREY, anchor='middle', size=None, italic=False):
    return f.text(x, y, t, size or FS['small'], anchor=anchor, color=colour, italic=italic)

W, H = 183, 89                       # 4 x 2 cells (full-width export convention)
BLUE, ORANGE, GREEN, PURPLE, RED, SKY = (HOUSE['blue'], HOUSE['orange'], HOUSE['green'], HOUSE['purple'],
                                         HOUSE['red'], HOUSE['sky'])

# ---- extra script-drawn glyphs (rects, ellipses and polylines only)
def g_tokens(f, x, cy, n, c, s=2.0, gap=0.5, labels=None):
    """row of n token squares, left edge x, centred on cy."""
    for i in range(n):
        f.rect(x + i * (s + gap), cy - s / 2, s, s, stroke=c, fill='#FFFFFF', sw=LW['fine'], r=0.3)

def g_grid(f, cx, cy, s, c, n=4):
    """n x n pair grid; diagonal cells filled."""
    d = s / n
    for i in range(n):
        for j in range(n):
            f.rect(cx - s / 2 + j * d, cy - s / 2 + i * d, d, d, stroke=c,
                   fill=mid(c) if i == j else '#FFFFFF', sw=LW['fine'], r=0)

def g_chain(f, pts, c, r=0.55):
    f.line(pts, stroke=c, sw=LW['icon'])
    for x, y in pts:
        f.ellipse(x, y, r, r, stroke=c, fill=c, sw=LW['fine'])

def g_dots(f, pts, c, r=0.55):
    for x, y in pts:
        f.ellipse(x, y, r, r, stroke=c, fill='#FFFFFF', sw=LW['fine'])

def side_card(f, x, y, w, h, title, body, colour, glyph=None, gw=9.0):
    """card with a glyph column on the left (glyph(cx, cy)) and left-aligned text on the right."""
    b = f.rect(x, y, w, h, stroke=colour, fill=tint(colour), sw=LW['card'])
    ts, bs = FS['title'], FS['body']
    tx = x + (gw + 1.5 if glyph else 2.0)
    tot = 0.72 * ts * PT + (len(body) * 1.22 * bs * PT + 0.5 if body else 0)
    top = y + (h - tot) / 2
    if glyph:
        glyph(x + 1.2 + gw / 2, y + h / 2)
    f.text(tx, top + 0.72 * ts * PT, title, ts, anchor='start', bold=True, inside=b)
    if body:
        f.lines(tx, top + 0.72 * ts * PT + 0.5 + 0.5 * bs * PT, body, bs, anchor='start', inside=b)
    return b

f = Fig('active-learning-discovery', W, H)

def zone_c(x, y, w, h, title, colour, tcol):
    b = f.rect(x, y, w, h, stroke=mid(colour), fill=ZONE, sw=LW['zone'], r=1.8)
    f.text(x + 2.0, y + 3.6, title, FS['zone'], anchor='start', bold=True, inside=b, color=tcol)
    return b

def g_lattice(cx, cy, c, s=6.0):
    d = s / 2
    for k in range(3):
        f.line([(cx - d, cy - d + k * d), (cx + d, cy - d + k * d)], stroke=c, sw=LW['fine'])
        f.line([(cx - d + k * d, cy - d), (cx - d + k * d, cy + d)], stroke=c, sw=LW['fine'])
    for i in range(3):
        for j in range(3):
            f.ellipse(cx - d + i * d, cy - d + j * d, 0.6, 0.6, stroke=c, fill=c if (i + j) % 2 else '#FFFFFF', sw=LW['fine'])

def g_scatter(cx, cy, c):
    for dx, dy in [(-2.6, -2.2), (0.4, -2.8), (2.6, -0.8), (-1.4, 0.6), (1.2, 2.4), (-2.8, 2.6), (3.0, 2.0)]:
        f.ellipse(cx + dx, cy + dy, 0.6, 0.6, stroke=c, fill='#FFFFFF', sw=LW['fine'])

def g_graph(cx, cy, c, s=8.0):
    P = [(-0.45, -0.3), (0.0, -0.5), (0.45, -0.2), (-0.25, 0.35), (0.3, 0.45)]
    P = [(cx + a * s, cy + b * s) for a, b in P]
    for i, j in [(0, 1), (1, 2), (0, 3), (1, 3), (2, 4), (3, 4), (1, 4)]:
        f.line([P[i], P[j]], stroke=c, sw=LW['fine'])
    for x, y in P:
        f.ellipse(x, y, 0.85, 0.85, stroke=c, fill='#FFFFFF', sw=LW['icon'])

# zones y 3..66; lanes: A = composition route (top), B = structure route (bottom)
ZT, ZB = 3, 66
LA, LB = (17.0, 34.0), (37.0, 53.0)
cyA, cyB = sum(LA) / 2, sum(LB) / 2
# ------------------------------------------------------------ 1 generate
f.group('generate')
f.zone(3, ZT, 40, ZB - ZT, '1  Generate', BLUE)
side_card(f, 5.0, LA[0], 36, LA[1] - LA[0], 'Compositions', ['new compositions', '(relaxed oxidation-', 'state rules)'], BLUE,
          lambda cx, cy: g_tokens(f, cx - 3.6, cy, 3, dark(BLUE), s=2.0, gap=0.6), gw=8.0)
side_card(f, 5.0, LB[0], 36, LB[1] - LB[0], 'Substitution', ['partial substitutions', '(SAPS) in known', 'structures'], BLUE,
          lambda cx, cy: g_lattice(cx, cy, dark(BLUE)), gw=8.0)

# ------------------------------------------------------------ 2 filter
f.group('filter')
f.zone(47, ZT, 38, ZB - ZT, '2  Filter', PURPLE)
gb = f.rect(49.5, 10, 33, 46, stroke=PURPLE, fill=tint(PURPLE), sw=LW['card'])
f.text(66, 14.4, 'Graph networks', FS['title'], bold=True, inside=gb)
sa = f.rect(51.5, LA[0], 29, LA[1] - LA[0], stroke=PURPLE, fill='#FFFFFF', sw=LW['fine'])
f.text(66, LA[0] + 5.2, 'Composition model', FS['title'], bold=True, inside=sa)
f.lines(66, LA[0] + 6.6, ['reduced formula only,', 'no structure; keeps', 'likely stable'], FS['body'], inside=sa)
sb = f.rect(51.5, LB[0], 29, LB[1] - LB[0], stroke=PURPLE, fill='#FFFFFF', sw=LW['fine'])
f.text(66, LB[0] + 5.2, 'Structure model', FS['title'], bold=True, inside=sb)
f.lines(66, LB[0] + 6.6, ['energy from the', 'structure; keeps', 'likely stable'], FS['body'], inside=sb)
f.arrow([(41.0, cyA), (49.5, cyA)], colour=GREY, sw=LW['arrow'])
f.arrow([(41.0, cyB), (49.5, cyB)], colour=GREY, sw=LW['arrow'])
rj = f.rect(50.5, 59.5, 19, 5, stroke=RULE, fill='#F0F0F0', sw=LW['card'], dash=True)
f.text(60, 62.9, 'rejected', FS['small'], inside=rj, color=GREY)
f.arrow([(60, 56), (60, 59.5)], colour=RULE, sw=LW['minor'], dash=True)

# ------------------------------------------------------------ 3 validate (AIRSS on the composition route, then DFT)
f.group('validate')
zone_c(89, ZT, 56, ZB - ZT, '3  Validate', ORANGE, mix(ORANGE, -0.45))
ai = f.card(91.5, LA[0], 24, LA[1] - LA[0], 'AIRSS', ['100 random', 'structures per', 'kept composition'], BLUE)
db_ = f.rect(119.5, LA[0], 23.5, LB[1] - LA[0], stroke=ORANGE, fill=tint(ORANGE), sw=LW['card'])
f.icon('gear', 131.25, 27.5, 7.0, mix(ORANGE, -0.3))
f.text(131.25, 37.6, 'DFT', FS['title'], bold=True, inside=db_)
f.lines(131.25, 39.4, ['relaxation and', 'energy of each', 'candidate'], FS['body'], inside=db_)
f.arrow([(82.5, cyA), (91.5, cyA)], colour=dark(PURPLE), sw=LW['arrow'])
f.arrow([(115.5, cyA), (119.5, cyA)], colour=dark(BLUE), sw=LW['arrow'])
f.arrow([(82.5, cyB), (119.5, cyB)], colour=dark(PURPLE), sw=LW['arrow'])
us = f.rect(128, 59.5, 15, 5, stroke=RULE, fill='#F0F0F0', sw=LW['card'], dash=True)
f.text(135.5, 62.9, 'unstable', FS['small'], inside=us, color=GREY)
f.arrow([(135.5, 53), (135.5, 59.5)], colour=RULE, sw=LW['minor'], dash=True)

# ------------------------------------------------------------ 4 results
f.group('results')
f.zone(149, ZT, 31, ZB - ZT, '4  Stable set', GREEN)
icard(f, 151.5, LA[0], 26, LB[1] - LA[0], 'db', 'Verified stable', ['candidates; grows', 'every round'], GREEN, isize=6.0)
f.arrow([(143, 35.0), (151.5, 35.0)], colour=mix(ORANGE, -0.3), sw=LW['arrow'])

# ------------------------------------------------------------ feedback loops (free band below the zones)
f.group('loops')
f.arrow([(124, 53), (124, 70), (76, 70), (76, 56)], colour=dark(PURPLE), sw=LW['arrow'])
label(f, 100, 73.6, 'retrain on all new DFT labels', dark(PURPLE), size=FS['body'])
f.arrow([(164.5, 53), (164.5, 79), (23, 79), (23, 53)], colour=dark(GREEN), sw=LW['arrow'])
label(f, 93.75, 82.6, 'stable results seed new substitutions (next round)', dark(GREEN), size=FS['body'])
label(f, 180, 86.9, 'Generic labels; counts and hit rates omitted', GREY, anchor='end')

# extra check (v2): no line stroke may pass through a text box (0.3 mm clearance)
def _line_text_clashes(f, pad=0.3):
    out = []
    for it in f.items:
        if it['k'] != 'line':
            continue
        p = it['pts']
        for (x1, y1), (x2, y2) in zip(p, p[1:]):
            n = max(2, int(math.hypot(x2 - x1, y2 - y1) / 0.1))
            for bb, lab, _, _ in f.textboxes:
                if any(bb[0] - pad < x1 + (x2 - x1) * i / n < bb[2] + pad and
                       bb[1] - pad < y1 + (y2 - y1) * i / n < bb[3] + pad for i in range(n + 1)):
                    out.append(lab)
    return sorted(set(out))
_cl = _line_text_clashes(f)
if _cl:
    sys.exit('line crosses text: ' + ', '.join(map(repr, _cl)))

write_all(f, 'Active-learning discovery loop with two routes: partial substitutions in known structures are '
          'filtered by a structure graph network and sent to DFT; new compositions are filtered by a composition '
          'graph network on reduced formulas (no structure), then AIRSS initialises 100 random structures per kept '
          'composition before DFT. Verified stable candidates are kept, all new DFT labels retrain the filters and '
          'stable results seed new substitutions in the next round. ' + DESC)
