# 可编辑架构示意图示例 / Editable architecture schematic example

中文：这是 house style 示意图做法的示例：版面、文字、公式和小插图都由 Python 脚本写成 SVG，图标是 AI 生成的位图，嵌入 SVG，同时在隐藏图层里保留一份矢量备份。这里只作为文档示例，不进图库目录（catalog），也不计入图数。

- 依赖：Python ≥ 3.10、`numpy`、`matplotlib`（公式转路径，用自带的 STIX 字体）、`Pillow`；字体 Roboto Condensed（Google Fonts，OFL 许可），脚本用它量上下标宽度，看图时也需要装上；导出 PNG 需要 `rsvg-convert`（librsvg），没有它时只重建 SVG。
- 重建：`python3 docs/house-style/arch/build_v3.py`（任意目录下都可运行），会覆盖本目录的 `arch_v3.svg` 和 `arch_v3.png`（2000 px 宽）。脚本不联网、不调用任何外部服务，图标只读 `icons/` 里已入库的文件。
- 文件：`build_v3.py` 是入口，`helpers.py` 放绘图函数，`body.py` 放版面坐标和文字，`icons/` 放四个 AI 生成图标（数据库、火焰、仪表、雪花）。
- SVG 里 `vector-icon-fallback` 和 `math-text-fallback` 两个图层默认隐藏：前者是图标的矢量版本，后者是公式的纯文字版本，需要时在编辑器里打开即可。

English: This is the worked example of the house-style schematic method. The layout, text, formulas and small insets are written to SVG by a Python script; the icons are AI-generated bitmaps embedded in the SVG, with vector copies kept in a hidden layer. It is a documentation example only: it is not in the catalog and does not count towards the figure total.

- Requirements: Python 3.10 or later, `numpy`, `matplotlib` (formulas to paths, with its bundled STIX fonts) and `Pillow`; the Roboto Condensed font (Google Fonts, OFL), which the script uses to measure sub- and superscripts and which viewers also need; `rsvg-convert` (librsvg) for the PNG. Without it only the SVG is rebuilt.
- Rebuild: `python3 docs/house-style/arch/build_v3.py` (from any directory). It overwrites `arch_v3.svg` and `arch_v3.png` (2000 px wide) in this folder. The script makes no network calls and uses no external service; icons are read only from the committed `icons/` folder.
- Files: `build_v3.py` is the entry point, `helpers.py` holds the drawing functions, `body.py` holds the layout coordinates and labels, and `icons/` holds the four AI-generated icons (database, flame, gauge, snowflake).
- The SVG has two hidden layers, `vector-icon-fallback` (vector versions of the icons) and `math-text-fallback` (formulas as plain text). Turn them on in an editor when needed.
