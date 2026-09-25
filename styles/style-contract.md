# 期刊终稿规范 / Journal figure contract

> **English Summary:** Final journal figures use a sans-serif face (Arial, then Helvetica, then DejaVu Sans), 5–7 pt body text, thin spines, a white background, and editable SVG plus PDF plus 600 dpi TIFF. Single column is about 89 mm wide; double column is about 183 mm.

这份规范写的是投稿终稿，不是幻灯片大图。数值取自期刊终稿口径：正文 5–7 pt、单栏约 89 mm、双栏约 183 mm、矢量可编辑、TIFF 600 dpi。色相保持克制，同一方法家族不换色；绿和红只表示方向。白底，去掉上、右边框，默认无网格，图例无框。分面字母用小写粗体，放在面板左上附近，大约 8 pt。

## 字体与字号

- 字体：Arial；没有 Arial 时用 Helvetica，再退到 DejaVu Sans。
- 正文、刻度、图例：5–7 pt。Python 终稿基准是 7 pt；R 的 `base_size` 是 6.5，图题 7 pt，图例大约 5.8–6.2 pt。
- 分面字母：约 8 pt，小写、粗体。
- 幻灯片稿可以更大（约 15–24 pt），不能把那套字号交成期刊终稿。

## 线宽与画布

- Python 轴线 `axes.linewidth` 0.8。
- R 轴线和刻度线宽 0.35。
- 单栏宽约 89 mm，双栏宽约 183 mm。R 终稿默认画布按双栏 183×120 mm。
- 上、右边框关闭；无默认网格；`legend.frameon = FALSE`。

## 导出

主交付是可编辑矢量，不要只交 PNG。

- SVG：文字保持文本（Python `svg.fonttype = none`）。
- PDF：TrueType（Python `pdf.fonttype = 42`；R 用 cairo PDF，字体 Arial）。
- TIFF：600 dpi。
- PNG 只作预览，不代替终稿。

## 色板

Python 主色与本仓库 house 色接近但不是同一张表。终稿若混用两套，要在图注里写明，不要在同一张图里交替使用。

House 色（`styles/python` 与 `styles/r` 共用）：`#1e3a5f` `#2A629A` `#D98324` `#518B60` `#C75050` `#6B6B6B`。

## 与当前样式默认值不一致（未改代码）

对照 `styles/python/matplotlibrc`、`styles/python/style.py`、`styles/python/helpers.py`、`styles/r/theme_viz.R`。下面只记录差异，数值未改。

| 项 | 终稿规范 | 当前默认 |
|----|----------|----------|
| 正文字号 | Python 7 pt；R `base_size` 6.5 | matplotlibrc `font.size` 8；`theme_viz` `base_size` 8；`apply_style` 找不到 rc 时也是 8 |
| 图题 | R 图题 7 pt | matplotlibrc `axes.titlesize` 9 |
| 分面字母 | 约 8 pt | `add_panel_tag` 默认 `fontsize` 9；`theme_viz` 的 `plot.tag` 是 `base_size + 1`（即 9） |
| 轴线线宽 | Python 0.8；R 0.35 | matplotlibrc `axes.linewidth` 0.6；刻度线宽同样 0.6；`theme_viz` 轴线/刻度 0.4 |
| 数据线宽 | 未单列 | matplotlibrc `lines.linewidth` 1.2 |
| 字体族 | Arial / Helvetica / DejaVu Sans | matplotlibrc 未设 `font.family`；`theme_viz` 的 `base_family` 为空字符串 |
| 矢量文字 | `svg.fonttype=none`，`pdf.fonttype=42` | matplotlibrc 与 `save_fig` 都没设 |
| 导出 DPI | TIFF 600 | matplotlibrc `savefig.dpi` 300；`save_fig` 默认 300；`save_pub` 默认 `dpi` 300 |
| 画布宽度 | 单栏 89 mm，双栏 183 mm | `save_pub` 默认 `width_mm` 89（单栏），不是双栏 183 |
| 预览 DPI | 终稿预览仍按 600 出 TIFF | matplotlibrc `figure.dpi` 150 |
