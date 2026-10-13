"""tools/png_within_tolerance.py: skip committing re-rendered previews that differ only by noise.

Run: python3 -m unittest discover tests
Within tolerance = same size, < 0.01 % of pixels differ, every RGBA channel diff <= 2.
"""
from __future__ import annotations

import contextlib
import importlib.util
import io
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "png_within_tolerance.py"
spec = importlib.util.spec_from_file_location("png_within_tolerance", SCRIPT)
pwt = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(pwt)


def _chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if pa <= pb and pa <= pc else (b if pb <= pc else c)


def _filter(row: bytes, prev: bytes, ftype: int, bpp: int) -> bytes:
    out = bytearray()
    for i, x in enumerate(row):
        a = row[i - bpp] if i >= bpp else 0
        b = prev[i]
        c = prev[i - bpp] if i >= bpp else 0
        pred = (0, a, b, (a + b) >> 1, _paeth(a, b, c))[ftype]
        out.append((x - pred) & 0xFF)
    return bytes([ftype]) + bytes(out)


def write_png(path: Path, pixels: list[list[tuple]], ctype: int = 2, palette: list[tuple] | None = None,
              cycle_filters: bool = True) -> None:
    """pixels: rows of RGB / RGBA / grey / palette-index tuples. Rows use filters 0-4 in turn."""
    h, w = len(pixels), len(pixels[0])
    nch = pwt.CHANNELS[ctype]
    raw = bytearray()
    prev = bytes(w * nch)
    for y, row in enumerate(pixels):
        data = bytes(v for px in row for v in (px if isinstance(px, tuple) else (px,)))
        raw += _filter(data, prev, (y % 5) if cycle_filters else 0, nch)
        prev = data
    chunks = [_chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, ctype, 0, 0, 0))]
    if palette:
        chunks.append(_chunk(b"PLTE", bytes(v for c in palette for v in c)))
    chunks += [_chunk(b"IDAT", zlib.compress(bytes(raw))), _chunk(b"IEND", b"")]
    path.write_bytes(pwt.SIG + b"".join(chunks))


def gradient(w: int, h: int) -> list[list[tuple]]:
    return [[((x * 7 + y) % 256, (y * 5) % 256, (x * y) % 256) for x in range(w)] for y in range(h)]


class Tolerance(unittest.TestCase):
    W, H = 200, 100  # 20 000 px: 0.01 % = 2 px, so 1 differing pixel is inside, 2 are not

    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="pv-tol-"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.base = gradient(self.W, self.H)
        self.old = self.tmp / "old.png"
        write_png(self.old, self.base)

    def variant(self, changes: dict[tuple[int, int], tuple], name: str = "new.png", **kw) -> Path:
        px = [list(r) for r in self.base]
        for (x, y), v in changes.items():
            px[y][x] = v
        p = self.tmp / name
        write_png(p, px, **kw)
        return p

    def shift(self, x: int, y: int, d: int) -> tuple:
        r, g, b = self.base[y][x]
        return (min(255, r + d) if r + d <= 255 else r - d, g, b)

    def cli(self, old: Path, new: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, str(SCRIPT), str(old), str(new)], capture_output=True, text=True)

    def test_byte_only_difference_is_within(self) -> None:
        new = self.variant({}, cycle_filters=False)  # same pixels, different encoding
        self.assertNotEqual(self.old.read_bytes(), new.read_bytes())
        r = self.cli(self.old, new)
        self.assertEqual(r.returncode, 0, r.stdout)
        self.assertIn("0 differing pixel", r.stdout)

    def test_one_pixel_diff_two_is_within(self) -> None:
        r = self.cli(self.old, self.variant({(5, 5): self.shift(5, 5, 2)}))
        self.assertEqual(r.returncode, 0, r.stdout)
        self.assertIn("1 differing pixel", r.stdout)

    def test_channel_diff_three_is_real(self) -> None:
        r = self.cli(self.old, self.variant({(5, 5): self.shift(5, 5, 3)}))
        self.assertEqual(r.returncode, 1, r.stdout)
        self.assertIn("max channel diff 3", r.stdout)

    def test_fraction_at_limit_is_real(self) -> None:
        # 2 of 20 000 px = 0.01 %: not < 0.01 %
        r = self.cli(self.old, self.variant({(5, 5): self.shift(5, 5, 1), (9, 9): self.shift(9, 9, 1)}))
        self.assertEqual(r.returncode, 1, r.stdout)
        self.assertIn("2 differing pixel", r.stdout)

    def test_many_pixels_real(self) -> None:
        ch = {(x, 10): self.shift(x, 10, 1) for x in range(50)}
        self.assertEqual(self.cli(self.old, self.variant(ch)).returncode, 1)

    def test_size_change_is_real(self) -> None:
        bigger = self.tmp / "big.png"
        write_png(bigger, gradient(self.W, self.H + 1))
        r = self.cli(self.old, bigger)
        self.assertEqual(r.returncode, 1, r.stdout)
        self.assertIn("size changed 200x100 -> 200x101", r.stdout)

    def test_alpha_counts(self) -> None:
        rgba = [[px + (255,) for px in row] for row in self.base]
        a = self.tmp / "a.png"
        write_png(a, rgba, ctype=6)
        rgba[3][3] = rgba[3][3][:3] + (250,)
        b = self.tmp / "b.png"
        write_png(b, rgba, ctype=6)
        r = self.cli(a, b)
        self.assertEqual(r.returncode, 1, r.stdout)
        self.assertIn("max channel diff 5", r.stdout)
        # RGB vs identical-looking opaque RGBA: same pixels after decoding
        self.assertEqual(self.cli(self.old, a).returncode, 0)

    def test_grey_and_palette_decode(self) -> None:
        g = self.tmp / "g.png"
        write_png(g, [[(x + y) % 256 for x in range(16)] for y in range(8)], ctype=0)
        w, h, rows = pwt.decode_rgba(str(g))
        self.assertEqual((w, h, rows[2][4 * 3:4 * 3 + 4]), (16, 8, bytes([5, 5, 5, 255])))
        pal = [(10, 20, 30), (200, 100, 50)]
        p = self.tmp / "p.png"
        write_png(p, [[x % 2 for x in range(4)] for _ in range(2)], ctype=3, palette=pal)
        _, _, rows = pwt.decode_rgba(str(p))
        self.assertEqual(rows[1][4:8], bytes([200, 100, 50, 255]))

    def test_not_a_png_exit_2(self) -> None:
        bad = self.tmp / "bad.png"
        bad.write_text("nope")
        r = self.cli(self.old, bad)
        self.assertEqual(r.returncode, 2, r.stdout)
        self.assertIn("cannot compare", r.stdout)

    def test_custom_limits(self) -> None:
        new = self.variant({(5, 5): self.shift(5, 5, 3)})
        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(pwt.main([str(self.old), str(new), "--max-channel", "3"]), 0)
        self.assertIn("limit <= 3", out.getvalue())


if __name__ == "__main__":
    unittest.main()
