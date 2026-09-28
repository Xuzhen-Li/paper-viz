"""Trace a flat two-color picture and check the editable SVG still paints it."""

import tempfile
import unittest
from pathlib import Path

import cairosvg
import vtracer
from PIL import Image

from simplify import simplify_svg


class PipelineTest(unittest.TestCase):
    def test_flat_rectangle_survives_trace_and_simplify(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            png = folder / "in.png"
            raw = folder / "raw.svg"
            rendered = folder / "out.png"
            image = Image.new("RGB", (80, 60), (255, 255, 255))
            for y in range(15, 45):
                for x in range(20, 60):
                    image.putpixel((x, y), (200, 30, 40))
            image.save(png)
            vtracer.convert_image_to_svg_py(
                str(png),
                str(raw),
                colormode="color",
                hierarchical="stacked",
                mode="spline",
                filter_speckle=1,
                color_precision=8,
                layer_difference=8,
                path_precision=2,
            )
            raw_text = raw.read_text(encoding="utf-8")
            simplified = simplify_svg(raw_text, eps=0.6)
            self.assertEqual(simplified.count("<path"), raw_text.count("<path"))
            self.assertGreater(simplified.count("<path"), 0)
            self.assertNotIn("transform=", simplified)
            cairosvg.svg2png(
                bytestring=simplified.encode(),
                write_to=str(rendered),
                output_width=80,
            )
            out = Image.open(rendered).convert("RGB")
            self.assertEqual(out.size, (80, 60))
            red = out.getpixel((40, 30))
            white = out.getpixel((2, 2))
            self.assertGreater(red[0], 170)
            self.assertLess(red[1], 60)
            self.assertGreater(white[0], 240)
            self.assertGreater(white[1], 240)


if __name__ == "__main__":
    unittest.main()
