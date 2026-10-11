"""Tests for the README badge step of tools/build_catalog.py. Run: python3 -m unittest discover tests"""
from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "build_catalog.py"


def load_builder():
    spec = importlib.util.spec_from_file_location("build_catalog", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class RewriteBadgeTest(unittest.TestCase):
    def setUp(self) -> None:
        self.mod = load_builder()
        self.tmp = tempfile.TemporaryDirectory()
        self.readme = Path(self.tmp.name) / "README.md"

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_badge_present_is_replaced(self) -> None:
        self.readme.write_text(
            "# x\n![figures](https://img.shields.io/badge/figures-12-blue)\n", encoding="utf-8")
        self.assertTrue(self.mod.rewrite_badge(115, self.readme))
        self.assertIn("badge/figures-115-blue", self.readme.read_text(encoding="utf-8"))

    def test_no_badge_is_skipped(self) -> None:
        text = "# x\nNo badge here.\n"
        self.readme.write_text(text, encoding="utf-8")
        self.assertFalse(self.mod.rewrite_badge(115, self.readme))
        self.assertEqual(self.readme.read_text(encoding="utf-8"), text)


if __name__ == "__main__":
    unittest.main()
