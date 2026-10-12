"""geo / chrom12 palettes: length, exact values from FINAL STYLE.md ("附加配色"), R == Python.
Run: python3 -m unittest discover tests"""
from __future__ import annotations

import importlib.util
import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Verbatim from FINAL STYLE.md, section "附加配色" (2026-10-12).
GEO = "#c5c838 #eaa944 #e17d52 #b93234 #3e9349 #2c69a6".split()
CHROM_LIGHT = "#a3c7da #accc8a #e49698 #ecba73 #c4b1d1 #efe89c".split()
CHROM_DARK = "#2072aa #339a39 #d02623 #e17927 #623f88 #ab5a29".split()
# chrom12 order: light/dark pairs interleaved, like RColorBrewer "Paired".
CHROM12 = [c for pair in zip(CHROM_LIGHT, CHROM_DARK) for c in pair]


def load_house():
    spec = importlib.util.spec_from_file_location("house", ROOT / "styles" / "python" / "house.py")
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    try:
        spec.loader.exec_module(module)
    except ImportError as exc:  # matplotlib missing
        raise unittest.SkipTest(f"house.py needs {exc.name}") from exc
    return module


class PythonPaletteTest(unittest.TestCase):
    def setUp(self) -> None:
        self.h = load_house()

    def test_geo(self) -> None:
        self.assertEqual(len(self.h.pv_palette("geo")), 6)
        self.assertEqual(self.h.pv_palette("geo"), GEO)
        self.assertEqual(len(self.h.pv_palette("geo", 9)), 9)  # gradient ramps

    def test_chrom12(self) -> None:
        self.assertEqual(len(self.h.pv_palette("chrom12")), 12)
        self.assertEqual(self.h.pv_palette("chrom12"), CHROM12)
        self.assertEqual(self.h.pv_palette("chrom12")[0::2], CHROM_LIGHT)
        self.assertEqual(self.h.pv_palette("chrom12")[1::2], CHROM_DARK)
        with self.assertRaises(ValueError):
            self.h.pv_palette("chrom12", 13)

    def test_old_palettes_unchanged(self) -> None:
        self.assertEqual(self.h.pv_palette("house", 3), ["#1F72AE", "#F77E12", "#119B76"])
        self.assertEqual(self.h.pv_palette("house_div")[4], "#F7F7F7")
        self.assertEqual(len(self.h.pv_palette("house_warm")), 5)

class ContractTest(unittest.TestCase):
    def test_contract_lists_the_same_hex(self) -> None:
        text = (ROOT / "styles" / "style-contract.md").read_text(encoding="utf-8")
        sec = text[text.index("<!-- palettes:geo-chrom12 -->"):text.index("<!-- /palettes:geo-chrom12 -->")]
        found = [h.lower() for h in re.findall(r"#[0-9a-fA-F]{6}", sec)]
        for hexv in GEO + CHROM12:
            self.assertIn(hexv, found)


@unittest.skipUnless(shutil.which("Rscript"), "Rscript not installed")
class RMatchesPythonTest(unittest.TestCase):
    def test_r_equals_python(self) -> None:
        code = (
            'source("styles/r/theme_viz.R"); '
            'cat(paste0("{\\"geo\\":[", paste0("\\"", unname(pv_palette("geo")), "\\"", collapse = ","), '
            '"],\\"chrom12\\":[", paste0("\\"", unname(pv_palette("chrom12")), "\\"", collapse = ","), "]}"))'
        )
        out = subprocess.run(["Rscript", "-e", code], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(out.returncode, 0, out.stderr)
        r = json.loads(out.stdout.strip().splitlines()[-1])
        self.assertEqual(r["geo"], GEO)
        self.assertEqual(r["chrom12"], CHROM12)
        h = load_house()
        self.assertEqual(r["geo"], h.pv_palette("geo"))
        self.assertEqual(r["chrom12"], h.pv_palette("chrom12"))


if __name__ == "__main__":
    unittest.main()
