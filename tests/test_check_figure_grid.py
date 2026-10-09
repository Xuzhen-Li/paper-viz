"""Preview size rules in tools/check_png_grid.sh (used by tools/check_figure.sh). No R needed.

Run: python3 -m unittest discover tests

House-grid figures (meta.yaml `cells: WxH`): each side of 1 / 2 / 3 / 4 cells must be
43 / 89 / 135 / 183 mm; expected px = round(mm / 25.4 * dpi), +-1 px, dpi from the PNG pHYs
chunk. Figures without `cells` keep the fixed >= 300 px floor.
"""
from __future__ import annotations

import os
import shutil
import struct
import subprocess
import tempfile
import unittest
import uuid
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "tools" / "check_png_grid.sh"
CHECK = ROOT / "tools" / "check_figure.sh"
SHELLS = [s for s in ("sh", "dash", "bash") if shutil.which(s)]

GRID_MM = {1: 43, 2: 89, 3: 135, 4: 183}


def _chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def write_png(path: Path, w: int, h: int, dpi: float | None = None, text_before: bool = False) -> None:
    """Grey PNG; pHYs (pixels per metre) when dpi is given, like ggsave / savefig write it."""
    chunks = [_chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 0, 0, 0, 0))]
    if text_before:
        chunks.append(_chunk(b"tEXt", b"Software\x00" + b"x" * 300))
    if dpi is not None:
        ppm = round(dpi / 0.0254)
        chunks.append(_chunk(b"pHYs", struct.pack(">IIB", ppm, ppm, 1)))
    raw = b"".join(b"\x00" + b"\xff" * w for _ in range(h))
    chunks.append(_chunk(b"IDAT", zlib.compress(raw, 1)))
    chunks.append(_chunk(b"IEND", b""))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + b"".join(chunks))


def preview_dpi(cw: int) -> float:
    """pv_save_house / save_house: preview.png is 1200 px wide, so dpi = 1200 / width in."""
    return 1200 / (GRID_MM[cw] / 25.4)


def grid_px(n: int, dpi: float) -> int:
    return int(GRID_MM[n] / 25.4 * dpi + 0.5)


class GridCheck(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="pv-grid-"))
        self.addCleanup(shutil.rmtree, self.tmp, True)

    def run_check(self, w: int, h: int, cells: str | None, dpi: float | None = None, shell: str = "sh",
                  **png_kw) -> subprocess.CompletedProcess[str]:
        d = self.tmp / uuid.uuid4().hex[:8]
        d.mkdir()
        write_png(d / "preview.png", w, h, dpi, **png_kw)
        meta = "title: t\nlang: R\n" + (f"cells: {cells}\n" if cells is not None else "")
        (d / "meta.yaml").write_text(meta, encoding="utf-8")
        return subprocess.run([shell, str(LIB), str(d / "preview.png"), str(d / "meta.yaml")],
                              capture_output=True, text=True, encoding="utf-8")

    def assertPass(self, *a, **kw) -> None:
        for sh in SHELLS:
            r = self.run_check(*a, shell=sh, **kw)
            self.assertEqual(r.returncode, 0, f"{sh}: {r.stderr}")

    def assertFail(self, *a, msg: str = "", **kw) -> None:
        for sh in SHELLS:
            r = self.run_check(*a, shell=sh, **kw)
            self.assertNotEqual(r.returncode, 0, f"{sh}: expected failure")
            self.assertIn(msg, r.stderr, f"{sh}: {r.stderr}")

    def grid(self, cw: int, ch: int, dw: int = 0, dh: int = 0, **kw) -> dict:
        dpi = preview_dpi(cw)
        return dict(w=grid_px(cw, dpi) + dw, h=grid_px(ch, dpi) + dh, cells=f"{cw}x{ch}", dpi=dpi, **kw)

    # --- grid figures ---------------------------------------------------------------
    def test_1x1_passes(self) -> None:
        self.assertPass(**self.grid(1, 1))

    def test_2x1_passes(self) -> None:
        self.assertPass(**self.grid(2, 1))

    def test_4x1_strip_passes_below_px_floor(self) -> None:
        g = self.grid(4, 1)
        self.assertLess(g["h"], 300)  # a strip is legal on the grid even under 300 px
        self.assertPass(**g)

    def test_4x3_and_quoted_cells(self) -> None:
        self.assertPass(**self.grid(4, 3))
        g = self.grid(2, 2)
        g["cells"] = '"2x2"'
        self.assertPass(**g)
        g = self.grid(3, 1)
        g["cells"] = "3×1"
        self.assertPass(**g)

    def test_plus_minus_one_px_passes(self) -> None:
        for dw, dh in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, -1)):
            self.assertPass(**self.grid(2, 1, dw, dh))

    def test_off_by_two_px_fails(self) -> None:
        self.assertFail(**self.grid(2, 1, 0, 2), msg="cells 2x1 needs 89 x 43 mm")
        self.assertFail(**self.grid(2, 1, -2, 0), msg="got")

    def test_wrong_height_fails(self) -> None:
        g = self.grid(2, 1)
        g["h"] = g["w"]  # rendered 2x2 but meta says 2x1
        self.assertFail(**g, msg="89 x 43 mm")

    def test_cells_out_of_range_fails(self) -> None:
        for bad in ("5x1", "1x5", "0x1"):
            g = self.grid(1, 1)
            g["cells"] = bad
            self.assertFail(**g, msg="off the house grid")

    def test_cells_malformed_fails(self) -> None:
        g = self.grid(1, 1)
        g["cells"] = "two by one"
        self.assertFail(**g, msg="is not WxH")

    def test_missing_dpi_fails(self) -> None:
        g = self.grid(2, 1)
        g["dpi"] = None
        self.assertFail(**g, msg="cannot read dpi")

    def test_phys_after_other_chunks(self) -> None:
        self.assertPass(**self.grid(2, 1, text_before=True))

    def test_600_dpi_figure_size(self) -> None:
        # same rule at the export dpi: 89 x 43 mm at 600 dpi = 2102 x 1016 px
        self.assertPass(w=2102, h=1016, cells="2x1", dpi=600)
        self.assertFail(w=2102, h=1018, cells="2x1", dpi=600, msg="2102 x 1016 px")

    # --- figures without cells ------------------------------------------------------
    def test_no_cells_tiny_fails(self) -> None:
        self.assertFail(w=3, h=2, cells=None, dpi=None, msg="at least 300 px")

    def test_no_cells_old_preview_passes(self) -> None:
        self.assertPass(w=1200, h=511, cells=None, dpi=None)

    def test_no_cells_short_fails(self) -> None:
        self.assertFail(w=1200, h=299, cells=None, dpi=None, msg="1200x299 px")


class CheckFigureUsesGridCheck(unittest.TestCase):
    """End-to-end through tools/check_figure.sh with a tiny Python-only figure (no R)."""

    def make_fig(self, w: int, h: int, cells: str | None, dpi: float | None) -> Path:
        fig = ROOT / "figures" / "zz-unittest" / f"grid-{uuid.uuid4().hex[:8]}"
        fig.mkdir(parents=True)
        self.addCleanup(shutil.rmtree, fig.parent, True)
        write_png(fig / "src.png", w, h, dpi)
        (fig / "meta.yaml").write_text("title: t\nlang: Python\n" + (f"cells: {cells}\n" if cells else ""),
                                       encoding="utf-8")
        (fig / "make_data.py").write_text("pass\n", encoding="utf-8")
        (fig / "plot.py").write_text("import shutil\nshutil.copyfile('src.png', 'preview.png')\n", encoding="utf-8")
        return fig

    def run_fig(self, fig: Path) -> subprocess.CompletedProcess[str]:
        env = dict(os.environ)
        env.setdefault("PYTHON", "python3")
        return subprocess.run(["sh", str(CHECK), str(fig)], capture_output=True, text=True, cwd=ROOT, env=env)

    def test_grid_pass_and_fail(self) -> None:
        dpi = preview_dpi(4)
        ok = self.run_fig(self.make_fig(1200, grid_px(1, dpi), "4x1", dpi))
        self.assertEqual(ok.returncode, 0, ok.stderr)
        bad = self.run_fig(self.make_fig(1200, grid_px(1, dpi) + 5, "4x1", dpi))
        self.assertNotEqual(bad.returncode, 0)
        self.assertIn("cells 4x1 needs 183 x 43 mm", bad.stderr)

    def test_no_cells_floor(self) -> None:
        bad = self.run_fig(self.make_fig(3, 2, None, None))
        self.assertNotEqual(bad.returncode, 0)
        self.assertIn("at least 300 px", bad.stderr)


if __name__ == "__main__":
    unittest.main()
