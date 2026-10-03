# 期刊终稿规范 / Journal figure contract

> **English Summary:** Sans-serif figures with a closed black frame, white background, and one shared categorical palette in R and Python. Ordinary single panels are 85×60 mm with 7 pt ticks and the legend inside the frame. Square panels are 85×85 mm. Wide, circular, and multi-panel figures keep their canvas.

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
