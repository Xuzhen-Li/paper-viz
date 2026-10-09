"""House style smoke tests (R + Python). Run: python3 -m unittest discover tests

Python: theme loads, exported PNG is mm / 25.4 * 600 px, PDF page is mm / 25.4 * 72 pt,
PDF text is TrueType (not outlined), grid cells -> mm (43 mm cell, 3 mm gap, 1 mm page margin
only on 4-cell sides) and off-grid sizes raise, only a single 2x2 panel gets +2 pt once, last
PNG row is white, legacy style.PALETTES is unchanged. R: runs tests/test_theme_house.R when Rscript + ggplot2 exist.
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

    def _plot(self, cells, ncols=1):
        h = self.house
        fig, axes = h.house_figure(cells=cells, ncols=ncols)
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

    def test_grid_conversion(self):
        h = self.house
        self.assertEqual([h.grid_span(n) for n in range(1, 5)], [43, 89, 135, 181])
        self.assertEqual([h.grid_canvas(n) for n in range(1, 5)], [43, 89, 135, 183])
        self.assertEqual(h.house_cells("2x1"), (2, 1))
        self.assertEqual(h.house_cells((3, 4)), (3, 4))
        self.assertEqual(h.house_cells(" 4 X 2 "), (4, 2))
        self.assertEqual(h.house_cells("1\u00d71"), (1, 1))
        g = h.house_canvas("4x1")
        self.assertEqual((g["width_mm"], g["height_mm"], g["content_width_mm"]), (183, 43, 181))
        self.assertEqual((g["margin_x_mm"], g["margin_y_mm"]), (1, 0))
        g = h.house_canvas((4, 4))
        self.assertEqual((g["width_mm"], g["height_mm"], g["margin_y_mm"]), (183, 183, 1))
        self.assertEqual(h.house_canvas((2, 2))["margin_x_mm"], 0)
        for row in ([1, 1, 1, 1], [1, 1, 2], [2, 2], [1, 3], [4]):
            total = 2 * h.PAGE_MARGIN_MM + sum(h.grid_span(n) for n in row) + h.GAP_MM * (len(row) - 1)
            self.assertAlmostEqual(total, 183, msg=f"row {row}")
        # old presets / grid mm convert
        fig, _ = h.house_figure("double")
        self.assertEqual(fig._pv_cells, (4, 1))
        fig, _ = h.house_figure(135, height_mm=89)
        self.assertEqual(fig._pv_cells, (3, 2))

    def test_off_grid_raises(self):
        h = self.house
        for bad in ((5, 1), (0, 1), (1.5, 1), "2x", (1, 2, 3), "5x1", 3):
            with self.assertRaises(ValueError, msg=repr(bad)):
                h.house_cells(bad)
        with self.assertRaises(ValueError):
            h.house_figure("single", height_mm=76)
        with self.assertRaises(ValueError):
            h.house_figure(181, height_mm=43)
        with self.assertRaises(ValueError):
            h.house_figure("single", cells="2x1")
        import matplotlib.pyplot as plt

        fig = plt.figure(figsize=(100 * self.house.MM, 43 * self.house.MM))
        with self.assertRaises(ValueError):
            h.save_house(fig, self.tmp / "offgrid" / "figure", preview=False)
        # a bare figure already on the grid is accepted
        fig = plt.figure(figsize=(89 * self.house.MM, 43 * self.house.MM))
        fig.add_subplot().plot([0, 1])
        self.assertEqual(h.save_house(fig, self.tmp / "ongrid" / "figure", preview=False)["cells"], (2, 1))

    def test_non_finite_raises_value_error(self):
        # R stop() -> ValueError; never OverflowError / a raw float() message
        h = self.house
        nan, inf = float("nan"), float("inf")
        for bad in ((nan, 1), (inf, 1), (1, -inf), (None, 1), ("a", 1)):
            with self.assertRaisesRegex(ValueError, "off the house grid", msg=repr(bad)):
                h.house_cells(bad)
        for kw in ({"width": nan}, {"width": inf}, {"width": "single", "height_mm": nan},
                   {"width": "single", "height_mm": -inf}):
            with self.assertRaisesRegex(ValueError, "not a finite size in mm", msg=repr(kw)):
                h.house_figure(**kw)
        import matplotlib.pyplot as plt

        fig = plt.figure()
        with self.assertRaises(ValueError):
            h.save_house(fig, self.tmp / "nf" / "figure", cells=(inf, 1), preview=False)

    def test_single_column_single_panel(self):
        fig, (ax,) = self._plot((2, 2))
        res = self.house.save_house(fig, self.tmp / "single" / "figure")
        self.assertEqual(res["bump"], 2)
        self.assertEqual(ax.xaxis.get_ticklabels()[0].get_fontsize(), 9)
        self.assertEqual(ax.xaxis.label.get_fontsize(), 10)
        self._check_export(res, 89, 89)
        # saving again must not bump twice
        self.assertEqual(self.house.save_house(fig, self.tmp / "single" / "again", preview=False)["bump"], 0)

    def test_only_2x2_is_bumped(self):
        for cells in ("2x1", "1x1", "1x2", "3x3"):
            fig, _ = self._plot(cells)
            res = self.house.save_house(fig, self.tmp / f"nb{cells}" / "figure", preview=False)
            self.assertEqual(res["bump"], 0, cells)

    def test_double_column(self):
        fig, axes = self._plot("4x1", ncols=3)
        res = self.house.save_house(fig, self.tmp / "double" / "figure")
        self.assertEqual(res["bump"], 0)
        self.assertEqual(axes[0].xaxis.label.get_fontsize(), 8)
        self._check_export(res, 183, 43)
        # 1 mm page margin left and right: nothing drawn there
        import numpy as np
        from PIL import Image

        a = np.asarray(Image.open(res["png"]).convert("L"))
        px_mm = 600 / 25.4
        edge = int(px_mm)  # first / last 1 mm
        self.assertTrue((a[:, :edge] > 250).all() and (a[:, -edge:] > 250).all())

    def test_last_png_row_white(self):
        import numpy as np
        from PIL import Image

        for cells in ("1x1", "2x1", "2x2", "4x1"):
            fig, (ax,) = self._plot(cells)
            ax.set_xlabel("Berry weight (g, log scale)")
            res = self.house.save_house(fig, self.tmp / f"bottom{cells}" / "figure", preview=False)
            a = np.asarray(Image.open(res["png"]).convert("RGB"))
            self.assertTrue((a[-1] > 250).all(), f"{cells}: last pixel row not white")

    def test_point_size_matches_r(self):
        h = self.house
        d_pt, edge_pt = h.ggplot_point_pt(2.3, 0.3)
        self.assertAlmostEqual(h.POINT["markersize"], d_pt)
        self.assertAlmostEqual(h.SCATTER["s"], d_pt**2)
        self.assertAlmostEqual((d_pt + edge_pt) / 72 * 25.4, 2.04, delta=0.02)
        if not shutil.which("Rscript"):
            self.skipTest("Rscript not installed")
        # Render one point in each language at 2540 dpi (100 px/mm) and compare outer diameters.
        import matplotlib.pyplot as plt
        import numpy as np
        from PIL import Image

        r_png = self.tmp / "point_r.png"
        code = (
            "suppressMessages(source('styles/r/theme_house.R')); library(ggplot2);"
            "p <- ggplot(data.frame(x = 0, y = 0), aes(x, y)) +"
            " geom_point(shape = 21, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke, fill = 'red') + theme_void();"
            f"ggsave('{r_png}', p, width = 20, height = 20, units = 'mm', dpi = 2540, bg = 'white')"
        )
        out = subprocess.run(["Rscript", "-e", code], cwd=ROOT, capture_output=True, text=True)
        if out.returncode != 0:
            self.skipTest("R point render failed: " + out.stderr[-300:])
        py_png = self.tmp / "point_py.png"
        fig = plt.figure(figsize=(20 / 25.4, 20 / 25.4))
        ax = fig.add_axes([0, 0, 1, 1])
        ax.axis("off")
        ax.scatter([0], [0], c="red", **h.SCATTER)
        fig.savefig(py_png, dpi=2540, facecolor="white", bbox_inches=None)
        plt.close(fig)

        def width_mm(path):
            a = np.asarray(Image.open(path).convert("L")) < 250
            xs = np.where(a.any(axis=0))[0]
            return (xs.max() - xs.min() + 1) / 100

        self.assertAlmostEqual(width_mm(r_png), width_mm(py_png), delta=0.05)

    def test_single_column_two_panels_not_bumped(self):
        fig, _ = self._plot("2x2", ncols=2)
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
