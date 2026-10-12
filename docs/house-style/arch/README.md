# 可编辑示意图示例 / Editable schematic example

中文：这是 house style 示意图做法的示例，内容是自拟的通用流程：基因型和环境数据经编码器、融合和预测头，预测植物表型并做交叉验证评估。版面、文字、公式和小插图由 Python 脚本写成 SVG；图标是 AI 生成的位图，另在隐藏图层里放了矢量备用图标。只作为文档示例，不进图库目录（catalog），也不计入图数。做法、字号线宽等数值和验收标准以 [styles/style-contract.md](../../../styles/style-contract.md#示意图与架构图--schematics-and-architecture-diagrams) 为准，这里不重复。

- 改成自己的图：复制本目录，改 `body.py` 里的坐标和文字、`helpers.PAL`，再跑 `build_v3.py`。
- 依赖：Python ≥ 3.10，`pip install -r requirements.txt`（numpy、matplotlib、Pillow）。另需字体 Arial 或 Liberation Sans（二者字宽一致；Linux 可装 `fonts-liberation`），以及导出 PNG 用的 `rsvg-convert`（Debian/Ubuntu 包名 `librsvg2-bin`）。公式用 matplotlib 自带的 STIX 字体。
- 重建：`python3 docs/house-style/arch/build_v3.py`（任意目录下都可运行）。它会覆盖本目录的 `arch_v3.svg` 和 `arch_v3.png`（2000 px 宽），并打印 contract 里规定的字号、线宽和对齐检查；不达标时以非零状态退出。脚本不联网，图标只读 `icons/` 里已入库的文件。
- 图标检查：重建时只渲染矢量备用图标，逐个和对应位图的不透明区域（alpha > 40）比较中心和宽高：中心偏差 ≤ 2 px，宽、高之比各在 ±5% 以内，否则以非零状态退出。`clean_icons.py` 清除图标透明边距里孤立的近透明杂点（alpha ≤ 16 且 2 px 内没有可见像素），保留抗锯齿边缘；`--check` 只检查。
- 字体与 PNG：入库的 PNG 用真 Arial 渲染。只装了 Liberation Sans 时，重建出的 SVG 和入库版逐字节一致；PNG 版面相同，但字节不同。
- 为什么页面显示 PNG：SVG 的文字依赖本机字体，没有 Arial 或 Liberation Sans 的设备（如部分手机）会换字体，可能出框；SVG 供下载编辑。
- 颜色：只使用命名色板 `PAL` 里的颜色，以及用 `shade()` 从 PAL 派生的明暗色；脚本里不写死其他色号。
- 文件：`build_v3.py`（入口和检查）、`helpers.py`（画布、`PAL`、`LW`、`FS` 和绘图函数）、`body.py`（版面坐标和文字）、`icons/`（四个 AI 生成图标：数据库、火焰、雪花、仪表，分别用于基因型数据、高温、低温和精度）。
- 隐藏图层：`vector-icon-fallback` 是矢量备用图标，按位图不透明区域对齐；`math-text-fallback` 是公式的纯文字版。公式路径的 `data-tex` 存 LaTeX 源码。
- 切换到矢量备用图标：在编辑器图层面板里显示 `vector-icon-fallback`，并隐藏 class 为 `icon-bitmap` 的位图；或运行 `python3 docs/house-style/arch/build_v3.py --vector-icons /path/to/check.svg`，另写一份已切换的 SVG 和 PNG，不覆盖入库文件。
- 标签：图注和 SVG 的 `<desc>` 写 “AI-assisted icons”，并注明图标位置。部分期刊（如 Nature Portfolio）不接受 AI 生成的图像；投稿时切换到矢量备用图标，并去掉该标签。

English: This is the worked example of the house-style schematic method. Its content is a made-up generic pipeline: genotype and environment data pass through encoders, fusion and a prediction head to predict plant phenotypes, followed by cross-validated evaluation. The layout, text, formulas and small insets are written to SVG by a Python script. The icons are AI-generated bitmaps, with vector fallback icons in a hidden layer. It is a documentation example only: it is not in the catalog and does not count towards the figure total. The method, the numbers (font sizes, line widths) and the acceptance criteria are defined in [styles/style-contract.md](../../../styles/style-contract.md#示意图与架构图--schematics-and-architecture-diagrams) and are not repeated here.

- To make your own: copy this folder, change the coordinates and labels in `body.py` and the colours in `helpers.PAL`, then run `build_v3.py`.
- Requirements: Python 3.10 or later and `pip install -r requirements.txt` (numpy, matplotlib, Pillow). You also need the Arial or Liberation Sans font (the two have the same widths; on Linux, `fonts-liberation`), and `rsvg-convert` (Debian/Ubuntu package `librsvg2-bin`) for the PNG. Formulas use the STIX fonts bundled with matplotlib.
- Rebuild: `python3 docs/house-style/arch/build_v3.py` (from any directory). It overwrites `arch_v3.svg` and `arch_v3.png` (2000 px wide) in this folder and prints the font-size, line-width and alignment checks defined in the contract; it exits non-zero if any fails. The script makes no network calls and reads icons only from the committed `icons/` folder.
- Icon check: a rebuild renders only the vector fallback icons and compares each one with the visible (alpha > 40) area of its bitmap: the centre offset must be ≤ 2 px and the width and height ratios each within ±5 %, otherwise it exits non-zero. `clean_icons.py` removes isolated near-transparent specks from the icons' transparent margins (alpha ≤ 16 with no visible pixel within 2 px) and keeps anti-aliased edges; `--check` only reports.
- Fonts and the PNG: the committed PNG was rendered with real Arial. With only Liberation Sans installed, a rebuild gives a byte-identical SVG and a PNG with the same layout but different bytes.
- Why the page shows the PNG: the SVG text depends on installed fonts, and devices without Arial or Liberation Sans (some phones) would substitute a font that may overflow the boxes; the SVG is there to download and edit.
- Colours: the scripts use only colours from the named palette `PAL` and lighter or darker variants derived from it with `shade()`; no other colour values are hard-coded.
- Files: `build_v3.py` (entry point and checks), `helpers.py` (canvas, `PAL`, `LW`, `FS` and drawing functions), `body.py` (layout coordinates and labels), `icons/` (four AI-generated icons, database, flame, snowflake and gauge, used for genotype data, heat, frost and accuracy).
- Hidden layers: `vector-icon-fallback` holds the vector fallback icons, fitted to each bitmap's visible area; `math-text-fallback` holds the formulas as plain text. Each formula path keeps its LaTeX source in `data-tex`.
- To switch to the vector fallback icons: in an editor's layers panel, show `vector-icon-fallback` and hide the bitmaps (class `icon-bitmap`); or run `python3 docs/house-style/arch/build_v3.py --vector-icons /path/to/check.svg`, which writes a switched SVG and PNG without touching the committed files.
- Label: the caption and the SVG `<desc>` say "AI-assisted icons" and where the icons are. Some journals (e.g. Nature Portfolio) do not accept AI-generated images; for submission, switch to the vector icons and drop the label.
