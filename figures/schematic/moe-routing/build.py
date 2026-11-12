#!/usr/bin/env python3
"""moe-routing: one spec -> figure.svg + template.drawio + preview.png (600 dpi).

Run from any directory: python3 figures/schematic/moe-routing/build.py
Layout type redrawn from scratch with invented labels; no part of any published figure is copied."""
# ======================================================================= drawing kit (paper-viz schematic kit v2)
# Self-contained: one spec below -> figure.svg + template.drawio + preview.png (600 dpi).
# Needs Python >= 3.8, Pillow, Arial or Liberation Sans (set PV_FONT_DIR if not found), and
# rsvg-convert (librsvg2-bin) or a headless Chrome/Chromium for the PNG. Exits non-zero if a
# label leaves the canvas or its box, labels overlap, or any text is below 6 pt.
import html, itertools, math, os, random, shutil, subprocess, sys, tempfile
from xml.sax.saxutils import quoteattr
from PIL import Image, ImageFont

PT = 25.4 / 72          # mm per pt
K = 72 / 25.4           # draw.io units (pt) per mm
_FONT_CANDIDATES = {False: ['Arial.TTF', 'Arial.ttf', 'arial.ttf', 'LiberationSans-Regular.ttf'],
                    True: ['Arialbd.TTF', 'Arial_Bold.ttf', 'arialbd.ttf', 'LiberationSans-Bold.ttf']}
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
                    _F[bold] = ImageFont.truetype(p, 1000); break
            if bold in _F: break
        else:
            raise SystemExit('Arial or Liberation Sans not found (set PV_FONT_DIR)')
    return _F[bold]

def tw_mm(t, size, bold=False):
    return _font(bold).getlength(t) / 1000 * size * PT

# Named palette (style-contract, architecture exception): one main colour per zone + light fill.
PAL = {'ink': '#1c2430', 'grey': '#5b6878', 'rule': '#c9ced6', 'zone': '#f2f4f7', 'card': '#ffffff',
       'blue': '#1F72AE', 'blue_light': '#DEE4F0', 'red': '#CC312C', 'red_light': '#F6DEDE',
       'teal': '#2aa198', 'teal_light': '#e3f4f1', 'purple': '#9a5bd1', 'purple_light': '#efe3f7',
       'orange': '#e08a3a', 'orange_light': '#fde8d4', 'green': '#2e7d32', 'green_light': '#e8f3ea'}
LW = {'zone': 0.5, 'card': 0.8, 'frame': 1.2, 'arrow': 1.2, 'minor': 0.8, 'data': 1.0, 'fine': 0.5}
FS = {'zone': 7.6, 'title': 6.8, 'body': 6.2, 'small': 6.0}

class Fig:
    def __init__(self, name, w, h):
        self.name, self.w, self.h = name, w, h
        self.items, self.textboxes = [], []
        self.group = None
    def g(self, gid):
        self.group = gid
    def rect(self, x, y, w, h, stroke=None, fill=None, sw=0.8, rx=0.0, dash=False):
        self.items.append(dict(k='rect', x=x, y=y, w=w, h=h, stroke=stroke, fill=fill, sw=sw, rx=rx, dash=dash, g=self.group))
        return (x, y, w, h)
    def circle(self, cx, cy, r, stroke=None, fill=None, sw=0.5):
        self.items.append(dict(k='circ', x=cx, y=cy, r=r, stroke=stroke, fill=fill, sw=sw, g=self.group))
    def line(self, pts, stroke=None, sw=1.2, arrow=False, dash=False):
        self.items.append(dict(k='line', pts=list(pts), stroke=stroke or PAL['ink'], sw=sw, arrow=arrow, dash=dash, g=self.group))
    def text(self, x, y, t, size=None, anchor='middle', color=None, bold=False, inside=None, check=True, italic=False):
        size = size or FS['body']
        em = size * PT; w = tw_mm(t, size, bold)
        self.items.append(dict(k='text', x=x, y=y, t=t, size=size, anchor=anchor, color=color or PAL['ink'],
                               bold=bold, italic=italic, tw=w, g=self.group))
        x0 = {'start': x, 'middle': x - w / 2, 'end': x - w}[anchor]
        if check:
            self.textboxes.append(((x0, y - 0.74 * em, x0 + w, y + 0.21 * em), t, inside))
        return w
    # ---------------------------------------------------------------- composites
    def zone(self, x, y, w, h, title, color=None):
        self.rect(x, y, w, h, stroke=PAL['rule'], fill=PAL['zone'], sw=LW['zone'], rx=1.6)
        self.text(x + w / 2, y + 3.6, title, FS['zone'], bold=True, color=color or PAL['ink'], inside=(x, y, w, h))
    def card(self, x, y, w, title, lines=(), color='blue', h=None, fill=None, title_color=None, dash=False, size=None):
        """Card with bold title and centred body lines; height grows with the text."""
        size = size or FS['body']
        pitch = size * PT * 1.28
        need = 1.6 + (FS['title'] * PT * 1.25 if title else 0) + pitch * len(lines) + 0.9
        h = max(h or 0, need)
        fill = fill if fill is not None else PAL.get(color + '_light', PAL['card'])
        box = self.rect(x, y, w, h, stroke=PAL.get(color, color), fill=fill, sw=LW['card'], rx=1.2, dash=dash)
        top = y + (h - (need - 2.5)) / 2
        yy = top + FS['title'] * PT * 0.9
        if title:
            self.text(x + w / 2, yy, title, FS['title'], bold=True, color=title_color or PAL['ink'], inside=box)
            yy += FS['title'] * PT * 0.35 + pitch
        else:
            yy = top + size * PT * 0.85
        for ln in lines:
            self.text(x + w / 2, yy, ln, size, color=PAL['ink'], inside=box); yy += pitch
        return box
    def arrow(self, pts, color=None, sw=None, dash=False):
        self.line(pts, stroke=color or PAL['ink'], sw=sw or LW['arrow'], arrow=True, dash=dash)
    def label(self, x, y, t, color=None, size=None, anchor='middle', bold=False):
        return self.text(x, y, t, size or FS['small'], anchor=anchor, color=color or PAL['grey'], bold=bold)
    # ---------------------------------------------------------------- checks
    def check(self):
        errs = []
        for bb, lab, box in self.textboxes:
            if bb[0] < 0 or bb[1] < 0 or bb[2] > self.w or bb[3] > self.h:
                errs.append(f'outside canvas: {lab!r} {tuple(round(v, 2) for v in bb)}')
            if box:
                bx, by, bw, bh = box
                if bb[0] < bx + 0.4 or bb[2] > bx + bw - 0.4 or bb[1] < by + 0.2 or bb[3] > by + bh - 0.2:
                    errs.append(f'outside its box: {lab!r} bb={tuple(round(v, 2) for v in bb)} box={tuple(round(v, 2) for v in box)}')
        for (a, la, _), (b, lb, _) in itertools.combinations(self.textboxes, 2):
            if a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]:
                errs.append(f'overlap: {la!r} x {lb!r}')
        return errs
    # ---------------------------------------------------------------- SVG
    def svg(self, desc=''):
        o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w:.3f}mm" height="{self.h:.3f}mm" '
             f'viewBox="0 0 {self.w:.3f} {self.h:.3f}" font-family="Arial, \'Liberation Sans\', Helvetica, sans-serif">',
             f'<title>{html.escape(self.name)}</title>', f'<desc>{html.escape(desc)}</desc>',
             f'<rect x="0" y="0" width="{self.w:.3f}" height="{self.h:.3f}" fill="#ffffff"/>']
        cur = None
        for it in self.items:
            if it['g'] != cur:
                if cur is not None: o.append('</g>')
                cur = it['g']
                if cur is not None: o.append(f'<g id="{html.escape(cur)}">')
            sw = f'{it.get("sw", 0) * PT:.4f}'
            da = ' stroke-dasharray="0.9 0.6"' if it.get('dash') else ''
            if it['k'] == 'rect':
                o.append(f'<rect x="{it["x"]:.3f}" y="{it["y"]:.3f}" width="{it["w"]:.3f}" height="{it["h"]:.3f}" rx="{it["rx"]:.2f}" '
                         f'fill="{it["fill"] or "none"}" stroke="{it["stroke"] or "none"}" stroke-width="{sw}"{da}/>')
            elif it['k'] == 'circ':
                o.append(f'<circle cx="{it["x"]:.3f}" cy="{it["y"]:.3f}" r="{it["r"]:.3f}" fill="{it["fill"] or "none"}" '
                         f'stroke="{it["stroke"] or "none"}" stroke-width="{sw}"/>')
            elif it['k'] == 'line':
                pts = list(it['pts']); head = None
                if it['arrow']:
                    (x1, y1), (x2, y2) = pts[-2], pts[-1]
                    L_ = math.hypot(x2 - x1, y2 - y1) or 1; ux, uy = (x2 - x1) / L_, (y2 - y1) / L_
                    al, aw = 1.5, 0.62
                    bx, by = x2 - ux * al, y2 - uy * al
                    head = [(x2, y2), (bx - uy * aw, by + ux * aw), (bx + uy * aw, by - ux * aw)]
                    pts[-1] = (x2 - ux * al * 0.8, y2 - uy * al * 0.8)
                d = ' '.join(f'{x:.3f},{y:.3f}' for x, y in pts)
                o.append(f'<polyline points="{d}" fill="none" stroke="{it["stroke"]}" stroke-width="{sw}" stroke-linejoin="round"{da}/>')
                if head:
                    o.append('<polygon points="' + ' '.join(f'{x:.3f},{y:.3f}' for x, y in head) + f'" fill="{it["stroke"]}"/>')
            else:
                em = it['size'] * PT
                a = (f'x="{it["x"]:.3f}" y="{it["y"]:.3f}" font-size="{em:.4f}" fill="{it["color"]}" text-anchor="{it["anchor"]}"'
                     + (' font-weight="bold"' if it['bold'] else '') + (' font-style="italic"' if it['italic'] else ''))
                o.append(f'<text {a} xml:space="preserve">{html.escape(it["t"], quote=False)}</text>')
        if cur is not None: o.append('</g>')
        o.append('</svg>')
        return '\n'.join(o) + '\n'
    # ---------------------------------------------------------------- draw.io
    def drawio(self):
        cells, n = [], itertools.count(2)
        for it in self.items:
            i = next(n)
            dash = 'dashed=1;' if it.get('dash') else ''
            if it['k'] in ('rect', 'circ'):
                if it['k'] == 'rect':
                    x, y, w, h = it['x'], it['y'], it['w'], it['h']
                    shape = f'rounded={1 if it["rx"] else 0};arcSize={min(50, 100 * it["rx"] / max(0.1, min(w, h))):.0f};absoluteArcSize=0;'
                else:
                    x, y, w, h = it['x'] - it['r'], it['y'] - it['r'], 2 * it['r'], 2 * it['r']
                    shape = 'ellipse;'
                st = (shape + f'whiteSpace=wrap;html=1;fillColor={it["fill"] or "none"};strokeColor={it["stroke"] or "none"};'
                      f'strokeWidth={it["sw"]:g};' + dash)
                cells.append(f'<mxCell id="c{i}" value="" style="{st}" vertex="1" parent="1"><mxGeometry x="{x * K:.2f}" y="{y * K:.2f}" '
                             f'width="{w * K:.2f}" height="{h * K:.2f}" as="geometry"/></mxCell>')
            elif it['k'] == 'line':
                pts = it['pts']
                st = (f'endArrow={"block;endFill=1;endSize=4" if it["arrow"] else "none"};startArrow=none;html=1;rounded=0;'
                      f'strokeColor={it["stroke"]};strokeWidth={it["sw"]:g};' + dash)
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
                st = (f'text;html=0;whiteSpace=nowrap;fontFamily=Arial;fontSize={it["size"]:g};fontColor={it["color"]};align={align};'
                      f'verticalAlign=middle;spacing=0;strokeColor=none;fillColor=none;fontStyle={(1 if it["bold"] else 0) + (2 if it["italic"] else 0)};')
                cells.append(f'<mxCell id="c{i}" value={quoteattr(it["t"])} style="{st}" vertex="1" parent="1"><mxGeometry x="{x0 * K:.2f}" '
                             f'y="{(cy - h / 2) * K:.2f}" width="{w * K:.2f}" height="{h * K:.2f}" as="geometry"/></mxCell>')
        pw, ph = round(self.w * K), round(self.h * K)
        return ('<mxfile host="paper-viz" type="device">\n'
                f'<diagram id="{self.name}" name="{self.name}">\n'
                f'<mxGraphModel dx="{pw}" dy="{ph}" grid="0" gridSize="1" guides="1" tooltips="1" connect="0" arrows="1" '
                f'fold="1" page="1" pageScale="1" pageWidth="{pw}" pageHeight="{ph}" math="0" shadow="0">\n'
                '<root>\n<mxCell id="0"/>\n<mxCell id="1" parent="0"/>\n' + '\n'.join(cells) +
                '\n</root>\n</mxGraphModel>\n</diagram>\n</mxfile>\n')

def _png(svg_p, png_p, w_mm, h_mm):
    W, H = round(w_mm / 25.4 * 600), round(h_mm / 25.4 * 600)
    if shutil.which('rsvg-convert'):
        subprocess.run(['rsvg-convert', '-d', '600', '-p', '600', '-b', 'white', '-o', png_p, svg_p], check=True)
    else:
        chrome = next((c for c in ('google-chrome', 'chromium', 'chromium-browser', 'chrome') if shutil.which(c)), None)
        if not chrome:
            raise SystemExit('need rsvg-convert or a headless Chrome/Chromium for preview.png')
        cw, ch = w_mm * 96 / 25.4, h_mm * 96 / 25.4
        with tempfile.TemporaryDirectory() as td:
            page = os.path.join(td, 'p.html'); shot = os.path.join(td, 'p.png')
            with open(page, 'w') as fh:
                fh.write(f'<html><body style="margin:0"><img src="file://{svg_p}" style="display:block;width:{cw:.3f}px;height:{ch:.3f}px"></body></html>')
            subprocess.run([chrome, '--headless=new', '--no-sandbox', '--disable-gpu', '--hide-scrollbars',
                            f'--force-device-scale-factor={600 / 96}', f'--window-size={math.ceil(cw)},{math.ceil(ch)}',
                            f'--screenshot={shot}', f'file://{page}'], check=True, capture_output=True)
            Image.open(shot).convert('RGB').crop((0, 0, W, H)).save(png_p)
    im = Image.open(png_p).convert('RGB')
    if im.size != (W, H):
        im = im.resize((W, H), Image.LANCZOS)
    im.save(png_p, dpi=(600, 600), optimize=True)
    return im.size

def finish(f, out_dir, desc=''):
    errs = f.check()
    for e in errs: print('CHECK', e)
    sizes = [it['size'] for it in f.items if it['k'] == 'text']
    widths = [it['sw'] for it in f.items if it['k'] in ('rect', 'line', 'circ') and (it['k'] == 'line' or it.get('stroke'))]
    print(f'text {min(sizes):g}-{max(sizes):g} pt, lines {min(widths):g}-{max(widths):g} pt')
    if errs or min(sizes) < 6:
        sys.exit(1)
    svg_p, dio_p, png_p = (os.path.join(out_dir, n) for n in ('figure.svg', 'template.drawio', 'preview.png'))
    with open(svg_p, 'w') as fh: fh.write(f.svg(desc))
    with open(dio_p, 'w') as fh: fh.write(f.drawio())
    print('wrote figure.svg, template.drawio, preview.png', _png(svg_p, png_p, f.w, f.h))

# ======================================================================= figure
OUT = os.path.dirname(os.path.abspath(__file__))   # writes next to this script
# ---------------------------------------------------------------- spec: sparse mixture-of-experts layer with top-2 routing
W, H = 89, 66
f = Fig('moe-routing', W, H)
def R(b): return b[0] + b[2]
def M(b): return b[1] + b[3] / 2
def C(b): return b[0] + b[2] / 2
def B(b): return b[1] + b[3]
f.g('frame'); f.zone(1, 1, 87, 64, 'Sparse mixture-of-experts layer', PAL['ink'])
f.g('cards')
tok = f.card(30, 55, 29, None, ['token x'], 'grey', fill='#ffffff')
rt = f.card(30, 43, 29, 'Router', ['softmax over 4 experts'], 'purple')
probs = [0.08, 0.52, 0.11, 0.29]
EX = []
for k, p in enumerate(probs):
    on = p in sorted(probs)[-2:]
    EX.append(f.card(5 + k * 20.3, 21, 17.5, f'Expert {k + 1}', ['FFN'], 'orange' if on else 'grey', fill=None if on else '#ffffff', dash=not on))
out = f.card(30, 7.5, 29, None, ['y = 0.64 E2(x) + 0.36 E4(x)'], 'grey', fill='#ffffff')
f.g('bars')
for k, (p, e) in enumerate(zip(probs, EX)):
    hh = p * 12
    on = p in sorted(probs)[-2:]
    f.rect(C(e) - 2.2, 38.5 - hh, 4.4, hh, fill=PAL['orange'] if on else PAL['rule'], stroke=None, sw=0)
    f.text(C(e) + 3.0, 38.3, f'{p:.2f}', FS['small'], anchor='start')
f.label(4.5, 33.4, 'router p', color=PAL['purple'], anchor='start')
f.g('arrows')
f.arrow([(C(tok), tok[1]), (C(tok), B(rt) + 0.3)], sw=LW['minor'])
for k in (1, 3):
    e = EX[k]
    f.arrow([(C(rt), rt[1]), (C(rt), 40.5), (C(e) - 5.5, 40.5), (C(e) - 5.5, B(e) + 0.3)], sw=LW['minor'], color=PAL['orange'])
    f.arrow([(C(e), e[1]), (C(e), 17), (C(out), 17), (C(out), B(out) + 0.3)], sw=LW['minor'], color=PAL['orange'])
f.label(44.5, 63.0, 'top-2 experts run; the other two are skipped', color=PAL['grey'])
f.g(None)
finish(f, OUT, 'Schematic: token routed to the top-2 of 4 experts in a sparse MoE layer. Layout type only; numbers illustrative.')
