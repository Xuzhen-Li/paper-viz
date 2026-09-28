"""Geometry checks for the vectorizer-style path cleanup."""

import unittest

from simplify import parse_path, simplify_path_d, simplify_svg


def _kinds(d: str) -> list[str]:
    return [cmd[0] for sub in parse_path(d) for cmd in sub]


class SimplifyPathTest(unittest.TestCase):
    def test_straight_cubic_becomes_a_line_and_bakes_translate(self):
        d = simplify_path_d("M0 0 C3 0 7 0 10 0 Z", tx=5, ty=7, eps=0.6)
        self.assertEqual(d, "M5 7 L15 7 Z")

    def test_curved_cubic_is_preserved(self):
        d = simplify_path_d("M0 0 C0 20 10 20 10 0 Z", eps=0.6)
        self.assertIn("C", d)
        self.assertTrue(d.startswith("M0 0 "))
        self.assertTrue(d.endswith("Z"))

    def test_colinear_line_run_collapses_to_endpoints(self):
        d = simplify_path_d(
            "M0 0 C3 0 7 0 10 0 C13 0.1 17 0 20 0 Z",
            eps=0.6,
        )
        self.assertEqual(d, "M0 0 L20 0 Z")

    def test_square_corners_survive(self):
        d = simplify_path_d(
            "M0 0 C5 0 10 0 20 0 "
            "C20 5 20 10 20 20 "
            "C15 20 10 20 0 20 "
            "C0 15 0 10 0 0 Z",
            eps=0.6,
        )
        self.assertEqual(d, "M0 0 L20 0 L20 20 L0 20 Z")
        self.assertNotIn("C", d)

    def test_multiple_subpaths_stay_separate(self):
        d = simplify_path_d("M0 0 C2 0 4 0 6 0 Z M10 10 C12 10 14 10 16 10 Z", eps=0.6)
        self.assertEqual(d.count("M"), 2)
        self.assertEqual(d.count("Z"), 2)
        self.assertIn("M10 10", d)

    def test_svg_keeps_paint_order_and_drops_translate(self):
        svg = """<svg xmlns="http://www.w3.org/2000/svg" width="30" height="20">
<path d="M0 0 C3 0 6 0 10 0 C10 2 10 4 10 8 C8 8 4 8 0 8 Z" fill="#112233" transform="translate(4,5)"/>
<path d="M0 0 C0 12 16 12 8 0 Z" fill="#abcdef" transform="translate(1,1)"/>
</svg>
"""
        out = simplify_svg(svg, eps=0.6)
        self.assertEqual(out.count("<path"), 2)
        self.assertNotIn("transform=", out)
        self.assertLess(out.index("#112233"), out.index("#ABCDEF"))
        first, second = parse_path(
            out.split('d="')[1].split('"')[0]
        ), parse_path(out.split('d="')[2].split('"')[0])
        self.assertEqual(first[0][0], ("M", 4.0, 5.0))
        self.assertIn("L", _kinds(out.split('d="')[1].split('"')[0]))
        self.assertIn("C", _kinds(out.split('d="')[2].split('"')[0]))
        self.assertEqual(second[0][0][0], "M")


if __name__ == "__main__":
    unittest.main()
