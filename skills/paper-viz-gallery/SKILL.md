---
name: paper-viz-gallery
description: >-
  Pick a paper-viz figure by category or tag, copy its folder, swap data.csv
  to the declared columns, and export with pv_save. Use when the user asks for
  a volcano, Manhattan, PCA, pangenome schematic, or another chart from this gallery.
---

# paper-viz gallery

图库根目录是本仓库。索引是仓库根的 `catalog.json`（由 `tools/build_catalog.py` 从 `figures/**/meta.yaml` 生成）。不要手改 `catalog.json`。在线画廊：<https://xuzhen-li.github.io/paper-viz/>。

## catalog.json 字段

根对象是 `{ "figures": [ ... ] }`。每条常用字段：

| 字段 | 含义 |
|------|------|
| `title` / `title_zh` | 英文名 / 中文名 |
| `slug` | 目录名，全库唯一 |
| `category` | 15 个分类之一 |
| `tags` | 英文标签数组 |
| `packages` | 依赖 |
| `data_columns` | 列名 → 含义；列名是接口 |
| `when_to_use` | 何时用（中文） |
| `customize` | 改哪些参数 |
| `lang` | `R`、`Python` 或 `drawio` |
| `dir` | `figures/<category>/<slug>` |
| `code` / `data` | `plot.R`（或 `plot.py`）与 `data.csv`；流程图的 `data` 为 null |
| `preview` | `preview.png` |
| `github_code` / `github_data` / `github_dir` | GitHub blob 链接 |

`category` 只可能是 `distribution`、`comparison`、`correlation`、`composition`、`heatmap`、`dimension-reduction`、`differential-expression`、`enrichment`、`population-genetics`、`genome`、`phylogeny`、`network`、`microbiome-ecology`、`clinical`、`schematic`。

## 检索

1. 读 `catalog.json` 的 `figures`。
2. 用 `category` 或 `tags` 过滤（例如 `category == "population-genetics"`，或 `tags` 含 `manhattan`）。
3. 命中后读 `dir`、`lang`、`data_columns`、`customize`、`when_to_use`。

## R 图：复制、换数据、改参数

1. 把 `dir` 整个文件夹复制到用户项目，不要只抄 `plot.R`。
2. 按 `data_columns` 替换 `data.csv`。列名不要改。
3. 按 `customize` 改 `plot.R` 顶部的阈值、分组、颜色或标签开关。继续用 `theme_viz()` 和 `pv_palette()`。
4. 在该目录运行 `Rscript plot.R`。脚本 `source("../../../styles/r/theme_viz.R")`。目录深度变了就把 `styles/r/theme_viz.R` 一起复制，并改这一行。`pv_save()` 同时写出 PDF、600 dpi PNG 和 `preview.png`。
5. `lang: Python` 时运行 `python3 plot.py`，列接口仍然是 `data_columns`。

## draw.io 模板：改字

1. 复制 `figures/schematic/<slug>/`（`template.drawio`、`figure.svg`、`preview.png`、`meta.yaml`）。
2. 用 draw.io 打开 `template.drawio`，按 `customize` 改方框文字。
3. 导出覆盖 `figure.svg`。不要把示意图重写成 R 代码。

## 示例

1. 群体遗传 PCA：`category` 为 `population-genetics`、`slug` 为 `pca-population`。复制 `figures/population-genetics/pca-population/`。`data.csv` 保留 `sample`、`pop`、`PC1`、`PC2`、`PC3`、`var_explained`。按 `customize` 改 `show_ellipse`、`show_labels`、`pc_x`、`pc_y`，然后 `Rscript plot.R`。
2. GWAS 曼哈顿：`tags` 含 `manhattan`，目录 `figures/genome/gwas-manhattan/`。列是 `chr`、`pos`、`p`、`snp`、`highlight`。改 `sig_threshold`、`sug_threshold`、`show_qq` 后 `Rscript plot.R`。
3. 火山图：`slug` 为 `volcano`，目录 `figures/differential-expression/volcano/`。用用户的 `gene`、`log2_fold_change`、`pvalue` 换掉 `data.csv`，把 `lfc_cut` 与 `p_cut` 改成 1.5 和 0.05，再 `Rscript plot.R`。
4. 泛基因组流程图：`slug` 为 `pangenome-phases`，`lang` 为 `drawio`。用 draw.io 打开 `figures/schematic/pangenome-phases/template.drawio`，改四条色带的阶段名和任务方框，导出 `figure.svg`。
