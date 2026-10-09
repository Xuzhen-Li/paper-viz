# 期刊终稿规范 / Journal figure contract

> **English Summary:** New figures use the **house style** (`styles/r/theme_house.R`, `styles/python/house.py`): compact, text-dense, little white space. sizes on a 43 mm grid given as `cells = c(w, h)` (1–4 cells per side: 43 / 89 / 135 / 183 mm), 7 pt ticks, 8 pt plain axis titles, 10 pt bold lowercase panel tags, four-sided 0.5 pt frame, ticks outward 1 mm, no grid, direct labels instead of legends, the nine-colour house palette. Only a single panel saved at 2×2 (89 × 89 mm) gets +2 pt (9/10 pt). Export cairo PDF (text stays text) plus a 600 dpi PNG. Existing figures keep the legacy `theme_viz()` contract below and are not re-rendered; `theme_viz()`, `pv_save()` and `pv_palette("categorical")` (chip eight) stay available.

## House style（新图默认，2026-10 起）

**新加的图一律用 house style**；已有的图不重渲染，继续按下文“旧版 theme_viz 规范”。一句话：**紧凑、字多、留白少**。

入口：

- R：`source("../../../styles/r/theme_house.R")`（会顺带加载同目录的 `theme_viz.R`），然后 `theme_house()`、`pv_palette("house")`、`pv_save_house()`。
- Python：`import house`（`styles/python/house.py`），然后 `house.apply_house_style()`、`house.house_figure()`、`house.save_house()`。
- 规范页（九张示例、出图流程与字号层级示意图；网格示意图待重画）：<https://xuzhen-li.github.io/paper-viz/house-style/>

### 用法 / Usage

中文：source `theme_house.R`；主题 `theme_house()`、颜色 `pv_palette("house")`、导出 `pv_save_house(p, "figure", cells = "2x1")`。尺寸只用 `cells = c(宽格数, 高格数)`（或 `"WxH"`），不在网格上的尺寸直接报错；旧写法 `width = "single", height_mm = 76` 现在会报错。默认 7/8 pt；只有单个面板存成 2×2（89 × 89 mm）时自动 +2 pt，`bump = 0` 关掉。多张图拼一页用 `pv_house_mosaic()`。非用图例不可时用 `legend = "inside"`，放框内右上。*P* 值用 `pv_fmt_p(p)`（配 `parse = TRUE`），7/8 pt 的图不写上标。

English: source `theme_house.R`, then use `theme_house()` for the theme, `pv_palette("house")` for colours and `pv_save_house(p, "figure", cells = "2x1")` to export. Sizes are given only as `cells = c(width, height)` in grid cells (or `"WxH"`); a size off the grid is an error, so the old call `width = "single", height_mm = 76` now fails. Defaults are 7 pt ticks and 8 pt plain axis titles; only a single panel saved at 2×2 (89 × 89 mm) gets +2 pt, and `bump = 0` switches this off. To put several plots on one page, use `pv_house_mosaic()`. When a legend is unavoidable, use `legend = "inside"` (top-right inside the frame, no box). Use `pv_house_lw()` for line widths, `HOUSE_POINT` for points, `pv_pt2size(pt)` for in-panel text size and `pv_fmt_p(p)` for *P* labels (with `parse = TRUE`); at 7/8 pt keep the default form without superscripts. `pv_save_house()` overwrites any `preview.png` in the output folder.

```r
theme_house(base_size = 7, title_size = base_size + 1, tag_size = max(10, base_size + 3),
            base_family = house_family(), legend = c("none", "inside"))
pv_save_house(plot, file, width = NULL, height_mm = NULL, cells = NULL,
              bump = NULL, dpi = 600, preview = TRUE)   # 用 cells = c(w, h) 或 "WxH" / use cells
pv_house_mosaic(tiles, cells)   # tiles = list(list(plot = , at = c(col, row), cells = c(w, h)), ...)
pv_fmt_p(p, digits = 1, exact = FALSE)
```

```r
# figures/<category>/<slug>/plot.R
source("../../../styles/r/theme_house.R")   # 会顺带加载 theme_viz.R
library(ggplot2)
df <- data.frame(x = rep(1:10, 3),
                 y = c(1:10, 0.8 * (1:10) + 1, 0.5 * (1:10) + 2),
                 group = rep(c("a", "b", "c"), each = 10))   # 真实数据用 utils::read.csv("data.csv")
p <- ggplot(df, aes(x, y, colour = group)) +
  geom_line(linewidth = pv_house_lw("main")) +
  scale_colour_manual(values = unname(pv_palette("house", 3))) +
  theme_house()                               # 7/8 pt；非用图例不可时 theme_house(legend = "inside")
pv_save_house(p, "figure", cells = "2x1")     # 折线默认 2×1 = 89 × 43 mm；会覆盖同目录的 preview.png
```

拼页示例（三张图排成 1 + 1 + 2，导出 183 × 43 mm）/ Mosaic example (three plots as 1 + 1 + 2, exported at 183 × 43 mm):

```r
# figures/<category>/<slug>/plot.R
source("../../../styles/r/theme_house.R")
library(ggplot2)
set.seed(1)
df <- data.frame(x = 1:30, y = 1:30 + rnorm(30, 0, 4))
fit <- summary(lm(y ~ x, data = df))
p_lab <- pv_fmt_p(coef(fit)[2, 4])                  # "P < 0.001"，7/8 pt 用这个
p_exact <- pv_fmt_p(coef(fit)[2, 4], exact = TRUE)  # "P = m × 10^−k"，只用于 ≥8.6 pt 的文字
pa <- ggplot(df, aes(x, y)) +
  geom_point(shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
             fill = pv_palette("house")[["blue"]]) +
  annotate("text", x = 1, y = 35, hjust = 0, vjust = 1, size = pv_pt2size(7),
           label = p_lab, parse = TRUE) +
  labs(x = "Dose (mg)", y = "Response", tag = "a") + theme_house()
pb <- ggplot(df, aes(y)) +
  geom_histogram(bins = 8, fill = pv_palette("house")[["sky"]], colour = "white") +
  labs(x = "Response", y = "Count", tag = "b") + theme_house()
pc <- ggplot(df, aes(x, y)) +
  geom_line(linewidth = pv_house_lw("main"), colour = pv_palette("house")[["red"]]) +
  labs(x = "Day", y = "Response", tag = "c") + theme_house()
page <- pv_house_mosaic(list(
  list(plot = pa, at = c(1, 1), cells = c(1, 1)),
  list(plot = pb, at = c(2, 1), cells = c(1, 1)),
  list(plot = pc, at = c(3, 1), cells = c(2, 1))
), cells = c(4, 1))
pv_save_house(page, "figure", cells = c(4, 1))      # cells 必须与 mosaic 的 cells 相同 / must match
```

Python：`fig, ax = house.house_figure(cells="2x1")`，画完 `house.save_house(fig, "figure")`（cells 沿用 `house_figure` 的设置）。/ Python: `fig, ax = house.house_figure(cells="2x1")`, then `house.save_house(fig, "figure")`, which reuses the cells given to `house_figure`.

### 网格与画布 / Grid and canvas

中文：

- **网格单位**：格宽 S = 43 mm，格间距 g = 3 mm。n 格跨度 = n × 43 + (n − 1) × 3，即 1–4 格分别为 **43 / 89 / 135 / 181 mm**。
- **外边距**：某一边占满 4 格时，这一边两侧各加 1 mm，导出 **183 mm**（1 + 181 + 1）；1–3 格的边不加边距，画布就是跨度本身。宽和高分别算。
- **画布 = 导出页面**：`cells = c(w, h)`，w、h 各为 1–4 的整数。例：`"1x1"` = 43 × 43，`"2x1"` = 89 × 43，`"2x2"` = 89 × 89，`"4x2"` = 183 × 89，`"4x3"` = 183 × 135 mm。
- **排法**：双栏每行 4 格，可组合为 1+1+1+1 / 1+1+2 / 2+2 / 1+3 / 4；单栏每行 2 格（`width = "single"` 等于 2 格宽）。
- **报错**：不在网格上的尺寸直接报错，不会悄悄取整。`cells` 超出 1–4 或不是整数时报错；只给 `width` / `height_mm` 时只认 43 / 89 / 135 / 183 mm，报错信息会给出最近的网格尺寸；`cells` 与 `width` / `height_mm` 同时给也报错；什么都不给时报错，提示写 `cells`。
- **+2 pt**：只有**单个面板存成 2×2（89 × 89 mm）**时全部字号 +2 pt（刻度 9、轴标题 10）。其他尺寸、patchwork 组合图、分面图、拼页（mosaic）一律不加。
- **拼页**：`pv_house_mosaic(tiles, cells)` 把几张图放到同一页的格子上：每张图写 `at = c(列, 行)`（从 1 起，左上为 1, 1）和 `cells = c(w, h)`；第 c 列的图从 1 + 46 × (c − 1) mm 处开始（4 格宽的页）。超出页面、互相重叠时报错。结果交给 `pv_save_house()`，cells 必须与拼页相同。
- `theme_house()` 的 plot.margin 为上 1.6 / 右 0.8 / 下 0.9 / 左 0.4 mm。底边 0.9 mm 是专门留的：ragg 和 cairo-png 排出的文字比 cairo PDF 略低，底边只留 0.4 mm 时，600 dpi PNG 的最后一行像素会切到 x 轴标题的下伸部分（g、y、括号）。`tests/test_theme_house.R` 检查最后一行像素全白。自定义 plot.margin 时，底边不要小于 0.9 mm。
- 字号不随面板缩小；绘图区 ≥60% 面板面积。

默认格数（拿不准时用这个；太挤或太空可在网格内升降一档，并在 meta.yaml 写明原因）：

| 图型 | 默认 cells |
|---|---|
| 散点 | 1×1 |
| 直方图 / 密度 | 1×1 |
| 箱线 / 小提琴 / 雨云 | 1×1；组多时 2×1 |
| 柱图 | 1×1；类别多时 2×1 |
| 折线 / 时间序列 | 2×1 |
| 堆叠构成 | 2×1 |
| 森林图 | 1×2；行多时 2×2 |
| 热图 | 2×2 |
| 小多图 | 每张小图 1×1 |
| 基因组轨道 / 曼哈顿图 | 4×1 |

九张示例的实际格数：

| 示例 | 默认 | 实际 | 画布 (mm) | +2 pt | 说明 |
|---|---|---|---|---|---|
| house-scatter | 1×1 | 2×2 | 89 × 89 | 是 | 升一档：6 个直接标签加 3 行 *R*² / *P*，43 mm 里 “Wild” 压在点上，“Cabernet Sauvignon” 的引线穿过点云 |
| house-density | 1×1 | 1×1 | 43 × 43 | 否 | x 轴标题缩短为 “Flowering to véraison (d)” |
| house-raincloud | 1×1 | 1×1 | 43 × 43 | 否 | n 标签放在各组下方居中 |
| house-bar | 1×1 | 1×1 | 43 × 43 | 否 | 4 组不算多，不升档 |
| house-line | 2×1 | 2×1 | 89 × 43 | 否 | — |
| house-donut | 2×1（按堆叠构成） | 2×1 | 89 × 43 | 否 | 1×1 时环直径约 18 mm，标签放不下 |
| house-forest | 1×2；行多时 2×2 | 2×2 | 89 × 89 | 是 | 16 行算“行多”；1×2 时 2024 / 2025 图例重叠、数值被截 |
| house-heatmap | 2×2 | 2×2 | 89 × 89 | 是 | — |
| house-small-multiples | 每张小图 1×1 | 4×2 | 183 × 89（内容 181 × 89） | 否 | 8 个区域排 4 × 2，面板间距 3 mm |

另有拼页示例 `house-grid-mosaic`：七种图排在一页 4×3（183 × 135 mm）上。7/8 pt 的图不用 plotmath 上标（上标按 0.7 倍排，会低于 6 pt）：*P* < 0.001 用 `pv_fmt_p()` 默认写法，*R*² 写 Unicode 字符 ²，单位写 mg/g。

English:

- **Grid unit**: cell width S = 43 mm, gap g = 3 mm. A span of n cells is n × 43 + (n − 1) × 3, so 1–4 cells span **43 / 89 / 135 / 181 mm**.
- **Margin**: a side that spans all 4 cells gets 1 mm on each end and is exported at **183 mm** (1 + 181 + 1); a side of 1–3 cells gets no margin and the canvas equals the span. Width and height are handled separately.
- **Canvas = exported page**: `cells = c(w, h)`, with w and h whole numbers from 1 to 4. Examples: `"1x1"` = 43 × 43, `"2x1"` = 89 × 43, `"2x2"` = 89 × 89, `"4x2"` = 183 × 89, `"4x3"` = 183 × 135 mm.
- **Layout**: a double column has 4 cells per row, combined as 1+1+1+1, 1+1+2, 2+2, 1+3 or 4; a single column has 2 cells per row (`width = "single"` means 2 cells wide).
- **Errors**: sizes off the grid are errors and are never rounded silently. `cells` outside 1–4 or not whole is an error; `width` / `height_mm` alone accept only 43, 89, 135 or 183 mm, and the message names the nearest grid size; giving `cells` together with `width` / `height_mm` is an error; giving neither is an error that asks for `cells`.
- **+2 pt**: only a **single panel saved at 2×2 (89 × 89 mm)** gets +2 pt on all text (9 pt ticks, 10 pt axis titles). Other sizes, patchwork compositions, faceted plots and mosaics never get it.
- **Mosaic**: `pv_house_mosaic(tiles, cells)` places several plots on one grid page. Each tile gives `at = c(col, row)` (from 1, top-left is 1, 1) and `cells = c(w, h)`; on a 4-cell-wide page a tile in column c starts at 1 + 46 × (c − 1) mm. Tiles that leave the page or overlap are errors. Pass the result to `pv_save_house()` with the same cells.
- `theme_house()` uses plot.margin top 1.6 / right 0.8 / bottom 0.9 / left 0.4 mm. The 0.9 mm bottom is deliberate: ragg and cairo-png set text slightly lower than cairo PDF, and with only 0.4 mm the last pixel row of a 600 dpi PNG clips the descenders of the x-axis title (g, y, brackets). `tests/test_theme_house.R` checks that the last pixel row is white. If you set your own plot.margin, keep the bottom at 0.9 mm or more.
- Text does not shrink with the panel; the plotting area is at least 60% of the panel.

Default cells (use these when unsure; if a figure is crowded or empty, move one size up or down within the grid and give the reason in meta.yaml):

| Chart | Default cells |
|---|---|
| Scatter | 1×1 |
| Histogram / density | 1×1 |
| Box / violin / raincloud | 1×1; 2×1 with many groups |
| Bar | 1×1; 2×1 with many categories |
| Line / time series | 2×1 |
| Stacked composition | 2×1 |
| Forest | 1×2; 2×2 with many rows |
| Heatmap | 2×2 |
| Small multiples | 1×1 per small plot |
| Genome track / Manhattan | 4×1 |

Actual cells of the nine examples:

| Example | Default | Actual | Canvas (mm) | +2 pt | Note |
|---|---|---|---|---|---|
| house-scatter | 1×1 | 2×2 | 89 × 89 | yes | One size up: six direct labels plus three lines of *R*² / *P*; at 43 mm “Wild” sat on the points and the “Cabernet Sauvignon” leader crossed the point cloud |
| house-density | 1×1 | 1×1 | 43 × 43 | no | x-axis title shortened to “Flowering to véraison (d)” |
| house-raincloud | 1×1 | 1×1 | 43 × 43 | no | n labels centred under each group |
| house-bar | 1×1 | 1×1 | 43 × 43 | no | Four groups is not many, so no step up |
| house-line | 2×1 | 2×1 | 89 × 43 | no | — |
| house-donut | 2×1 (as stacked composition) | 2×1 | 89 × 43 | no | At 1×1 the ring is about 18 mm across and the labels do not fit |
| house-forest | 1×2; 2×2 with many rows | 2×2 | 89 × 89 | yes | 16 rows count as many; at 1×2 the 2024 / 2025 legend overlapped and values were clipped |
| house-heatmap | 2×2 | 2×2 | 89 × 89 | yes | — |
| house-small-multiples | 1×1 per small plot | 4×2 | 183 × 89 (content 181 × 89) | no | Eight regions in 4 × 2, 3 mm between panels |

The mosaic example `house-grid-mosaic` puts seven chart types on one 4×3 page (183 × 135 mm). Figures at 7/8 pt use no plotmath superscripts, which are set at 0.7× and would fall under 6 pt: *P* < 0.001 via the default `pv_fmt_p()`, *R*² with the Unicode character ², and units as mg/g.

### 字号（印刷最终尺寸）

| 元素 | 字号 | 字重 |
|---|---|---|
| 刻度标签 | 7 pt | 常规 |
| 轴标题 | 8 pt | **常规，不加粗** |
| 直接数据标签 | 7–8 pt | 常规，关键系列可加粗 |
| 图内统计量（*R*²、*P*、*N*） | 7 pt | 常规，与组同色 |
| 面板字母 | 10 pt | 粗体小写 a b c（patchwork `tag_levels = "a"`） |
| 任何文字最小值 | 6 pt | — |

- **只有单个面板存成 2×2（89 × 89 mm）时，全部字号 +2 pt**（刻度 9、轴标题 10）。`pv_save_house()` / `save_house()` 在 cells 为 2×2 且只有一个面板（非 patchwork、非拼页、无分面 / 只有一个数据轴）时自动加；按当前刻度字号算差值，已经用 `theme_house(base_size = 9)` 的图不会再加一次；`bump = 0` 可关掉。
- `geom_text()` / `annotate()` 的 size 用 `pv_pt2size(pt)`（7 pt = 2.46，8 pt = 2.81，6 pt = 2.11）。
- source `theme_house.R` 后 `geom_text` / `geom_label` / ggrepel 的默认字号是 **7 pt**（与刻度同号）；不写 `size` 的文字层在 2×2 单面板导出时同样自动 +2 pt。
- **patchwork 组合图不加 +2 pt，即使里面只有一个子图**（`wrap_plots(p)` 也算组合）；单面板请直接把 ggplot 对象交给 `pv_save_house()`，或手动 `theme_house(base_size = 9)`。分面（facet）图同样不加。
- 示例：`figures/*/house-*/` 下 9 个文件夹（散点、折线、柱、雨云、森林图、热图、密度、环图、小多图）是本风格的参考实现。

### 字体

Arial → Helvetica → Liberation Sans → DejaVu Sans（按机器上有的取第一个）；中文用思源黑体 / Noto Sans CJK SC。全图一种字体，数学符号用同字体斜体（Python 的 mathtext 也设为同一无衬线字体）。

- R 图内文字（`geom_text` / `annotate` / `geom_label` / ggrepel）也用主题字体：source `theme_house.R` 时设好这些 geom 的默认 `family`，`pv_save_house()` 导出前再给没写 `family` 的文字图层（含 patchwork 子图）补上，PDF 里不会混入 NimbusSans 等设备默认字体。只 source `theme_viz.R` 的旧图不受影响。

### 线与点

| 元素 | pt | R |
|---|---|---|
| 边框、刻度线（长 1 mm，向外） | 0.5 | `theme_house()` 已设 |
| 主数据线 | 1.5 | `linewidth = pv_house_lw("main")` |
| 强调线 / 拟合线 | 2.0 | `pv_house_lw("emph")` |
| 次要系列 | 0.8 | `pv_house_lw("minor")` |
| 参考线（虚线） | 0.5 | `pv_house_lw("ref")` |
| 误差棒 | 0.7 | `pv_house_lw("errorbar")` |

- 点：shape 21（实心圆加描边），描边 `#000000`；≤200 个点不透明。**以定稿 demo A 的 ggplot 值为准**：`HOUSE_POINT`（`size = 2.3, stroke = 0.3`），实际填充直径约 1.9 mm、描边约 0.43 pt、外径约 2.0 mm（`pv_point_dims()` 可算）。STYLE §5 里“1.2–1.4 mm”与它自己给的 ggplot `size = 2.2–2.6` 对不上，这里按 Jason 确认的 demo A 观感取 ggplot 值。Python `house.POINT` / `house.SCATTER` 由同一公式换算，物理尺寸与 R 相同（测试里两边各画一个点比对外径）。
- **点规格统一**：普通数据点（散点、折线上的点）一律 `shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke`（21 / 2.3 / 0.3），不在图里另写数字。只有下面两种例外改 size，shape 和 stroke 仍取常量，写法是在 plot.R 顶部 `utils::modifyList(HOUSE_POINT, list(size = …))`：
  - **点估计**（森林图、dot plot）：`size = 3–3.5`（STYLE §5，直径约 1.8–2.2 mm），示例 `house-forest` 用 `est_point`（3.2）。
  - **叠在柱或箱体上的原始点**：比普通点小，`shape 21`、`stroke = 0.3`。柱图 `size = 1.6, alpha = 0.8`；雨云/箱线的抖动点 `size = 1.2–1.6, alpha = 0.7`（STYLE §12），示例 `house-raincloud` 用 `raw_point`（1.6）。
- 小多图的面板框与单面板相同，都是 0.5 pt 黑框。183 mm 的图缩到 1200 px 宽的 preview 时，这条线不到 1.2 px，看起来发灰，但 PDF 里是纯黑。
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

- `pv_save_house(plot, "figure", cells = c(w, h))`：画布按上面的网格算；cairo PDF（字体嵌入，文字保留为文本，不转曲）+ 600 dpi PNG + 1200 px 宽 `preview.png`。
- Python `house.save_house(fig, "figure")`：PDF（TrueType，`pdf.fonttype = 42`）+ 600 dpi PNG + `preview.png`；不裁边（不用 `bbox_inches="tight"`），保证网格尺寸（43 / 89 / 135 / 183 mm）精确。
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
