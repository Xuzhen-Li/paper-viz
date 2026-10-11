"""Helpers for the editable architecture schematic (layout in body.py, entry point build_v3.py)."""
import math, re, numpy as np, colorsys
from pathlib import Path
from PIL import ImageFont
from matplotlib.textpath import TextPath
from matplotlib.font_manager import FontProperties
import matplotlib; matplotlib.rcParams['mathtext.fontset']='stix'
W,H=1300,712
HERE=Path(__file__).resolve().parent
ICON_DIR=HERE/'icons'
out=[]; fallback=[]; defs=[]; iconfb=[]
import base64
from PIL import Image as _I
def ICON(n,cx,cy,w):
    p=ICON_DIR/f'{n}.png'; im=_I.open(p); hh=w*im.height/im.width
    b64=base64.b64encode(p.read_bytes()).decode()
    a(f'<image class="icon-{n}" x="{cx-w/2:.1f}" y="{cy-hh/2:.1f}" width="{w}" height="{hh:.1f}" href="data:image/png;base64,{b64}"/>')
def tofb(start):
    iconfb.extend(out[start:]); del out[start:]
def a(s): out.append(s)
SANS="Roboto Condensed, Arial Narrow, sans-serif"; SERIF="STIX Two Math, Times, serif"
def esc(t): return t.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')

def _measure_font():
    """Roboto Condensed Italic (variable) is used only to measure sub/superscript widths."""
    from matplotlib import font_manager
    for f in font_manager.findSystemFonts():
        if Path(f).name.startswith('RobotoCondensed-Italic'):
            return f
    raise SystemExit('Roboto Condensed is not installed; install it (Google Fonts, OFL) and rerun')
_F={}
def tw(t,sz,bold=False):
    k=(round(sz*10),bold)
    if k not in _F: _F[k]=ImageFont.truetype(_measure_font(),k[0])
    return _F[k].getlength(t)/10
def rich(t,s=11):
    res=''; i=0; prev=None
    for m in re.finditer(r'([_^])\{([^}]*)\}',t):
        txt=m.group(2); dx=''; post=''
        if prev is not None and m.start()==prev[0]:
            dx=f' dx="{-tw(prev[1],s*0.7):.1f}"'
            extra=max(0,tw(prev[1],s*0.7)-tw(txt,s*0.7))
            if extra: post=f' dx="{extra:.1f}"'
        res+=esc(t[i:m.start()])
        dy=s*0.3 if m.group(1)=='_' else -s*0.45
        res+=f'<tspan{dx} dy="{dy:.1f}" font-size="{s*0.7:.1f}" font-style="italic">{esc(txt)}</tspan><tspan{post} dy="{-dy:.1f}">\u200b</tspan>'
        prev=(m.end(),txt); i=m.end()
    return res+esc(t[i:])
FS=1.36
def T(x,y,t,s=11,w='normal',anchor='middle',fam=SANS,style='normal',fill='#1c2430'):
    s=s*FS*(1.0 if s>=13 else 1)*(0.92 if s<10 else 1); w='bold' if w=='bold' else '500'
    a(f'<text x="{x}" y="{y}" font-family="{fam}" font-size="{s:.1f}" font-weight="{w}" font-style="{style}" text-anchor="{anchor}" fill="{fill}">{rich(t,s)}</text>')
# ---- math via mathtext -> paths
MP=FontProperties(family='STIXGeneral')
def M(x,y,t,s=11,anchor='middle',w='normal',tex=None):
    """Math as vector paths. t: plain text (title + hidden fallback); tex: mathtext source (defaults to t)."""
    s=s*FS*1.15
    try:
        tp=TextPath((0,0),'$'+(tex or t)+'$',size=s,prop=MP)
    except Exception as e:
        raise SystemExit(f'math failed: {t}: {e}')
    ex=tp.get_extents(); wdt=ex.x1  # advance approx
    ox={'middle':-wdt/2,'start':0,'end':-wdt}[anchor]
    d=[]
    for verts,code in tp.iter_segments():
        pts=[(verts[i],verts[i+1]) for i in range(0,len(verts),2)]
        c={1:'M',2:'L',3:'Q',4:'C',79:'Z'}[code]
        d.append('Z' if c=='Z' else c+' '.join(f'{px+ox:.2f},{-py:.2f}' for px,py in pts))
    a(f'<path class="math" transform="translate({x},{y})" d="{" ".join(d)}" fill="#141a24" stroke="#141a24" stroke-width="0.45" stroke-linejoin="round"><title>{esc(t)}</title></path>')
    fallback.append(f'<text x="{x}" y="{y}" font-family="{SERIF}" font-style="italic" font-size="{s:.1f}" text-anchor="{anchor}">{rich(t,s)}</text>')
# ---- gradients / shadows
def shade(hexc,f):
    h=hexc.lstrip('#'); h=''.join(ch*2 for ch in h) if len(h)==3 else h; r,g,b=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    hh,l,ss=colorsys.rgb_to_hls(r,g,b); l=min(1,max(0,l*f if f<1 else l+(1-l)*(f-1)))
    r,g,b=colorsys.hls_to_rgb(hh,l,ss); return '#%02x%02x%02x'%(int(r*255),int(g*255),int(b*255))
_G={}
def grad(c):
    if c in _G: return _G[c]
    gid=f'g{len(_G)}'; _G[c]=gid
    defs.append(f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{shade(c,1.35)}"/><stop offset="1" stop-color="{shade(c,0.94)}"/></linearGradient>')
    return gid
def R(x,y,w,h,fill='#fff',stroke='#555',rx=6,sw=1.2,dash=None,op=1,zone=False):
    d=f' stroke-dasharray="{dash}"' if dash else ''
    sw2= sw*1.1 if (sw<=1.05 and rx>=8) else sw*1.75
    rx2=max(rx*1.6,10) if rx else 0
    filt='' if sw==0 else (' filter="url(#shz)"' if rx>=8 else ' filter="url(#sh)"')
    stroke=shade(stroke,0.8) if stroke not in('#fff',) else stroke
    a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx2}" fill="url(#{grad(fill)})" fill-opacity="{op}" stroke="{stroke}" stroke-width="{sw2:.2f}"{d}{filt}/>')
def L(pts,c='#444',sw=1.6,arrow=True,dash=None):
    if c=='#444': c='#334155'
    p=' '.join(f'{x},{y}' for x,y in pts); d=f' stroke-dasharray="{dash}"' if dash else ''
    mk=f' marker-end="url(#{marker(c)})"' if arrow else ''
    a(f'<polyline points="{p}" fill="none" stroke="{c}" stroke-width="{sw*1.9:.2f}" stroke-linejoin="round" stroke-linecap="round"{d}{mk}/>')
_M={}
def marker(c):
    """Id of the arrowhead marker for colour c (defined once, numbered in order of first use)."""
    if c=='#444': c='#334155'
    if c not in _M:
        _M[c]=f'ar{len(_M)+1}'
        defs.append(f'<marker id="{_M[c]}" viewBox="0 0 12 10" refX="10" refY="5" markerWidth="3.8" markerHeight="3.8" orient="auto-start-reverse"><path d="M0,0 L12,5 L0,10 L2.5,5z" fill="{c}"/></marker>')
    return _M[c]
def bend(d,c,sw=1.6):
    """Curved connector (SVG path d) with the same stroke and arrowhead as L()."""
    a(f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{sw*1.9:.2f}" stroke-linejoin="round" stroke-linecap="round" marker-end="url(#{marker(c)})"/>')
def curve(xs,ys,c,sw=1.4):
    a('<polyline fill="none" stroke="%s" stroke-width="%.2f" stroke-linejoin="round" stroke-linecap="round" points="%s"/>'%(c,sw*1.75,' '.join(f'{x:.1f},{y:.1f}' for x,y in zip(xs,ys))))
def axes(x,y,w,h,lx=None,ly=None):
    L([(x,y+h),(x,y-4)],'#222',1.2,True); L([(x,y+h),(x+w+4,y+h)],'#222',1.2,True)
def snow(cx,cy,r=7,c='#5a8fc7'):
    st=len(out); _snow(cx,cy,r); tofb(st); ICON('snowflake',cx,cy,r*3.6)
def _snow(cx,cy,r=7,c='#5a8fc7'):
    r*=1.3; g=['<g class="icon-snowflake" stroke-linecap="round">']
    for col,w in (('#2f5f9a',3.2),('#e8f2ff',1.6)):
        for k in range(3):
            an=k*math.pi/3+math.pi/2; dx,dy=r*math.cos(an),r*math.sin(an)
            g.append(f'<line x1="{cx-dx:.1f}" y1="{cy-dy:.1f}" x2="{cx+dx:.1f}" y2="{cy+dy:.1f}" stroke="{col}" stroke-width="{w}"/>')
            for sgn in (1,-1):
                bx,by=cx+sgn*dx*0.6,cy+sgn*dy*0.6; base=an+(0 if sgn>0 else math.pi)
                for t in (0.6,-0.6):
                    b2=base+math.pi+t
                    g.append(f'<line x1="{bx:.1f}" y1="{by:.1f}" x2="{bx-3.4*math.cos(b2-math.pi):.1f}" y2="{by-3.4*math.sin(b2-math.pi):.1f}" stroke="{col}" stroke-width="{w*0.8:.1f}"/>')
    g.append('</g>'); a(''.join(g))
def flame(cx,cy,s=1.0):
    st=len(out); _flame(cx,cy,s); tofb(st); ICON('flame',cx,cy-3,19*s)
def _flame(cx,cy,s=1.0):
    s*=1.35
    a(f'<g class="icon-flame" transform="translate({cx},{cy}) scale({s})" filter="url(#sh)"><path d="M0,-12 C7,-6 9,0 7,5 C5,10 -5,10 -7,5 C-9,0 -6,-4 -3,-7 C-2,-3 0,-2 1,-4 C2,-7 0,-10 0,-12Z" fill="url(#flameo)" stroke="#b5420c" stroke-width="0.6"/><path d="M0,-3 C3.5,0.5 3.5,5 0,7.5 C-3.5,5 -3.5,1.5 0,-3Z" fill="url(#flamei)"/></g>')
STATIC_DEFS='''<filter id="sh" x="-20%" y="-20%" width="140%" height="150%"><feDropShadow dx="0" dy="1.6" stdDeviation="1.8" flood-color="#1b2a40" flood-opacity="0.28"/></filter>
<filter id="shz" x="-5%" y="-5%" width="110%" height="110%"><feDropShadow dx="0" dy="1.2" stdDeviation="2.2" flood-color="#1b2a40" flood-opacity="0.16"/></filter>
<radialGradient id="snowbg" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#8fc3ff"/><stop offset="1" stop-color="#2f6db3"/></radialGradient>
<linearGradient id="flameo" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#e2410f"/><stop offset="0.6" stop-color="#f68a1e"/><stop offset="1" stop-color="#ffb43a"/></linearGradient>
<linearGradient id="flamei" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#ffe9a0"/><stop offset="1" stop-color="#ffc21f"/></linearGradient>
<linearGradient id="cyl" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#c9d2de"/><stop offset="0.35" stop-color="#f7f9fc"/><stop offset="1" stop-color="#9aa8ba"/></linearGradient>
<linearGradient id="cyltop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#dfe5ee"/></linearGradient>
<linearGradient id="gaugeg" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#b7e07a"/><stop offset="0.5" stop-color="#43a047"/><stop offset="1" stop-color="#1b5e20"/></linearGradient>
<radialGradient id="nodeg" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#d7dee8"/></radialGradient>'''
def finish(path):
    s=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">','<defs>',STATIC_DEFS,*defs,'</defs>',f'<rect width="{W}" height="{H}" fill="#fff"/>','<g id="figure">',*out,'</g>','<g id="vector-icon-fallback" visibility="hidden">',*iconfb,'</g>','<g id="math-text-fallback" visibility="hidden">',*fallback,'</g>','</svg>']
    Path(path).write_text('\n'.join(s))
