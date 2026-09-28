"""The redraw should use the icon artwork and keep every label as text."""

import unittest

from build_clean import build_svg

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
    "VS-1 genome",
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
        svg = build_svg()
        self.assertLess(svg.count("<path"), 40)
        self.assertGreater(svg.count("<text"), 30)
        self.assertGreater(svg.count("<image"), 10)
        for label in LABELS:
            self.assertIn(f">{label}</text>", svg)
        self.assertIn('id="step-trim"', svg)
        self.assertIn('id="report-view"', svg)
        self.assertNotIn("transform=\"translate(184", svg)


if __name__ == "__main__":
    unittest.main()
