#!/usr/bin/env python3
"""Find a paper-viz figure in catalog.json.

Usage:
  python3 tools/find_figure.py volcano
  python3 tools/find_figure.py 差异基因
  python3 tools/find_figure.py --category population-genetics
  python3 tools/find_figure.py --column pvalue
  python3 tools/find_figure.py --slug volcano --json

Reads catalog.json at the repository root (stdlib only). Rank: exact slug or
title, then title or tags, then when_to_use / customize / data_columns.
Prints the top matches (default 5). Exit code 1 when nothing matches.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "catalog.json"
GALLERY = "https://xuzhen-li.github.io/paper-viz"
RAW = "https://raw.githubusercontent.com/Xuzhen-Li/paper-viz/main"

DOWNLOADS = {
    "R": ("plot.R", "data.csv", "make_data.R"),
    "Python": ("plot.py", "data.csv", "make_data.py"),
    "drawio": ("template.drawio", "figure.svg"),
}
RUN = {
    "R": "Rscript plot.R",
    "Python": "python3 plot.py",
    "drawio": "open template.drawio",
}


def load_figures(path: Path = CATALOG) -> list[dict]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"missing {path.name}") from None
    except json.JSONDecodeError as exc:
        raise SystemExit(f"{path.name}: {exc}") from None
    figures = data.get("figures") if isinstance(data, dict) else None
    if not isinstance(figures, list):
        raise SystemExit(f"{path.name}: expected an object with a figures list")
    return figures


def _fold(value: object) -> str:
    return str(value or "").casefold()


def match_rank(fig: dict, query: str) -> int | None:
    """0 exact slug/title, 1 title/tags/slug, 2 prose or columns. None if no hit.

    An empty query is not a match. Callers that filter without a keyword skip this.
    """
    q = query.casefold().strip()
    if not q:
        return None
    slug = _fold(fig.get("slug"))
    title = _fold(fig.get("title"))
    title_zh = _fold(fig.get("title_zh"))
    if q in {slug, title, title_zh}:
        return 0
    tags = [_fold(tag) for tag in fig.get("tags") or []]
    if q in title or q in title_zh or q in slug or any(q in tag for tag in tags):
        return 1
    columns = fig.get("data_columns") or {}
    blob = "\n".join(
        [
            _fold(fig.get("when_to_use")),
            _fold(fig.get("customize")),
            " ".join(_fold(key) for key in columns),
            " ".join(_fold(value) for value in columns.values()),
        ]
    )
    if q in blob:
        return 2
    return None


def passes_filters(fig: dict, *, category: str, column: str, slug: str) -> bool:
    if slug and _fold(fig.get("slug")) != slug.casefold():
        return False
    if category and _fold(fig.get("category")) != category.casefold():
        return False
    if column:
        keys = {_fold(key) for key in (fig.get("data_columns") or {})}
        if column.casefold() not in keys:
            return False
    return True


def search(
    figures: list[dict],
    query: str = "",
    *,
    category: str = "",
    column: str = "",
    slug: str = "",
    limit: int = 5,
) -> list[dict]:
    query = query.strip()
    if not query and not category and not column and not slug:
        return []
    hits: list[tuple[int, str, dict]] = []
    for fig in figures:
        if not passes_filters(fig, category=category, column=column, slug=slug):
            continue
        rank = 0 if not query else match_rank(fig, query)
        if rank is None:
            continue
        hits.append((rank, str(fig.get("slug") or ""), fig))
    hits.sort(key=lambda item: (item[0], item[1]))
    if limit < 0:
        limit = 0
    return [fig for _rank, _slug, fig in hits[:limit]]


def _downloads(fig: dict) -> list[dict]:
    names = DOWNLOADS.get(str(fig.get("lang")), DOWNLOADS["R"])
    by_name = {item.get("name"): item for item in fig.get("downloads") or []}
    found = []
    directory = str(fig.get("dir") or "").strip("/")
    for name in names:
        item = by_name.get(name) or {}
        raw = item.get("raw")
        if not raw and directory:
            raw = f"{RAW}/{directory}/{name}"
            if not item:
                continue
        if raw:
            found.append({"name": name, "raw": raw})
    return found


def _variants(fig: dict) -> list[dict]:
    rows = []
    for item in fig.get("variants") or []:
        rows.append(
            {
                "slug": item.get("slug"),
                "variant_label": item.get("variant_label"),
                "title": item.get("title"),
                "title_zh": item.get("title_zh"),
            }
        )
    return rows


def project(fig: dict) -> dict:
    lang = str(fig.get("lang") or "R")
    directory = str(fig.get("dir") or "")
    command = RUN.get(lang, RUN["R"])
    variant_of = fig.get("variant_of") or None
    return {
        "slug": fig.get("slug"),
        "title": fig.get("title"),
        "title_zh": fig.get("title_zh"),
        "path": directory,
        "category": fig.get("category"),
        "lang": lang,
        "variants": _variants(fig),
        "variant_of": variant_of,
        "data_columns": {str(k): str(v) for k, v in dict(fig.get("data_columns") or {}).items()},
        "run": f"cd {directory} && {command}",
        "downloads": _downloads(fig),
        "gallery": f"{GALLERY}/#{fig.get('slug')}",
    }


def relation_line(row: dict) -> str:
    variants = row.get("variants") or []
    if variants:
        parts = []
        for item in variants:
            label = item.get("variant_label")
            slug = item.get("slug")
            parts.append(f"{slug} ({label})" if label else str(slug))
        return "variants: " + ", ".join(parts)
    if row.get("variant_of"):
        return f"variant_of: {row['variant_of']}"
    return "variants: none"


def format_text(rows: list[dict]) -> str:
    blocks = []
    for row in rows:
        lines = [
            f"slug: {row['slug']}",
            f"title: {row['title']} / {row['title_zh']}",
            f"path: {row['path']}",
            relation_line(row),
        ]
        columns = row["data_columns"]
        if columns:
            lines.append("columns:")
            for key, desc in columns.items():
                lines.append(f"  {key}: {desc}")
        else:
            lines.append("columns: none")
        lines.append(f"run: {row['run']}")
        if row["downloads"]:
            lines.append("raw:")
            for item in row["downloads"]:
                lines.append(f"  {item['name']}: {item['raw']}")
        lines.append(f"gallery: {row['gallery']}")
        blocks.append("\n".join(lines))
    if not blocks:
        return ""
    return "\n\n".join(blocks) + "\n"


def format_json(rows: list[dict]) -> str:
    return json.dumps(rows, ensure_ascii=False, indent=2) + "\n"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Find a paper-viz figure in catalog.json.",
        epilog=(
            "examples:\n"
            "  python3 tools/find_figure.py volcano\n"
            "  python3 tools/find_figure.py 差异基因\n"
            "  python3 tools/find_figure.py --category population-genetics\n"
            "  python3 tools/find_figure.py --column pvalue\n"
            "  python3 tools/find_figure.py --slug volcano --json"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("query", nargs="*", help="keyword matched against slug, titles, tags, prose, and columns")
    parser.add_argument("--category", default="", help="keep this category only")
    parser.add_argument("--column", default="", help="keep figures that declare this data column")
    parser.add_argument("--slug", default="", help="keep this slug only")
    parser.add_argument("--limit", type=int, default=5, help="maximum hits (default 5)")
    parser.add_argument("--json", action="store_true", dest="as_json", help="print a JSON list")
    return parser


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    args = build_parser().parse_args(argv)
    query = " ".join(args.query).strip()
    figures = search(
        load_figures(),
        query,
        category=args.category.strip(),
        column=args.column.strip(),
        slug=args.slug.strip(),
        limit=args.limit,
    )
    if not figures:
        print("no matches", file=sys.stderr)
        return 1
    rows = [project(fig) for fig in figures]
    sys.stdout.write(format_json(rows) if args.as_json else format_text(rows))
    return 0


if __name__ == "__main__":
    sys.exit(main())
