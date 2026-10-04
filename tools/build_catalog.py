#!/usr/bin/env python3
"""Scan figures/**/meta.yaml and write catalog.json, docs/catalog.json, README block.

Gallery extras (still keeps the required meta keys):
- variant_of / variant_label on each figure, and variants on each main entry
- task derived from category (heatmap shares 相关/关系 with correlation)
- parameters: top-of-file plot.R assignments before the analysis starts
- canvas: width_mm / height_mm from the last pv_save (or save_base) call
"""
from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIGURES = ROOT / "figures"
README = ROOT / "README.md"
DOCS = ROOT / "docs"
PREVIEWS = DOCS / "previews"
GITHUB = "https://github.com/Xuzhen-Li/paper-viz/blob/main"
RAW = "https://raw.githubusercontent.com/Xuzhen-Li/paper-viz/main"
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
# Task list is the gallery filter. heatmap has no task of its own; those
# matrices sit with correlation under 相关/关系.
CATEGORY_TASK = {
    "comparison": "compare",
    "distribution": "distribution",
    "correlation": "relationship",
    "heatmap": "relationship",
    "composition": "composition",
    "differential-expression": "de",
    "enrichment": "enrichment",
    "dimension-reduction": "ordination",
    "genome": "genome",
    "population-genetics": "popgen",
    "phylogeny": "phylogeny",
    "network": "network",
    "clinical": "clinical",
    "microbiome-ecology": "microbiome",
    "schematic": "schematic",
}
TASKS = (
    ("compare", "比较组", "Compare groups"),
    ("distribution", "分布", "Distribution"),
    ("relationship", "相关/关系", "Relationship"),
    ("composition", "组成", "Composition"),
    ("de", "差异表达", "Differential expression"),
    ("enrichment", "富集", "Enrichment"),
    ("ordination", "降维", "Dimension reduction"),
    ("genome", "基因组", "Genome"),
    ("popgen", "群体遗传", "Population genetics"),
    ("phylogeny", "系统发育", "Phylogeny"),
    ("network", "网络", "Network"),
    ("clinical", "临床", "Clinical"),
    ("microbiome", "微生物/生态", "Microbiome & ecology"),
    ("schematic", "流程图", "Schematic"),
)
TASK_LABELS = {task_id: (zh, en) for task_id, zh, en in TASKS}
# Audit A merges. Main slug first, then variant chips in this order.
VARIANT_ORDER = {
    "pca-biplot": ("pca-biplot", "pcoa", "nmds"),
    "cleveland-dot": ("cleveland-dot", "dumbbell"),
    "pie": ("pie", "donut"),
    "raincloud": ("raincloud", "violin", "beeswarm", "grouped-boxplot-signif"),
    "bar-grouped": ("bar-grouped", "circular-bar"),
    "parallel-coordinates": ("parallel-coordinates", "radar"),
    "enrichment-dot": ("enrichment-dot", "enrichment-bar"),
    "heatmap": ("heatmap", "circular-heatmap"),
    "selection-scan": ("selection-scan", "window-scan"),
    "project-phases": ("project-phases", "rnaseq-stages"),
    "multiomics-parallel": (
        "multiomics-parallel",
        "assembly-compare",
        "variant-modules",
        "case-control-arms",
    ),
}
PREAMBLE_RE = re.compile(
    r"^(source|library|require|suppressPackageStartupMessages|suppressMessages)\s*\("
)
ASSIGN_RE = re.compile(
    r"^([A-Za-z.][A-Za-z0-9._]*)\s*(<-|<<-|=(?!=))\s*([\s\S]*)$"
)
DATA_LOAD_RE = re.compile(
    r"(^|[^\w.])((utils|data\.table|readr)::)?(read\.csv|read\.csv2|read\.table|read\.delim|read_csv|fread)\s*\("
)
SAVE_FNS = {"pv_save", "save_base"}
# Assignments to these names are the script body, not knobs at the top.
STOP_LHS = {"df", "d", "dat", "data", "p", "p_plot", "wide", "long", "mat"}


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
        if value in ("", "{}"):
            data[key] = {}
        elif value == "[]":
            data[key] = []
        else:
            data[key] = _unquote(value)
    return data


def _opt_str(meta: dict, key: str) -> str | None:
    value = meta.get(key)
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def task_of(category: str) -> str:
    try:
        return CATEGORY_TASK[category]
    except KeyError as exc:
        raise SystemExit(f"no task for category {category}") from exc


def code_rel(fig_dir: Path, meta: dict) -> str:
    if meta["lang"] == "drawio":
        name = "template.drawio"
    elif meta["lang"] == "R" or (fig_dir / "plot.R").exists():
        name = "plot.R" if (fig_dir / "plot.R").exists() else "plot.py"
    else:
        name = "plot.py"
    return str((fig_dir / name).relative_to(ROOT)).replace("\\", "/")


def _collapse(value: str) -> str:
    text = re.sub(r"\s+", " ", value).strip()
    if len(text) > 300:
        return text[:297] + "..."
    return text


def statements(code: str) -> list[str]:
    """Split R source into statements. Comments and strings are respected."""
    out: list[str] = []
    buf: list[str] = []
    depth = 0
    quote = None
    i = 0
    n = len(code)
    while i < n:
        c = code[i]
        if quote:
            buf.append(c)
            if c == "\\":
                if i + 1 < n:
                    buf.append(code[i + 1])
                    i += 2
                    continue
            elif c == quote:
                quote = None
            i += 1
            continue
        if c in "\"'":
            quote = c
            buf.append(c)
            i += 1
            continue
        if c == "#":
            while i < n and code[i] != "\n":
                i += 1
            continue
        if c in "([{":
            depth += 1
            buf.append(c)
            i += 1
            continue
        if c in ")]}":
            depth = max(0, depth - 1)
            buf.append(c)
            i += 1
            continue
        if c in "\n;" and depth == 0:
            stmt = "".join(buf).strip()
            if stmt:
                out.append(stmt)
            buf = []
            i += 1
            continue
        buf.append(c)
        i += 1
    tail = "".join(buf).strip()
    if tail:
        out.append(tail)
    return out


def _is_knob(stmt: str) -> tuple[str, str] | None:
    """Return (name, value) for a top-of-file knob, or None to stop the block."""
    if PREAMBLE_RE.match(stmt):
        return ("", "")
    match = ASSIGN_RE.match(stmt)
    if not match:
        return None
    name, _op, value = match.group(1), match.group(2), match.group(3).strip()
    if name in {".", "..."} or name in STOP_LHS:
        return None
    if re.match(r"^function\s*\(", value):
        return None
    if DATA_LOAD_RE.search(value) or "ggplot" in value or "pv_save" in value:
        return None
    return name, _collapse(value)


def parse_parameters(code: str) -> list[dict]:
    """Assignment lines at the top of plot.R.

    Blank lines and comments are ignored. source() / library() preamble is
    skipped so the knobs after the style include are visible. The block ends
    at the first statement that is not one of those assignments (including
    read.csv and the ggplot object).
    """
    params: list[dict] = []
    for stmt in statements(code):
        knob = _is_knob(stmt)
        if knob is None:
            break
        name, value = knob
        if not name:
            continue
        params.append({"name": name, "value": value})
    return params


def _read_balanced(code: str, i: int) -> tuple[str, int]:
    """code[i] is '('. Return the inside and the index after the close."""
    i += 1
    start = i
    depth = 1
    quote = None
    n = len(code)
    while i < n:
        c = code[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = None
            i += 1
            continue
        if c in "\"'":
            quote = c
            i += 1
            continue
        if c == "#":
            nl = code.find("\n", i)
            i = n if nl < 0 else nl
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return code[start:i], i + 1
        i += 1
    return code[start:], n


def _find_calls(code: str, names: set[str]) -> list[str]:
    found: list[str] = []
    i = 0
    n = len(code)
    quote = None
    while i < n:
        c = code[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = None
            i += 1
            continue
        if c in "\"'":
            quote = c
            i += 1
            continue
        if c == "#":
            nl = code.find("\n", i)
            i = n if nl < 0 else nl + 1
            continue
        if c.isalpha() or c in "._":
            j = i + 1
            while j < n and (code[j].isalnum() or code[j] in "._"):
                j += 1
            name = code[i:j]
            k = j
            while k < n and code[k] in " \t\r\n":
                k += 1
            if name in names and k < n and code[k] == "(":
                args, end = _read_balanced(code, k)
                found.append(args)
                i = end
                continue
            i = j
            continue
        i += 1
    return found


def _split_args(args: str) -> list[str]:
    parts: list[str] = []
    buf: list[str] = []
    depth = 0
    quote = None
    i = 0
    while i < len(args):
        c = args[i]
        if quote:
            buf.append(c)
            if c == "\\":
                if i + 1 < len(args):
                    buf.append(args[i + 1])
                    i += 2
                    continue
            elif c == quote:
                quote = None
            i += 1
            continue
        if c in "\"'":
            quote = c
            buf.append(c)
            i += 1
            continue
        if c == "#":
            while i < len(args) and args[i] != "\n":
                i += 1
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth = max(0, depth - 1)
        if c == "," and depth == 0:
            parts.append("".join(buf).strip())
            buf = []
            i += 1
            continue
        buf.append(c)
        i += 1
    tail = "".join(buf).strip()
    if tail:
        parts.append(tail)
    return parts


def _named_arg(args: str, name: str) -> str | None:
    prefix = name + "="
    for part in _split_args(args):
        compact = re.sub(r"\s+", "", part[: len(name) + 8])
        if compact.startswith(prefix) or re.match(rf"^{name}\s*=", part):
            value = re.split(r"=", part, maxsplit=1)[1]
            return _collapse(value)
    return None


def _numeric_mm(value: str | None) -> bool:
    return bool(value) and bool(re.fullmatch(r"\d+(?:\.\d+)?", value or ""))


def parse_canvas(code: str) -> dict | None:
    """Last pv_save or save_base call that sets width_mm / height_mm."""
    calls = _find_calls(code, SAVE_FNS)
    width = height = None
    for args in calls:
        got_w = _named_arg(args, "width_mm")
        got_h = _named_arg(args, "height_mm")
        if got_w is None and got_h is None:
            continue
        width, height = got_w, got_h
    if width is None and height is None:
        return None
    if _numeric_mm(width) and _numeric_mm(height):
        label = f"{width} × {height} mm"
    else:
        label = f"{width or '?'} × {height or '?'} mm"
    return {"width_mm": width, "height_mm": height, "label": label}


def search_text(row: dict) -> str:
    columns: list[str] = []
    for key, value in row["data_columns"].items():
        columns.append(str(key))
        columns.append(str(value))
    parts = [
        row["title"],
        row["title_zh"],
        row["slug"],
        row.get("variant_label") or "",
        row["category"],
        CATEGORY_ZH.get(row["category"], ""),
        row["task"],
        row["task_zh"],
        row["task_en"],
        row["when_to_use"],
        row["customize"],
        " ".join(str(tag) for tag in row["tags"]),
        " ".join(columns),
    ]
    return "\n".join(parts).lower()


def downloads_for(fig_dir: Path, rel_dir: str, lang: str) -> list[dict]:
    if lang == "drawio":
        names = ["template.drawio", "figure.svg"]
    else:
        names = ["plot.R", "plot.py", "data.csv", "make_data.R", "make_data.py"]
        for path in sorted(fig_dir.glob("data*.csv")):
            if path.name not in names:
                names.append(path.name)
    found = []
    for name in names:
        if (fig_dir / name).exists():
            rel = f"{rel_dir}/{name}"
            found.append(
                {
                    "name": name,
                    "path": rel,
                    "raw": f"{RAW}/{rel}",
                    "github": f"{GITHUB}/{rel}",
                }
            )
    return found


def _script_meta(code_text: str, rel_code: str) -> tuple[list[dict], dict | None]:
    if not rel_code.endswith(".R"):
        return [], None
    try:
        return parse_parameters(code_text), parse_canvas(code_text)
    except Exception as exc:  # a sibling worker may be mid-write
        print(f"warn parse {rel_code}: {exc}", file=sys.stderr)
        return [], None


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
        task_id = task_of(str(meta["category"]))
        task_zh, task_en = TASK_LABELS[task_id]
        parameters, canvas = _script_meta(code_text, rel_code)
        variant_of = _opt_str(meta, "variant_of")
        if variant_of == slug:
            raise SystemExit(f"{slug}: variant_of cannot point at itself")
        figures.append(
            {
                "title": meta["title"],
                "title_zh": meta["title_zh"],
                "slug": slug,
                "category": meta["category"],
                "tags": [str(tag) for tag in meta["tags"]],
                "packages": list(meta["packages"]),
                "data_columns": {str(k): str(v) for k, v in dict(meta["data_columns"]).items()},
                "when_to_use": meta["when_to_use"],
                "customize": meta["customize"],
                "lang": meta["lang"],
                "task": task_id,
                "task_zh": task_zh,
                "task_en": task_en,
                "variant_of": variant_of,
                "variant_label": _opt_str(meta, "variant_label"),
                "variants": [],
                "parameters": parameters,
                "canvas": canvas,
                "downloads": downloads_for(fig_dir, rel_dir, str(meta["lang"])),
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
    by_slug = {row["slug"]: row for row in figures}
    children: dict[str, list[dict]] = {}
    for row in figures:
        parent = row["variant_of"]
        if not parent:
            continue
        if parent not in by_slug:
            raise SystemExit(f"{row['slug']}: variant_of {parent} does not exist")
        if by_slug[parent]["variant_of"]:
            raise SystemExit(f"{row['slug']}: variant chain via {parent}")
        if not row["variant_label"]:
            raise SystemExit(f"{row['slug']}: missing variant_label")
        children.setdefault(parent, []).append(row)
    for parent, kids in children.items():
        if not by_slug[parent]["variant_label"]:
            raise SystemExit(f"{parent}: main figure missing variant_label")
        order = VARIANT_ORDER.get(parent)
        wanted = set(order) if order else None
        got = {parent} | {kid["slug"] for kid in kids}
        if wanted is not None and got != wanted:
            raise SystemExit(f"{parent}: variants {sorted(got)} != {sorted(wanted)}")
        sequence = list(order) if order else [parent] + sorted(kid["slug"] for kid in kids)
        members = [by_slug[slug] for slug in sequence]
        by_slug[parent]["variants"] = [
            {
                "slug": member["slug"],
                "variant_label": member["variant_label"],
                "title": member["title"],
                "title_zh": member["title_zh"],
                "docs_preview": member["docs_preview"],
            }
            for member in members
        ]
    missing_groups = [slug for slug in VARIANT_ORDER if slug not in children]
    if missing_groups:
        raise SystemExit(f"missing variant groups: {', '.join(missing_groups)}")
    for row in figures:
        row["search_text"] = search_text(row)
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


def self_check() -> None:
    sample = """
# comment
source("../../../styles/r/theme_viz.R")
library(patchwork)

lfc_cut <- 1
p_cut <- 0.01

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$nlp <- -log10(df$pvalue)
"""
    names = [item["name"] for item in parse_parameters(sample)]
    if names != ["lfc_cut", "p_cut"]:
        raise SystemExit(f"param fixture {names}")
    sample_if = """
source("../../../styles/r/theme_viz.R")
view <- "expression"
show_annotation <- TRUE
if (view == "module-trait") {
  pv_save(p, "figure", width_mm = 110, height_mm = 70)
}
pv_save(p, "figure", width_mm = 183, height_mm = 150)
"""
    if [item["name"] for item in parse_parameters(sample_if)] != ["view", "show_annotation"]:
        raise SystemExit("if-block fixture")
    canvas = parse_canvas(sample_if)
    if not canvas or canvas["label"] != "183 × 150 mm":
        raise SystemExit(f"canvas fixture {canvas}")
    expr = 'pv_save(p, "figure", width_mm = if (nlevels(df$method) > 1) 140 else 89, height_mm = 72)\n'
    got = parse_canvas(expr)
    if not got or got["height_mm"] != "72" or "if" not in (got["width_mm"] or ""):
        raise SystemExit(f"expr canvas {got}")
    nested = 'pv_save(p, "figure", width_mm = 183, height_mm = if (layout %in% c("circular", "fan")) 160 else h)\n'
    nested_canvas = parse_canvas(nested)
    if not nested_canvas or nested_canvas["width_mm"] != "183" or "circular" not in (nested_canvas["height_mm"] or ""):
        raise SystemExit(f"nested canvas {nested_canvas}")
    base = "save_base(draw, width_mm = 140, height_mm = 140)\n"
    if parse_canvas(base)["label"] != "140 × 140 mm":
        raise SystemExit("save_base canvas")
    knobs = """
source("x")
stage_levels <- c(
  "Baseline",
  "Week 12"
)
use_arrow <- TRUE
df <- read.csv("data.csv")
p <- ggplot2::ggplot(df)
"""
    knob_names = [item["name"] for item in parse_parameters(knobs)]
    if knob_names != ["stage_levels", "use_arrow"]:
        raise SystemExit(f"multiline knobs {knob_names}")
    if task_of("heatmap") != "relationship" or task_of("comparison") != "compare":
        raise SystemExit("task map")
    if task_of("schematic") != "schematic" or TASK_LABELS["de"][0] != "差异表达":
        raise SystemExit("task labels")
    for plot in FIGURES.glob("*/*/plot.R"):
        text = plot.read_text(encoding="utf-8")
        parse_parameters(text)
        parse_canvas(text)


def assert_catalog(figures: list[dict]) -> None:
    by_slug = {row["slug"]: row for row in figures}
    hits = {row["slug"] for row in figures if "差异基因" in row["search_text"]}
    missing = {"volcano", "ma-plot"} - hits
    if missing:
        raise SystemExit(f"search 差异基因 missing {sorted(missing)}")
    mains = [row for row in figures if not row["variant_of"]]
    children = [row for row in figures if row["variant_of"]]
    if len(mains) + len(children) != len(figures):
        raise SystemExit("card count")
    if len(children) != sum(len(order) - 1 for order in VARIANT_ORDER.values()):
        raise SystemExit(f"expected variant count, got {len(children)}")
    labels = [item["variant_label"] for item in by_slug["pca-biplot"]["variants"]]
    if labels != ["PCA", "PCoA", "NMDS"]:
        raise SystemExit(f"pca chips {labels}")
    if by_slug["pcoa"]["variant_of"] != "pca-biplot":
        raise SystemExit("pcoa parent")
    if by_slug["rnaseq-stages"]["variant_of"] != "project-phases":
        raise SystemExit("rnaseq parent")
    if by_slug["case-control-arms"]["variant_of"] != "multiomics-parallel":
        raise SystemExit("case-control parent")
    volcano = by_slug["volcano"]
    if not isinstance(volcano["parameters"], list):
        raise SystemExit("parameters type")
    if "pv_save" in volcano["code_text"] and not (volcano.get("canvas") or {}).get("width_mm"):
        raise SystemExit("volcano canvas")
    joined = "\n".join(row["search_text"] for row in figures if row["slug"] in {"pca-biplot", "pcoa", "nmds"})
    if "pcoa" not in joined:
        raise SystemExit("variant search text")


def main() -> None:
    self_check()
    figures = build()
    assert_catalog(figures)
    tasks = [{"id": task_id, "zh": zh, "en": en} for task_id, zh, en in TASKS]
    payload = {
        "raw_base": RAW + "/",
        "github_base": GITHUB + "/",
        "tasks": tasks,
        "figures": figures,
    }
    raw = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    (ROOT / "catalog.json").write_text(raw, encoding="utf-8")
    DOCS.mkdir(parents=True, exist_ok=True)
    (DOCS / "catalog.json").write_text(raw, encoding="utf-8")
    rewrite_readme(render_readme(figures))
    cards = sum(1 for row in figures if not row["variant_of"])
    print(f"catalog {len(figures)} figures, {cards} cards")


if __name__ == "__main__":
    main()
