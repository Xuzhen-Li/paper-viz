# 期刊终稿规范 / Journal figure contract

> **English Summary:** Figures use a sans-serif face, 12 pt axis text, and a closed black frame around the main panel. A one-panel figure stays near square or about 120 mm wide. A second track, such as an enrichment barcode, sits in a short strip under the main panel and shares the x axis.

工作画布上的轴刻度是 12 pt，轴标题 13 pt。主图是四边闭合的黑框，不是只留左和下。白底，默认无网格，图例无框。分面字母用小写粗体，大约 14 pt。图内标签和轴刻度同一档字号，不要用 2 mm 的小字。

## 字体与字号

- 字体：Arial；没有 Arial 时用 Helvetica，再退到 DejaVu Sans。
- 工作画布上的轴刻度是 12 pt，轴标题 13 pt，图例 11 pt。R 的 `theme_viz()` 默认 `base_size = 12`。Python 的 `font.size` 是 11，轴标题 12。
- 画廊预览一律 1200 px 宽。6.5 pt 画在 183 mm 宽的图上，缩进去之后轴字大约只有 15 px，所以看起来图很大、字很小。12 pt 大约是 30 px。
- 5–7 pt 是图已经缩到栏宽之后的印刷下限，不是作图时再写一遍的字号。
- 分面字母：约 14 pt，小写、粗体。

## 线宽与画布

- Python 轴线 `axes.linewidth` 0.8。
- R 面板边框线宽 0.7，刻度线宽 0.45。四边都画。极坐标图（饼图、环形条形图）关掉 `panel.border`。
- 单栏宽约 89 mm。一张主图优先接近方形或略宽，不要为了显得大拉到 183 mm。
- 有第二条轨道时（例如火山图下面的富集条码），短条贴在主图下方、共用横轴，高度大约是主图的五分之一，不要再套一个同样重的外框。区段标题写在面板内部，字号跟轴刻度同一档。
- 无默认网格。图例无框。

## 导出

主交付是可编辑矢量，不要只交 PNG。

- SVG：文字保持文本（Python `svg.fonttype = none`）。
- PDF：TrueType（Python `pdf.fonttype = 42`；R 用 cairo PDF，字体 Arial）。
- TIFF：600 dpi。
- PNG 只作预览，不代替终稿。

## 色板

Python 主色与本仓库 house 色接近但不是同一张表。终稿若混用两套，要在图注里写明，不要在同一张图里交替使用。

House 色（`styles/python` 与 `styles/r` 共用）：`#1e3a5f` `#2A629A` `#D98324` `#518B60` `#C75050` `#6B6B6B`。

分类色的数据图默认用 `pv_palette("categorical")`（Okabe–Ito）。公众号配色帖是「一篇图抽一排低饱和色」的读法，不是把帖子里的 HEX 抄进仓库。热图用已有的 sequential / diverging，不要把彩虹色标当默认。期刊具名色板（Nature、Science、Lancet）以后走 ggsci，现在还没接。

## 字号以代码为准

`styles/r/theme_viz.R` 的轴刻度是 12 pt。`styles/python/matplotlibrc` 的 `font.size` 是 11。单栏大约 89 mm，双栏大约 183 mm。一张图如果只是一个面板，优先 120 mm 左右，不要为了「看起来大」拉到 183 mm，否则同样的字在画廊里又会被缩小。
