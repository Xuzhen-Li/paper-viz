"""docs/house-style/arch icons: no stray near-transparent pixels, and every vector fallback icon matches
its bitmap's visible box within 5 % in width and height. Run: python3 -m unittest discover tests"""
from __future__ import annotations

import importlib.util
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCH = ROOT / "docs" / "house-style" / "arch"


def load(name: str):
    spec = importlib.util.spec_from_file_location(name, ARCH / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class IconNoiseTest(unittest.TestCase):
    def test_no_stray_pixels(self) -> None:
        try:
            import numpy as np
            from PIL import Image
        except ImportError as exc:
            self.skipTest(f"needs {exc.name}")
        ci = load("clean_icons")
        icons = sorted(ci.ICON_DIR.glob("*.png"))
        self.assertTrue(icons)
        for p in icons:
            with self.subTest(icon=p.name):
                self.assertEqual(int(ci.noise_mask(np.array(Image.open(p).convert("RGBA"))).sum()), 0)


@unittest.skipUnless(shutil.which("rsvg-convert"), "rsvg-convert not installed")
class FallbackSizeTest(unittest.TestCase):
    def test_fallback_within_5_percent(self) -> None:
        sys.path.insert(0, str(ARCH))
        try:
            import numpy as np
            import helpers, body, build_v3  # noqa: E401
        except ImportError as exc:
            self.skipTest(f"needs {exc.name}")
        finally:
            sys.path.remove(str(ARCH))
        helpers.ICONS.clear()
        body.draw(np.random.default_rng(3))
        with tempfile.TemporaryDirectory() as tmp:
            svg = Path(tmp) / "check.svg"
            helpers.finish(svg)                         # temp copy; committed files are not touched
            rows = build_v3.icon_overlap(svg.read_text(), helpers.ICONS)
        self.assertEqual({r[0] for r in rows}, {"database", "flame", "snowflake", "gauge"})
        for name, dx, dy, rw, rh in rows:
            with self.subTest(icon=name):
                self.assertLessEqual(abs(rw - 1), build_v3.SIZE_TOL)
                self.assertLessEqual(abs(rh - 1), build_v3.SIZE_TOL)
                self.assertLessEqual(max(abs(dx), abs(dy)), build_v3.ICON_TOL)


if __name__ == "__main__":
    unittest.main()
