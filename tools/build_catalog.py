#!/usr/bin/env python3
"""Scan figures/**/meta.yaml and write catalog.json, docs/catalog.json, README block."""
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIGURES = ROOT / "figures"
README = ROOT / "README.md"
DOCS = ROOT / "docs"
PREVIEWS = DOCS / "previews"
GITHUB = "https://github.com/Xuzhen-Li/paper-viz/blob/main"
REQUIRED = (
    "title",
    "title_zh",
    "slug",
    "category",
    "tags",
    "packages",
    "data_columns",
    "when_to_use",
    "customize",
    "lang",
)
CATEGORIES = {
    "distribution",
    "comparison",
    "correlation",
    "composition",
    "heatmap",
    "dimension-reduction",
    "differential-expression",
    "enrichment",
    "population-genetics",
    "genome",
    "phylogeny",
    "network",
    "microbiome-ecology",
    "clinical",
    "schematic",
}
START = "<!-- CATALOG:START -->"
END = "<!-- CATALOG:END -->"
CATEGORY_ZH = {
    "distribution": "分布",
    "comparison": "比较",
    "correlation": "相关",
    "composition": "组成",
    "heatmap": "热图",
    "dimension-reduction": "降维",
    "differential-expression": "差异表达",
    "enrichment": "富集",
    "population-genetics": "群体遗传",
    "genome": "基因组",
    "phylogeny": "系统发育",
    "network": "网络",
    "microbiome-ecology": "微生物与生态",
    "clinical": "临床",
    "schematic": "流程图模板",
}
CATEGORY_ORDER = (
    "distribution",
    "comparison",
    "correlation",
    "composition",
    "heatmap",
    "dimension-reduction",
    "differential-expression",
    "enrichment",
    "population-genetics",
    "genome",
    "phylogeny",
    "network",
    "microbiome-ecology",
    "clinical",
    "schematic",
)


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def parse_meta(text: str) -> dict:
    try:
        import yaml  # type: ignore
    except ImportError:
        yaml = None
    if yaml is not None:
        data = yaml.safe_load(text)
        if not isinstance(data, dict):
            raise ValueError("meta.yaml root must be a mapping")
        return data
    return _parse_fallback(text)


def load_meta(path: Path) -> dict:
    data = parse_meta(path.read_text(encoding="utf-8"))
    missing = [k for k in REQUIRED if k not in data]
    if missing:
        raise SystemExit(f"{path}: missing {', '.join(missing)}")
    if data["category"] not in CATEGORIES:
        raise SystemExit(f"{path}: illegal category {data['category']}")
    if data["lang"] not in ("R", "Python", "drawio"):
        raise SystemExit(f"{path}: lang must be R, Python, or drawio")
    if not isinstance(data["tags"], list) or not isinstance(data["packages"], list):
        raise SystemExit(f"{path}: tags and packages must be lists")
    if not isinstance(data["data_columns"], dict):
        raise SystemExit(f"{path}: data_columns must be a mapping")
    return data


def _parse_fallback(text: str) -> dict:
    data: dict = {}
    current = None
    for raw in text.splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if raw.startswith("  - "):
            data.setdefault(current, [])
            if isinstance(data[current], dict):
                data[current] = []
            data[current].append(_unquote(raw[4:]))
            continue
        if raw.startswith("  "):
            key, _, value = raw.strip().partition(":")
            if not isinstance(data.get(current), dict):
                data[current] = {}
            data[current][key.strip()] = _unquote(value)
            continue
        key, _, value = raw.partition(":")
        key = key.strip()
        value = value.strip()
        current = key
        data[key] = {} if value == "" else _unquote(value)
    return data


def code_rel(fig_dir: Path, meta: dict) -> str:
    if meta["lang"] == "drawio":
        name = "template.drawio"
    elif meta["lang"] == "R" or (fig_dir / "plot.R").exists():
        name = "plot.R" if (fig_dir / "plot.R").exists() else "plot.py"
    else:
        name = "plot.py"
    return str((fig_dir / name).relative_to(ROOT)).replace("\\", "/")


def build() -> list[dict]:
    metas = sorted(FIGURES.glob("*/*/meta.yaml"))
    if not metas:
        raise SystemExit("no figures/**/meta.yaml")
    figures = []
    seen = set()
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    for path in metas:
        meta = load_meta(path)
        slug = str(meta["slug"])
        if slug in seen:
            raise SystemExit(f"duplicate slug {slug}")
        seen.add(slug)
        fig_dir = path.parent
        if slug != fig_dir.name:
            raise SystemExit(f"{path}: slug {slug} != directory {fig_dir.name}")
        preview = fig_dir / "preview.png"
        if not preview.exists():
            raise SystemExit(f"missing {preview}")
        if meta["lang"] == "drawio":
            drawio = fig_dir / "template.drawio"
            if not drawio.exists():
                raise SystemExit(f"missing {drawio}")
            rel_data = None
            rel_data_files: list[str] = []
        else:
            data_files = sorted(fig_dir.glob("data*.csv"))
            if not data_files:
                raise SystemExit(f"missing data csv in {fig_dir}")
            rel_data_files = [str(p.relative_to(ROOT)).replace("\\", "/") for p in data_files]
            preferred = fig_dir / "data.csv"
            rel_data = (
                str(preferred.relative_to(ROOT)).replace("\\", "/")
                if preferred.exists()
                else rel_data_files[0]
            )
        rel_preview = str(preview.relative_to(ROOT)).replace("\\", "/")
        rel_code = code_rel(fig_dir, meta)
        rel_dir = str(fig_dir.relative_to(ROOT)).replace("\\", "/")
        code_text = (ROOT / rel_code).read_text(encoding="utf-8")
        shutil.copyfile(preview, PREVIEWS / f"{slug}.png")
        py = fig_dir / "plot.py"
        figures.append(
            {
                "title": meta["title"],
                "title_zh": meta["title_zh"],
                "slug": slug,
                "category": meta["category"],
                "tags": list(meta["tags"]),
                "packages": list(meta["packages"]),
                "data_columns": dict(meta["data_columns"]),
                "when_to_use": meta["when_to_use"],
                "customize": meta["customize"],
                "lang": meta["lang"],
                "dir": rel_dir,
                "preview": rel_preview,
                "docs_preview": f"previews/{slug}.png",
                "code": rel_code,
                "data": rel_data,
                "data_files": rel_data_files,
                "code_python": (
                    str(py.relative_to(ROOT)).replace("\\", "/") if py.exists() and rel_code.endswith(".R") else None
                ),
                "github_code": f"{GITHUB}/{rel_code}",
                "github_data": f"{GITHUB}/{rel_data}" if rel_data else None,
                "github_dir": f"{GITHUB}/{rel_dir}",
                "code_text": code_text,
            }
        )
    figures.sort(key=lambda row: (row["category"], row["slug"]))
    return figures


def render_readme(figures: list[dict]) -> str:
    counts: dict[str, int] = {}
    for row in figures:
        counts[row["category"]] = counts.get(row["category"], 0) + 1
    lines = ["", f"共 {len(figures)} 张。", "", "| 分类 | 中文 | 数量 |", "|------|------|------|"]
    present = [cat for cat in CATEGORY_ORDER if counts.get(cat)]
    for cat in present:
        lines.append(f"| `{cat}` | {CATEGORY_ZH[cat]} | {counts[cat]} |")
    lines.append("")
    for cat in present:
        rows = [row for row in figures if row["category"] == cat]
        lines.append(f"### {CATEGORY_ZH[cat]} `{cat}`（{len(rows)}）")
        lines.append("")
        for row in rows[:4]:
            lines.append(
                f'<img src="{row["preview"]}" width="200" alt="{row["title_zh"]}">'
            )
        lines.append("")
    return "\n".join(lines)


def rewrite_readme(block: str) -> None:
    text = README.read_text(encoding="utf-8")
    if START not in text or END not in text:
        raise SystemExit("README missing CATALOG markers")
    pre, rest = text.split(START, 1)
    _, post = rest.split(END, 1)
    README.write_text(pre + START + "\n" + block + END + post, encoding="utf-8")


def main() -> None:
    figures = build()
    payload = {"figures": figures}
    raw = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    (ROOT / "catalog.json").write_text(raw, encoding="utf-8")
    DOCS.mkdir(parents=True, exist_ok=True)
    (DOCS / "catalog.json").write_text(raw, encoding="utf-8")
    rewrite_readme(render_readme(figures))
    print(f"catalog {len(figures)} figures")


if __name__ == "__main__":
    main()
