"""Editable labels sit on the original figure, inside the boxes they replace."""

import unittest

import numpy as np
from PIL import Image, ImageFont

from build_aligned import FONT_PATH, build_svg, place_text, select_labels


class SelectLabelsTest(unittest.TestCase):
    def test_merges_headers_and_drops_fragments(self):
        raw = [
            {"x0": 988, "y0": 136, "x1": 1461, "y1": 216, "text": "PROCESSIL", "score": 0.91},
            {"x0": 1270, "y0": 136, "x1": 1565, "y1": 215, "text": "ESSING", "score": 0.98},
            {"x0": 1267, "y0": 1680, "x1": 1364, "y1": 1755, "text": "CF", "score": 1.0},
            {"x0": 436, "y0": 1809, "x1": 465, "y1": 1846, "text": "c", "score": 0.68},
            {"x0": 2127, "y0": 2054, "x1": 2401, "y1": 2090, "text": "PCA/ ADMIXTURE", "score": 0.98},
            {"x0": 927, "y0": 510, "x1": 966, "y1": 536, "text": "9", "score": 0.66},
            {"x0": 1101, "y0": 441, "x1": 1247, "y1": 514, "text": "Trim", "score": 1.0},
        ]
        labels = {item["text"]: item for item in select_labels(raw)}
        self.assertIn("PROCESSING", labels)
        self.assertNotIn("PROCESSIL", labels)
        self.assertNotIn("ESSING", labels)
        self.assertEqual(labels["VCF"]["x0"], 1227)
        self.assertEqual(labels["C"]["text"], "C")
        self.assertIn("PCA/ADMIXTURE", labels)
        self.assertNotIn("9", labels)
        self.assertIn("Trim", labels)


class PlaceTextTest(unittest.TestCase):
    def test_descenders_stay_inside_the_box(self):
        box_w, box_h = 180, 59
        size, dx, dy = place_text("fastp", box_w, box_h)
        left, top, right, bottom = ImageFont.truetype(FONT_PATH, size).getbbox("fastp")
        self.assertGreaterEqual(dx + left, -0.01)
        self.assertGreaterEqual(dy + top, -0.01)
        self.assertLessEqual(dx + right, box_w + 0.01)
        self.assertLessEqual(dy + bottom, box_h + 0.01)


class BuildSvgTest(unittest.TestCase):
    def test_one_image_and_real_text(self):
        page = Image.fromarray(np.full((40, 160, 3), 255, dtype=np.uint8))
        labels = [{"x0": 8, "y0": 4, "x1": 140, "y1": 36, "text": "Trim", "score": 1.0}]
        svg = build_svg(page, labels)
        self.assertEqual(svg.count("<image"), 1)
        self.assertEqual(svg.count("<text"), 1)
        self.assertIn(">Trim</text>", svg)
        self.assertIn('font-family="Noto Sans"', svg)
        self.assertIn("@font-face", svg)
        self.assertNotIn("<path", svg)
        self.assertIn('width="160"', svg)


if __name__ == "__main__":
    unittest.main()
