---
name: paper-viz-gallery
description: >-
  Pick a paper-viz figure by category or tag, copy its folder, swap data.csv
  to the declared columns, and export with pv_save. Use when the user asks for
  a volcano, heatmap, forest, KM, PCA, boxplot, or another chart from this gallery.
---

# paper-viz gallery

图库根目录是本仓库。索引是仓库根的 `catalog.json`（由 `tools/build_catalog.py` 从 `figures/**/meta.yaml` 生成）。不要手改 `catalog.json`。

## 检索

1. 读 `catalog.json` 的 `figures` 数组。
2. 用 `category` 或 `tags` 过滤。`category` 只可能是 `distribution`、`comparison`、`correlation`、`composition`、`heatmap`、`dimension-reduction`、`differential-expression`、`enrichment`、`population-genetics`、`genome`、`phylogeny`、`network`、`microbiome-ecology`、`clinical`、`schematic`。
3. 命中后读该条的 `dir`、`data`、`code`、`data_columns`、`customize`、`when_to_use`。

## 用到用户项目

1. 把 `dir` 整个文件夹复制到用户项目，不要只抄 `plot.R`。
2. 按 `data_columns` 替换 `data.csv` 的列。列名是接口，不要改名；含义写在 meta 里。
3. 按 `customize` 改阈值、分组名或 `pv_palette` 的调用。不要另起一套主题。
4. 在该目录运行 `Rscript plot.R`（`lang: Python` 则 `python3 plot.py`）。R 图必须 `source("../../../styles/r/theme_viz.R")`，并用 `pv_save(plot, file, width_mm, height_mm)` 同时写出 PDF、600 dpi PNG 和 `preview.png`。用户项目里若目录深度变了，把 `source` 改成能找到本仓库 `styles/r/theme_viz.R` 的相对路径，或把 `styles/r/theme_viz.R` 一起复制后改这一行。

## 示例指令

1. 「从 paper-viz 找一张火山图，复制到当前分析目录，用我的 gene、log2_fold_change、pvalue 三列换掉 data.csv，把阈值改成 1.5 和 0.05。」
2. 「catalog 里 category 为 clinical 的图有哪些？把森林图文件夹拷过来，HR 和置信区间换成这张表。」
3. 「按 tag heatmap 取出聚类热图，保留 pv_palette("diverging")，用 pv_save 导出 89 mm 宽的 PDF。」
