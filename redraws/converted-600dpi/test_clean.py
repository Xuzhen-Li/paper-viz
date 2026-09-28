"""The redraw should be a handful of shapes and real text, not a trace."""

import unittest

from build_clean import build_svg

TINY_PNG = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
    b"\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDAT\x08\xd7c\xf8\xff\xff?"
    b"\x00\x05\xfe\x02\xfe\xdc\xccY\xe7\x00\x00\x00\x00IEND\xaeB`\x82"
)

LABELS = [
    "INPUT",
    "PROCESSING",
    "ANALYSIS",
    "REPORT",
    "FASTQ",
    "BAM",
    "Trim",
    "MAP",
    "Markdup",
    "bcftools",
    "SNP calling",
    "GrapeAncestry",
    "target sites",
    "PE: fastp",
    "AdapterRemoval",
    "VS-1",
    "Relatedness",
    "ADMIXTURE",
    "Damage pattern",
    "GWAS / Selection",
    "Site annotation",
    "Reference data (used in analysis)",
    "descriptors",
]


class CleanFigureTest(unittest.TestCase):
    def test_labels_are_text_and_the_file_is_not_a_trace(self):
        svg = build_svg(TINY_PNG)
        self.assertLess(svg.count("<path"), 80)
        self.assertGreater(svg.count("<text"), 30)
        for label in LABELS:
            self.assertIn(f">{label}</text>", svg)
        self.assertIn('id="step-trim"', svg)
        self.assertIn('id="report-view"', svg)
        self.assertNotIn("transform=\"translate(184", svg)


if __name__ == "__main__":
    unittest.main()
