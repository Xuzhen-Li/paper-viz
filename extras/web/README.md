---
title: "HTML export — static vs interactive"
tags: [visualization, html, plotly]
created: 2026-08-10
updated: 2026-08-10
status: seedling
audience: personal
source_quality: A
---

# HTML export

## English Summary
Two lanes: **static-embed** (PNG/SVG → single self-contained HTML, stdlib) vs **interactive** (Plotly CDN). Escalate to D3 (`../web/d3/`) when you need custom force/chord/treemap layouts.

## When which
| Need | Path |
|------|------|
| Share a publication PNG in email/slide HTML | `static-embed/` |
| Hover / zoom scatter or Manhattan | `interactive/` |
| Custom network / chord / hierarchy | `../web/d3/` |
| Full dashboard / Three.js | `../web/scientific-visualization-templates.md` |

## Commands
```bash
# static: embed one or more image paths
python3 static-embed/build_report.py out.html fig1.png --title "Report"

# interactive (needs plotly)
python3 interactive/plotly_scatter.py
python3 interactive/plotly_manhattan.py
```

Sources: [Plotly write_html](https://plotly.com/python/interactive-html-export/); D3: https://d3js.org
