"""Rebuild arch_v3.svg (and arch_v3.png if rsvg-convert is installed).

Run from any directory:  python3 docs/house-style/arch/build_v3.py
"""
import shutil, subprocess
from helpers import *
rng=np.random.default_rng(3)
exec((HERE/'body.py').read_text())
finish(HERE/'arch_v3.svg')
if shutil.which('rsvg-convert'):
    subprocess.run(['rsvg-convert','-w','2000','-o',str(HERE/'arch_v3.png'),str(HERE/'arch_v3.svg')],check=True)
else:
    print('rsvg-convert not found; arch_v3.png not rebuilt')
