#!/usr/bin/env python3
"""Embed image files as base64 into a self-contained HTML report (stdlib only)."""
from __future__ import annotations

import argparse
import base64
import mimetypes
from pathlib import Path

TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<title>{title}</title>
<style>
  body {{ font-family: Helvetica, Arial, sans-serif; margin: 2rem; color: #222; }}
  h1 {{ font-size: 1.4rem; }}
  figure {{ margin: 1.5rem 0; }}
  img {{ max-width: 100%; height: auto; border: 1px solid #ddd; }}
  figcaption {{ font-size: 0.85rem; color: #666; margin-top: 0.4rem; }}
</style>
</head>
<body>
<h1>{title}</h1>
{figures}
</body>
</html>
"""


def img_tag(path: Path) -> str:
    mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    b64 = base64.b64encode(path.read_bytes()).decode("ascii")
    return (
        f'<figure><img src="data:{mime};base64,{b64}" alt="{path.name}"/>'
        f"<figcaption>{path.name}</figcaption></figure>"
    )


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("out_html", type=Path)
    p.add_argument("images", nargs="+", type=Path)
    p.add_argument("--title", default="Figure report")
    args = p.parse_args()
    figs = "\n".join(img_tag(i) for i in args.images)
    args.out_html.write_text(
        TEMPLATE.format(title=args.title, figures=figs), encoding="utf-8"
    )
    print(f"wrote {args.out_html.resolve()}")


if __name__ == "__main__":
    main()
