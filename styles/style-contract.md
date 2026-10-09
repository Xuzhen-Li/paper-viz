# 期刊终稿规范 / Journal figure contract

> **English Summary:** New figures use the **house style** (`styles/r/theme_house.R`, `styles/python/house.py`): compact, text-dense, little white space. 89 mm single / 183 mm double column, 7 pt ticks, 8 pt plain axis titles, 10 pt bold lowercase panel tags, four-sided 0.5 pt frame, ticks outward 1 mm, no grid, direct labels instead of legends, the nine-colour house palette. A single-column single panel gets +2 pt (9/10 pt). Export cairo PDF (text stays text) plus a 600 dpi PNG. Existing figures keep the legacy `theme_viz()` contract below and are not re-rendered; `theme_viz()`, `pv_save()` and `pv_palette("categorical")` (chip eight) stay available.

## House style（新图默认，2026-10 起）

**新加的图一律用 house style**；已有的图不重渲染，继续按下文“旧版 theme_viz 规范”。一句话：**紧凑、字多、留白少**。

入口：

- R：`source("../../../styles/r/theme_house.R")`（会顺带加载同目录的 `theme_viz.R`），然后 `theme_house()`、`pv_palette("house")`、`pv_save_house()`。
- Python：`import house`（`styles/python/house.py`），然后 `house.apply_house_style()`、`house.house_figure()`、`house.save_house()`。

### 画布

- 宽度预设：单栏 **89 mm**（`width = "single"`），双栏 **183 mm**（`width = "double"`）。高度按内容定，常见单行 55–65 mm；单栏单面板默认 76 mm，双栏默认 118 mm。
- 双栏每行 3 个面板（约 58 mm），单栏每行 2 个；面板间距水平约 3 mm、垂直约 2.5 mm；外边距 ≤1 mm；绘图区 ≥60% 面板面积。
- 字号不随面板缩小。

### 字号（印刷最终尺寸）

| 元素 | 字号 | 字重 |
|---|---|---|
| 刻度标签 | 7 pt | 常规 |
| 轴标题 | 8 pt | **常规，不加粗** |
| 直接数据标签 | 7–8 pt | 常规，关键系列可加粗 |
| 图内统计量（*R*²、*P*、*N*） | 7 pt | 常规，与组同色 |
| 面板字母 | 10 pt | 粗体小写 a b c（patchwork `tag_levels = "a"`） |
| 任何文字最小值 | 6 pt | — |

- **单栏 89 mm 只放 1 个面板时，全部字号 +2 pt**（刻度 9、轴标题 10）。`pv_save_house()` / `save_house()` 在宽 ≤89 mm 且只有一个面板（非 patchwork、无分面 / 只有一个数据轴）时自动加；按当前刻度字号算差值，已经用 `theme_house(base_size = 9)` 的图不会再加一次；`bump = 0` 可关掉。
- `geom_text()` / `annotate()` 的 size 用 `pv_pt2size(pt)`（7 pt = 2.46，8 pt = 2.81，6 pt = 2.11）。

### 字体

Arial → Helvetica → Liberation Sans → DejaVu Sans（按机器上有的取第一个）；中文用思源黑体 / Noto Sans CJK SC。全图一种字体，数学符号用同字体斜体（Python 的 mathtext 也设为同一无衬线字体）。

### 线与点

| 元素 | pt | R |
|---|---|---|
| 边框、刻度线（长 1 mm，向外） | 0.5 | `theme_house()` 已设 |
| 主数据线 | 1.5 | `linewidth = pv_house_lw("main")` |
| 强调线 / 拟合线 | 2.0 | `pv_house_lw("emph")` |
| 次要系列 | 0.8 | `pv_house_lw("minor")` |
| 参考线（虚线） | 0.5 | `pv_house_lw("ref")` |
| 误差棒 | 0.7 | `pv_house_lw("errorbar")` |

- 点：shape 21（实心圆加描边），`size = 2.2–2.6, stroke = 0.3`，描边 `#000000`；≤200 个点不透明。Python 用 `house.SCATTER` / `house.POINT`。
- 置信带同色 alpha 0.2；回归 CI 用灰 `#BFBFBF`。

### 坐标轴与图例

- 四边 0.5 pt 黑框，刻度向外 1 mm，无网格，无次刻度（对数轴除外）。
- 默认**不画图例**（`theme_house()` 的 `legend = "none"`），系列名直接写在图里，文字颜色 = 数据颜色。必须用图例时 `theme_house(legend = "inside")`：框内右上、无边框、键宽 ≤3 mm。
- 分面标题写在框内左上，无灰色 strip 底。

### 色板（house）

| 名字 | 颜色 | 用途 |
|---|---|---|
| `house` | `#1F72AE` `#F77E12` `#119B76` `#CC312C` `#595594` `#62B4E7` `#E6C32A` `#A8127F` `#8A4C38` | 分类，按顺序取，一张图 ≤6 个彩色系列，其余灰 |
| `house_div` | `#1D7CBB` `#4A82B0` `#8EBDDA` `#DEE4F0` `#F7F7F7` `#F6DEDE` `#E19193` `#C4454B` `#CB2223` | 蓝–红发散，0 居中 |
| `ssp` | Historical `#000000`，SSP1-2.6 `#3A9CFE`，SSP2-4.5 `#F79423`，SSP3-7.0 `#FD3B3B`，SSP5-8.5 `#9C2125` | 情景（具名向量 / dict） |
| `house_warm` | `#FBD6A0` `#F5BA7A` `#F38F64` `#CC635F` `#965459` | 暖色顺序（气泡、强度、热图） |
| `house_grey` | `#000000` `#333333` `#6B6B6B` `#757575` `#BFBFBF` `#E0E0E0` `#F0F0F0` | 文字、参考线、CI 带、背景点 |

R 与 Python 同一套：`pv_palette("house")`（R 在 `theme_viz.R` 里，旧名字照旧）、`house.pv_palette("house")`。`house` / `ssp` / `house_grey` 超过色数会报错，不会自动插值。

### 导出

- `pv_save_house(plot, "figure", width = "single" | "double" | mm, height_mm = ...)`：cairo PDF（字体嵌入，文字保留为文本，不转曲）+ 600 dpi PNG + 1200 px 宽 `preview.png`。
- Python `house.save_house(fig, "figure")`：PDF（TrueType，`pdf.fonttype = 42`）+ 600 dpi PNG + `preview.png`；不裁边（不用 `bbox_inches="tight"`），保证 89 / 183 mm 精确。
- 测试：`python3 -m unittest discover tests`（含 `tests/test_house_theme.py`，会调 `Rscript tests/test_theme_house.R`）。

## 旧版 theme_viz 规范（已有图保持，不重渲染）

以下是 house style 之前的约定。已有的图继续按它；`theme_viz()`、`pv_save()`、`pv_palette("categorical")`（chip 八色）等旧接口保留可用。

主图是四边闭合的黑框，白底，默认无网格，图例无框，放在框内空白处，不放在图外侧。分类数据色只用下面固定八色顺序；对照或背景点云用 `#E0E0E0`（不是数据色）。

## 字体与字号

- 字体候选顺序：Helvetica，Arial，DejaVu Sans。
- `theme_viz()` 默认 `base_size = 12`，给仍保持宽画布的图用。轴刻度跟随 `base_size`，轴标题约为 `base_size + 1`。
- **普通单面板**（散点、箱线、柱、火山、密度、生存曲线等）：`pv_save` 宽 85、高 60，并 `theme_viz(base_size = 7)`。刻度 7 pt，轴标题 8 pt。
- **需要正方形的单面板**（QQ、ROC、hexbin）：宽 85、高 85，同样 `theme_viz(base_size = 7)`。
- **不要压成 85 mm** 的图类：环图、曼哈顿、热图、circos，以及多面板或按类别拉高的图（棒棒糖、瀑布、富集条形）。这些保持现有宽高。
- 图例默认在框内右上角。某张图右上角有数据时，改到框内真正的空白处。不要把图例放回图外侧。
- 画廊预览一律 1200 px 宽、白底，不要透明底。
- 分面字母：粗体，略大于轴刻度。

## 线宽与画布

- R：`panel.border` 线宽 0.5；刻度线宽 0.5。四边都画。极坐标图（饼图、环形图等）可关掉 `panel.border`。
- Python：四边 spines 都开，线宽 0.5；不要改回只有左下两条边。
- 无默认网格。图例无框。

## 色板

分类色顺序固定（R `pv_palette("categorical")` 与 Python `PALETTES["categorical"]` / `bio` / `contrast` / `axes.prop_cycle` 同一套，不要两套混在一张图）：

1. `#134aa3`
2. `#f6a3b1`
3. `#0b5475`
4. `#dc1f26`
5. `#835ca6`
6. `#f7922c`
7. `#fbee61`
8. `#981b1e`

- 对照 / 背景点云：`#E0E0E0`（不是分类数据色）。
- 不要再用 `#999999` 或 `#000000` 当分类色。
- `sequential` / `diverging` 不动。
- 不要彩虹色标、ggsci 具名板、公众号 HEX、lieflat 灰阶当默认分类色。
- 热图继续用已有 sequential / diverging。

## 导出

主交付是可编辑矢量，不要只交 PNG。

- SVG：文字保持文本（Python `svg.fonttype = none`）。
- PDF：TrueType（Python `pdf.fonttype = 42`；R 用 cairo PDF）。
- TIFF：600 dpi。
- PNG 只作预览，不代替终稿；不要手交假预览。
