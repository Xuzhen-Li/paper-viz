"""House style smoke tests (R + Python). Run: python3 -m unittest discover tests

Python: theme loads, exported PNG is mm / 25.4 * 600 px, PDF page is mm / 25.4 * 72 pt,
PDF text is TrueType (not outlined), single-column single panel gets +2 pt once, legacy
style.PALETTES is unchanged. R: runs tests/test_theme_house.R when Rscript + ggplot2 exist.
"""
from __future__ import annotations

import re
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STYLES = ROOT / "styles" / "python"

try:
    import matplotlib

    matplotlib.use("Agg")
    HAVE_MPL = True
except ImportError:  # pragma: no cover
    HAVE_MPL = False

CHIP = ["#134aa3", "#f6a3b1", "#0b5475", "#dc1f26", "#835ca6", "#f7922c", "#fbee61", "#981b1e"]


def png_size(path: Path) -> tuple[int, int]:
    with open(path, "rb") as fh:
        head = fh.read(24)
    return struct.unpack(">II", head[16:24])


def pdf_page_size(path: Path) -> tuple[float, float]:
    if shutil.which("pdfinfo"):
        out = subprocess.run(["pdfinfo", str(path)], capture_output=True, text=True).stdout
        m = re.search(r"Page size:\s+([0-9.]+) x ([0-9.]+)", out)
        return float(m.group(1)), float(m.group(2))
    m = re.search(rb"/MediaBox\s*\[\s*[0-9.]+\s+[0-9.]+\s+([0-9.]+)\s+([0-9.]+)", path.read_bytes())
    return float(m.group(1)), float(m.group(2))


@unittest.skipUnless(HAVE_MPL, "matplotlib not installed")
class PythonHouseTheme(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(STYLES))
        import house  # noqa: E402
        import style  # noqa: E402

        cls.house = house
        cls.style = style
        cls.tmp = Path(tempfile.mkdtemp())

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def setUp(self):
        import matplotlib.pyplot as plt

        plt.close("all")
        self.house.apply_house_style()

    def _plot(self, width, height_mm, ncols=1):
        h = self.house
        fig, axes = h.house_figure(width, height_mm=height_mm, ncols=ncols)
        axes = axes if ncols > 1 else [axes]
        for i, ax in enumerate(axes):
            ax.plot([0, 1, 2], [0, 1, 4], color=h.pv_palette("house")[i])
            ax.scatter([0, 1, 2], [0, 1, 4], color=h.pv_palette("house")[i], **h.SCATTER)
            ax.set_xlabel("Time (d)")
            ax.set_ylabel("Signal (a.u.)")
            ax.text(0.05, 0.9, "N = 3", transform=ax.transAxes)
            h.add_house_tag(ax, "ABC"[i])
        return fig, axes

    def test_legacy_unchanged(self):
        self.assertEqual(self.style.PALETTES["categorical"], CHIP)
        self.assertEqual(self.house.pv_palette("categorical"), CHIP)
        self.assertTrue(callable(self.style.apply_style))

    def test_palettes(self):
        h = self.house
        self.assertEqual(h.pv_palette("house", 3), ["#1F72AE", "#F77E12", "#119B76"])
        self.assertEqual(h.pv_palette("house_div")[4], "#F7F7F7")
        self.assertEqual(h.pv_palette("ssp")["SSP5-8.5"], "#9C2125")
        self.assertEqual(len(h.pv_palette("house_div", 11)), 11)
        with self.assertRaises(ValueError):
            h.pv_palette("house", 10)

    def test_rc(self):
        import matplotlib as mpl

        self.assertEqual(mpl.rcParams["xtick.labelsize"], 7)
        self.assertEqual(mpl.rcParams["axes.labelsize"], 8)
        self.assertEqual(mpl.rcParams["axes.linewidth"], 0.5)
        self.assertEqual(mpl.rcParams["lines.linewidth"], 1.5)
        self.assertEqual(mpl.rcParams["xtick.direction"], "out")
        self.assertAlmostEqual(mpl.rcParams["xtick.major.size"], 72 / 25.4, places=6)
        self.assertFalse(mpl.rcParams["axes.grid"])
        self.assertEqual(mpl.rcParams["pdf.fonttype"], 42)

    def _check_export(self, res, w_mm, h_mm):
        w_px, h_px = png_size(res["png"])
        self.assertLessEqual(abs(w_px - round(w_mm / 25.4 * 600)), 1)
        self.assertLessEqual(abs(h_px - round(h_mm / 25.4 * 600)), 1)
        pw, ph = pdf_page_size(res["pdf"])
        self.assertLess(abs(pw - w_mm / 25.4 * 72), 1)
        self.assertLess(abs(ph - h_mm / 25.4 * 72), 1)
        raw = res["pdf"].read_bytes()
        self.assertIn(b"/FontFile2", raw)  # embedded TrueType => text kept as text
        self.assertEqual(png_size(res["pdf"].parent / "preview.png")[0], 1200)

    def test_single_column_single_panel(self):
        fig, (ax,) = self._plot("single", 76)
        res = self.house.save_house(fig, self.tmp / "single" / "figure")
        self.assertEqual(res["bump"], 2)
        self.assertEqual(ax.xaxis.get_ticklabels()[0].get_fontsize(), 9)
        self.assertEqual(ax.xaxis.label.get_fontsize(), 10)
        self._check_export(res, 89, 76)
        # saving again must not bump twice
        self.assertEqual(self.house.save_house(fig, self.tmp / "single" / "again", preview=False)["bump"], 0)

    def test_double_column(self):
        fig, axes = self._plot("double", 60, ncols=3)
        res = self.house.save_house(fig, self.tmp / "double" / "figure")
        self.assertEqual(res["bump"], 0)
        self.assertEqual(axes[0].xaxis.label.get_fontsize(), 8)
        self._check_export(res, 183, 60)

    def test_single_column_two_panels_not_bumped(self):
        fig, _ = self._plot("single", 50, ncols=2)
        self.assertEqual(self.house.save_house(fig, self.tmp / "two" / "figure", preview=False)["bump"], 0)


@unittest.skipUnless(shutil.which("Rscript"), "Rscript not installed")
class RHouseTheme(unittest.TestCase):
    def test_r_theme(self):
        probe = subprocess.run(
            ["Rscript", "-e", "quit(status = !requireNamespace('ggplot2', quietly = TRUE))"],
            capture_output=True,
        )
        if probe.returncode != 0:
            self.skipTest("ggplot2 not installed")
        out = subprocess.run(
            ["Rscript", "tests/test_theme_house.R"], cwd=ROOT, capture_output=True, text=True
        )
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)


if __name__ == "__main__":
    unittest.main()
