"""CLI tests for tools/find_figure.py. Run: python3 -m unittest discover tests"""
from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "find_figure.py"
CATALOG = ROOT / "catalog.json"


def load_finder():
    spec = importlib.util.spec_from_file_location("find_figure", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


def figures() -> list[dict]:
    return json.loads(CATALOG.read_text(encoding="utf-8"))["figures"]


class TestFindFigure(unittest.TestCase):
    def test_rank_tiers(self) -> None:
        mod = load_finder()
        exact = {
            "slug": "volcano",
            "title": "Volcano plot",
            "title_zh": "火山图",
            "tags": ["volcano"],
            "when_to_use": "",
            "customize": "",
            "data_columns": {},
        }
        title_hit = {
            "slug": "foo",
            "title": "Volcano extra",
            "title_zh": "其他",
            "tags": [],
            "when_to_use": "",
            "customize": "",
            "data_columns": {},
        }
        body_hit = {
            "slug": "bar",
            "title": "Bar",
            "title_zh": "条",
            "tags": ["other"],
            "when_to_use": "use a volcano here",
            "customize": "",
            "data_columns": {},
        }
        self.assertEqual(mod.match_rank(exact, "volcano"), 0)
        self.assertEqual(mod.match_rank(exact, "火山图"), 0)
        self.assertEqual(mod.match_rank(title_hit, "volcano"), 1)
        self.assertEqual(mod.match_rank(body_hit, "volcano"), 2)
        self.assertLess(mod.match_rank(exact, "volcano"), mod.match_rank(title_hit, "volcano"))
        self.assertLess(mod.match_rank(title_hit, "volcano"), mod.match_rank(body_hit, "volcano"))
        self.assertIsNone(mod.match_rank(body_hit, "missing-xyz"))

    def test_volcano_ranks_first(self) -> None:
        proc = run("volcano")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertTrue(proc.stdout.startswith("slug: volcano\n"), proc.stdout)
        self.assertIn("title: Volcano plot / 火山图", proc.stdout)
        self.assertIn(
            "run: cd figures/differential-expression/volcano && Rscript plot.R",
            proc.stdout,
        )
        self.assertIn(
            "https://raw.githubusercontent.com/Xuzhen-Li/paper-viz/main/figures/differential-expression/volcano/plot.R",
            proc.stdout,
        )
        self.assertIn("https://xuzhen-li.github.io/paper-viz/#volcano", proc.stdout)
        proc_json = run("volcano", "--json")
        rows = json.loads(proc_json.stdout)
        self.assertEqual(rows[0]["slug"], "volcano")

    def test_chinese_query_returns_volcano(self) -> None:
        proc = run("差异基因")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("slug: volcano", proc.stdout)
        rows = json.loads(run("差异基因", "--json").stdout)
        self.assertIn("volcano", [row["slug"] for row in rows])

    def test_category_filter(self) -> None:
        proc = run("--category", "population-genetics", "--limit", "1000", "--json")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        rows = json.loads(proc.stdout)
        expected = sorted(
            fig["slug"] for fig in figures() if fig["category"] == "population-genetics"
        )
        self.assertEqual([row["slug"] for row in rows], expected)
        self.assertTrue(expected)
        self.assertTrue(all(row["category"] == "population-genetics" for row in rows))
        self.assertNotIn("volcano", [row["slug"] for row in rows])

    def test_column_filter(self) -> None:
        proc = run("--column", "pvalue", "--limit", "1000", "--json")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        rows = json.loads(proc.stdout)
        expected = sorted(
            fig["slug"]
            for fig in figures()
            if "pvalue" in {str(key).casefold() for key in fig["data_columns"]}
        )
        self.assertEqual([row["slug"] for row in rows], expected)
        self.assertIn("volcano", expected)
        self.assertNotIn("forest", expected)
        self.assertTrue(all("pvalue" in row["data_columns"] for row in rows))

    def test_no_match_exits_1(self) -> None:
        proc = run("zzz-no-such-figure-9f3a")
        self.assertEqual(proc.returncode, 1)
        self.assertEqual(proc.stdout, "")
        self.assertIn("no matches", proc.stderr)

    def test_json_parses(self) -> None:
        proc = run("--slug", "volcano", "--json")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        rows = json.loads(proc.stdout)
        self.assertEqual(len(rows), 1)
        row = rows[0]
        self.assertEqual(row["slug"], "volcano")
        self.assertEqual(row["gallery"], "https://xuzhen-li.github.io/paper-viz/#volcano")
        self.assertIn("Rscript plot.R", row["run"])
        self.assertEqual(
            [item["name"] for item in row["downloads"]],
            ["plot.R", "data.csv", "make_data.R"],
        )
        for item in row["downloads"]:
            self.assertTrue(
                item["raw"].startswith("https://raw.githubusercontent.com/Xuzhen-Li/paper-viz/main/")
            )
        self.assertIn("gene", row["data_columns"])

    def test_variants_and_drawio(self) -> None:
        main_row = json.loads(run("--slug", "pca-biplot", "--json").stdout)[0]
        self.assertGreaterEqual(len(main_row["variants"]), 2)
        self.assertIsNone(main_row["variant_of"])
        self.assertIn("variants:", run("--slug", "pca-biplot").stdout)

        variant = json.loads(run("--slug", "pcoa", "--json").stdout)[0]
        self.assertEqual(variant["variant_of"], "pca-biplot")
        self.assertEqual(variant["variants"], [])
        self.assertIn("variant_of: pca-biplot", run("--slug", "pcoa").stdout)

        schematic = json.loads(run("--slug", "rnaseq-stages", "--json").stdout)[0]
        self.assertEqual(
            schematic["run"],
            "cd figures/schematic/rnaseq-stages && open template.drawio",
        )
        self.assertIn("template.drawio", [item["name"] for item in schematic["downloads"]])

    def test_default_limit_is_five(self) -> None:
        rows = json.loads(run("--category", "comparison", "--json").stdout)
        self.assertEqual(len(rows), 5)
        self.assertTrue(all(row["category"] == "comparison" for row in rows))


if __name__ == "__main__":
    unittest.main()
