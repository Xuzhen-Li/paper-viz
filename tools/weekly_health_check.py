#!/usr/bin/env python3
"""Weekly gallery/catalog health check for paper-viz (CI).

Exit 0 on pass. Exit 1 on fail and print a machine-readable JSON report on stderr
plus a human Chinese summary on stdout suitable for a GitHub Issue body.
"""
from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GALLERY = os.environ.get(
    "PAPER_VIZ_GALLERY_BASE", "https://xuzhen-li.github.io/paper-viz"
).rstrip("/")
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
ABS_PATH_RE = re.compile(
    r"(?:/Users/|/home/(?!runner\b)|[A-Za-z]:\\|/Volumes/|\\\\[A-Za-z])"
)
# Text fields scanned for blocklist / absolute paths. `reference` is exempt for brands.
TEXT_FIELDS = (
    "title",
    "title_zh",
    "when_to_use",
    "customize",
    "code_text",
    "slug",
    "dir",
    "code",
    "data",
)


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_blocklist() -> list[str]:
    path = ROOT / "tools" / "blocklist.txt"
    words = []
    for line in path.read_text(encoding="utf-8").splitlines():
        w = line.strip()
        if w and not w.startswith("#"):
            words.append(w)
    return words


def http_ok(url: str, timeout: float = 20.0) -> tuple[bool, str]:
    req = urllib.request.Request(url, method="GET", headers={"User-Agent": "paper-viz-weekly-health"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            code = getattr(resp, "status", None) or resp.getcode()
            if code != 200:
                return False, f"HTTP {code}"
            # Ensure image-ish content for preview URLs
            ctype = (resp.headers.get("Content-Type") or "").lower()
            if url.endswith(".png") and "image" not in ctype and "octet-stream" not in ctype:
                return False, f"unexpected Content-Type {ctype!r}"
            return True, "200"
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}"
    except Exception as e:  # noqa: BLE001
        return False, f"{type(e).__name__}: {e}"


def main() -> int:
    errors: list[dict] = []
    notes: list[str] = []

    cat_root = ROOT / "catalog.json"
    cat_docs = ROOT / "docs" / "catalog.json"
    readme = ROOT / "README.md"
    previews_dir = ROOT / "docs" / "previews"

    if not cat_root.is_file():
        errors.append({"kind": "missing", "detail": "缺少 catalog.json", "url": None})
    if not cat_docs.is_file():
        errors.append({"kind": "missing", "detail": "缺少 docs/catalog.json", "url": None})
    if not readme.is_file():
        errors.append({"kind": "missing", "detail": "缺少 README.md", "url": None})
    if errors:
        return emit(errors, notes, 0)

    root = load_json(cat_root)
    docs = load_json(cat_docs)
    figs_root = root.get("figures")
    figs_docs = docs.get("figures")
    if not isinstance(figs_root, list) or not isinstance(figs_docs, list):
        errors.append({"kind": "catalog", "detail": "catalog figures 必须是数组", "url": None})
        return emit(errors, notes, 0)

    n = len(figs_root)
    if len(figs_docs) != n:
        errors.append(
            {
                "kind": "catalog_count",
                "detail": f"根 catalog 与 docs/catalog 数量不一致：root={n} docs={len(figs_docs)}",
                "url": f"{GALLERY}/",
            }
        )

    # Prefer root catalog length as source of truth
    py_n = sum(1 for f in figs_root if f.get("lang") == "Python")
    if py_n != 0:
        errors.append(
            {
                "kind": "lang",
                "detail": f"语言不一致：Python 应为 0，实际 {py_n}",
                "url": f"{GALLERY}/",
            }
        )

    cats = {f.get("category") for f in figs_root}
    missing_cats = sorted(CATEGORIES - cats)
    extra_cats = sorted(cats - CATEGORIES)
    if len(cats & CATEGORIES) != 15 or missing_cats or extra_cats:
        errors.append(
            {
                "kind": "categories",
                "detail": (
                    f"分类应为 15 类齐全；现有 {len(cats & CATEGORIES)} 类。"
                    f" 缺={missing_cats or '无'} 多={extra_cats or '无'}"
                ),
                "url": f"{GALLERY}/",
            }
        )

    # README count line inside CATALOG markers
    text = readme.read_text(encoding="utf-8")
    start, end = "<!-- CATALOG:START -->", "<!-- CATALOG:END -->"
    if start not in text or end not in text:
        errors.append({"kind": "readme", "detail": "README 缺少 CATALOG 标记", "url": None})
    else:
        block = text.split(start, 1)[1].split(end, 1)[0]
        m = re.search(r"共\s+(\d+)\s+张", block)
        if not m:
            errors.append({"kind": "readme", "detail": "README 目录块缺少「共 N 张」", "url": None})
        else:
            readme_n = int(m.group(1))
            if readme_n != n:
                errors.append(
                    {
                        "kind": "readme_count",
                        "detail": f"README「共 {readme_n} 张」与 catalog figures 长度 {n} 不一致",
                        "url": f"{GALLERY}/",
                    }
                )

    # Gallery home must be up
    ok, why = http_ok(f"{GALLERY}/")
    if not ok:
        errors.append(
            {
                "kind": "gallery_home",
                "detail": f"画廊首页不可用：{why}",
                "url": f"{GALLERY}/",
            }
        )
    else:
        notes.append(f"画廊首页 OK：{GALLERY}/")

    # docs/previews png count
    if not previews_dir.is_dir():
        errors.append({"kind": "previews", "detail": "缺少 docs/previews/", "url": None})
        pngs = []
    else:
        pngs = sorted(p.name for p in previews_dir.glob("*.png"))
    if len(pngs) != n:
        errors.append(
            {
                "kind": "previews_count",
                "detail": f"docs/previews png 数={len(pngs)}，catalog figures 长度={n}",
                "url": f"{GALLERY}/",
            }
        )

    blocklist = load_blocklist()
    # docs_preview → gallery HTTP 200
    for fig in figs_root:
        slug = fig.get("slug")
        rel = fig.get("docs_preview")
        if not rel:
            errors.append(
                {
                    "kind": "docs_preview",
                    "detail": f"缺 docs_preview：slug={slug}",
                    "url": None,
                }
            )
            continue
        url = f"{GALLERY}/{rel.lstrip('/')}"
        ok, why = http_ok(url)
        if not ok:
            errors.append(
                {
                    "kind": "preview_http",
                    "detail": f"预览图失败 slug={slug}：{why}",
                    "url": url,
                }
            )

        # copy checks
        for field in TEXT_FIELDS:
            val = fig.get(field)
            if val is None:
                continue
            s = val if isinstance(val, str) else json.dumps(val, ensure_ascii=False)
            if ABS_PATH_RE.search(s):
                errors.append(
                    {
                        "kind": "abspath",
                        "detail": f"文案含本机绝对路径：slug={slug} field={field}",
                        "url": url,
                    }
                )
            for word in blocklist:
                if word and word in s:
                    errors.append(
                        {
                            "kind": "blocklist",
                            "detail": f"文案命中 blocklist「{word}」：slug={slug} field={field}",
                            "url": url,
                        }
                    )
        # reference field: still scan absolute paths, skip blocklist brands
        ref = fig.get("reference")
        if isinstance(ref, str) and ABS_PATH_RE.search(ref):
            errors.append(
                {
                    "kind": "abspath",
                    "detail": f"reference 含本机绝对路径：slug={slug}",
                    "url": url,
                }
            )

    return emit(errors, notes, n)


def emit(errors: list[dict], notes: list[str], n: int) -> int:
    report = {"ok": not errors, "figure_count": n, "errors": errors, "notes": notes}
    # Always write JSON for the workflow step
    out = Path(os.environ.get("GITHUB_WORKSPACE", "/tmp")) / "weekly-health-report.json"
    try:
        out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    except OSError:
        pass
    print(json.dumps(report, ensure_ascii=False), file=sys.stderr)

    if not errors:
        print(f"weekly health OK：catalog={n} gallery={GALLERY}/")
        return 0

    # Chinese issue body
    lines = [
        "## paper-viz 每周巡检失败",
        "",
        f"- 画廊：{GALLERY}/",
        f"- catalog figures 长度：{n}",
        f"- 失败项：{len(errors)}",
        "",
        "### 问题列表",
        "",
    ]
    for i, e in enumerate(errors, 1):
        url = e.get("url") or "(无)"
        lines.append(f"{i}. **{e['kind']}**：{e['detail']}")
        lines.append(f"   - 网址：{url}")
    lines.append("")
    lines.append("由 `.github/workflows/weekly-gallery-health.yml` 自动开 issue。")
    print("\n".join(lines))
    # Title hint for the workflow (first line marker)
    kinds = sorted({e["kind"] for e in errors})
    print(f"ISSUE_TITLE::每周巡检失败：{ '、'.join(kinds) }（共 {len(errors)} 项）")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
