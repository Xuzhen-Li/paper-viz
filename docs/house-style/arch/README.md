# 可编辑示意图示例 / Editable schematic example

中文：这是 house style 示意图做法的示例，内容是自拟的通用流程：基因型和环境数据经编码器、融合和预测头，预测植物表型并做交叉验证评估。版面、文字、公式和小插图都由 Python 脚本写成 SVG；图标是 AI 生成的位图，嵌入 SVG，同时在隐藏图层里放了一份简化的矢量版。只作为文档示例，不进图库目录（catalog），也不计入图数。

- 依赖：Python ≥ 3.10，`pip install -r requirements.txt`（numpy、matplotlib、Pillow）。另需字体 Arial 或 Liberation Sans（二者字宽一致；Linux 可装 `fonts-liberation`），以及导出 PNG 用的 `rsvg-convert`（librsvg，Debian/Ubuntu 包名 `librsvg2-bin`）。公式用 matplotlib 自带的 STIX 字体。
- 重建：`python3 docs/house-style/arch/build_v3.py`（任意目录下都可运行）。它会覆盖本目录的 `arch_v3.svg` 和 `arch_v3.png`（2000 px 宽），并打印字号和线宽检查（按 183 mm 宽印刷换算成 pt）。有文字出框、文字互相重叠或任何字小于 6 pt 时，以非零状态退出。脚本不联网、不调用外部服务，图标只读 `icons/` 里已入库的文件。
- 文件：
  - `build_v3.py`：入口和检查；
  - `helpers.py`：画布尺寸、命名色板 `PAL`、命名线宽 `LW`、字号 `FS` 和绘图函数；
  - `body.py`：版面坐标和文字；
  - `icons/`：四个 AI 生成图标，即数据库、火焰、雪花、仪表，分别用于基因型数据、高温、低温和评估精度。
- 隐藏图层：SVG 里有两个默认隐藏的图层。
  - `vector-icon-fallback`：图标的矢量版，和位图图标位置重合。
  - `math-text-fallback`：公式的纯文字版。每个公式路径的 `data-tex` 里存着 LaTeX 源码。
- 切换到矢量图标：
  - 在编辑器的图层面板里打开 `vector-icon-fallback`，并隐藏 class 为 `icon-bitmap` 的位图；或者手动把该组的 `visibility="hidden"` 改为 `visible`，再给位图加 `display:none`。
  - 也可以运行 `python3 docs/house-style/arch/build_v3.py --vector-icons /path/to/check.svg`，它会另外写出一份已切换好的检查用 SVG 和同名 PNG，不会覆盖入库文件。

English: This is the worked example of the house-style schematic method. Its content is a made-up generic pipeline: genotype and environment data pass through encoders, fusion and a prediction head to predict plant phenotypes, followed by cross-validated evaluation. The layout, text, formulas and small insets are written to SVG by a Python script. The icons are AI-generated bitmaps embedded in the SVG, with simplified vector versions kept in a hidden layer. It is a documentation example only: it is not in the catalog and does not count towards the figure total.

- Requirements: Python 3.10 or later and `pip install -r requirements.txt` (numpy, matplotlib, Pillow). You also need the Arial or Liberation Sans font (the two have the same widths; on Linux, `fonts-liberation`), and `rsvg-convert` (librsvg; the Debian/Ubuntu package is `librsvg2-bin`) for the PNG. Formulas use the STIX fonts bundled with matplotlib.
- Rebuild: `python3 docs/house-style/arch/build_v3.py` (from any directory). It overwrites `arch_v3.svg` and `arch_v3.png` (2000 px wide) in this folder and prints the font-size and line-width check, converted to pt for a 183 mm print width. It exits non-zero if any text leaves its box, overlaps other text, or is smaller than 6 pt. The script makes no network calls and uses no external service; icons are read only from the committed `icons/` folder.
- Files:
  - `build_v3.py`: the entry point and the check;
  - `helpers.py`: canvas size, the named palette `PAL`, named line widths `LW`, font sizes `FS` and the drawing functions;
  - `body.py`: layout coordinates and labels;
  - `icons/`: the four AI-generated icons, database, flame, snowflake and gauge, used for genotype data, heat, frost and accuracy.
- Hidden layers: the SVG has two layers that are hidden by default.
  - `vector-icon-fallback`: vector versions of the icons, placed exactly over the bitmaps.
  - `math-text-fallback`: the formulas as plain text. Each formula path also keeps its LaTeX source in `data-tex`.
- To switch to the vector icons:
  - In an editor's layers panel, show `vector-icon-fallback` and hide the bitmaps (class `icon-bitmap`). Or, by hand, change that group's `visibility="hidden"` to `visible` and give the bitmaps `display:none`.
  - Or run `python3 docs/house-style/arch/build_v3.py --vector-icons /path/to/check.svg`, which writes a switched copy and a PNG of the same name for checking, without touching the committed files.
