# paper-viz

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Gallery](https://img.shields.io/badge/gallery-online-0E7C66)](https://xuzhen-li.github.io/paper-viz/)
[![Figures](https://img.shields.io/badge/figures-111-4C78A8)](https://xuzhen-li.github.io/paper-viz/)

![paper-viz banner](docs/banner.png)

![paper-viz figure contact sheet](docs/hero.png)

R 优先的科研绘图库：复制一张图的文件夹，按列接口换掉 `data.csv`，就能用统一期刊风格出图；也方便 agent 检索调用。

R-first paper-figure library: copy a figure folder, swap `data.csv` to the declared columns, and export in one journal style—also easy for agents to find and reuse.

在线画廊 / Gallery: <https://xuzhen-li.github.io/paper-viz/>

画廊一张卡片是一个主图。近重复图写在 `meta.yaml` 的 `variant_of` 上，变成这张卡片里的切换，不再各占一格。顶栏按任务筛选。搜索匹配中英文标题、标签、`when_to_use`、`customize` 和列名（例如「差异基因」会找到火山图和 MA 图）。打开卡片可以看大图、用途、列说明、CSV 表头和前 5 行、脚本顶部赋值参数和画布毫米；可以复制 `plot.R`，并下载原始的 `plot.R`、`data.csv`、`make_data.R`。地址栏 `#slug` 直接打开该图，例如 <https://xuzhen-li.github.io/paper-viz/#volcano> 。

One gallery card is one main figure. Near-duplicates set `variant_of` in `meta.yaml` and show up as toggles on that card. Filter by task. Search matches titles, tags, when-to-use text, customize notes, and column names. Open a card for the large preview, column descriptions, a CSV sample, top-of-file parameters, and canvas size; copy `plot.R` or download the raw files. `#slug` opens that figure, for example <https://xuzhen-li.github.io/paper-viz/#volcano>.

## 分类 / Categories

<!-- CATALOG:START -->

共 111 张。

| 分类 | 中文 | 数量 |
|------|------|------|
| `distribution` | 分布 | 11 |
| `comparison` | 比较 | 13 |
| `correlation` | 相关 | 10 |
| `composition` | 组成 | 13 |
| `heatmap` | 热图 | 4 |
| `dimension-reduction` | 降维 | 6 |
| `differential-expression` | 差异表达 | 3 |
| `enrichment` | 富集 | 3 |
| `population-genetics` | 群体遗传 | 14 |
| `genome` | 基因组 | 20 |
| `phylogeny` | 系统发育 | 2 |
| `network` | 网络 | 2 |
| `microbiome-ecology` | 微生物与生态 | 5 |
| `clinical` | 临床 | 3 |
| `layout` | 拼图 | 2 |

### 分布 `distribution`（11）

<img src="figures/distribution/beeswarm/preview.png" width="200" alt="蜂群图">
<img src="figures/distribution/density/preview.png" width="200" alt="密度图">
<img src="figures/distribution/ecdf/preview.png" width="200" alt="经验累积分布">
<img src="figures/distribution/histogram/preview.png" width="200" alt="直方图">

### 比较 `comparison`（13）

<img src="figures/comparison/bar-grouped/preview.png" width="200" alt="分组柱状图">
<img src="figures/comparison/bump-chart/preview.png" width="200" alt="凹凸图">
<img src="figures/comparison/circular-bar/preview.png" width="200" alt="环状柱形图">
<img src="figures/comparison/cleveland-dot/preview.png" width="200" alt="Cleveland 点图">

### 相关 `correlation`（10）

<img src="figures/correlation/bland-altman/preview.png" width="200" alt="Bland–Altman 图">
<img src="figures/correlation/bubble/preview.png" width="200" alt="气泡图">
<img src="figures/correlation/correlation-matrix/preview.png" width="200" alt="相关矩阵">
<img src="figures/correlation/hexbin/preview.png" width="200" alt="六边形分箱密度图">

### 组成 `composition`（13）

<img src="figures/composition/alluvial/preview.png" width="200" alt="桑基 / 冲积图">
<img src="figures/composition/donut/preview.png" width="200" alt="环形图">
<img src="figures/composition/house-donut/preview.png" width="200" alt="直标环图（house 风格）">
<img src="figures/composition/mosaic/preview.png" width="200" alt="马赛克图">

### 热图 `heatmap`（4）

<img src="figures/heatmap/circular-heatmap/preview.png" width="200" alt="环状热图">
<img src="figures/heatmap/dot-heatmap/preview.png" width="200" alt="点状热图">
<img src="figures/heatmap/heatmap/preview.png" width="200" alt="聚类热图">
<img src="figures/heatmap/house-heatmap/preview.png" width="200" alt="带数值的发散色热图（house 风格）">

### 降维 `dimension-reduction`（6）

<img src="figures/dimension-reduction/nmds/preview.png" width="200" alt="非度量多维标度">
<img src="figures/dimension-reduction/opls-da/preview.png" width="200" alt="OPLS-DA 得分图">
<img src="figures/dimension-reduction/pca-biplot/preview.png" width="200" alt="PCA 得分散点">
<img src="figures/dimension-reduction/pcoa/preview.png" width="200" alt="主坐标分析">

### 差异表达 `differential-expression`（3）

<img src="figures/differential-expression/expression-trend/preview.png" width="200" alt="表达趋势图">
<img src="figures/differential-expression/ma-plot/preview.png" width="200" alt="MA 图">
<img src="figures/differential-expression/volcano/preview.png" width="200" alt="火山图">

### 富集 `enrichment`（3）

<img src="figures/enrichment/enrichment-bar/preview.png" width="200" alt="富集柱状图">
<img src="figures/enrichment/enrichment-dot/preview.png" width="200" alt="富集气泡图">
<img src="figures/enrichment/gsea/preview.png" width="200" alt="GSEA 富集图">

### 群体遗传 `population-genetics`（14）

<img src="figures/population-genetics/admixture-bar/preview.png" width="200" alt="ADMIXTURE 堆积条">
<img src="figures/population-genetics/admixture-cv/preview.png" width="200" alt="ADMIXTURE 交叉验证折线">
<img src="figures/population-genetics/fst-heatmap/preview.png" width="200" alt="成对 Fst 热图">
<img src="figures/population-genetics/fstats-point/preview.png" width="200" alt="f3 / f4 / D 点距图">

### 基因组 `genome`（20）

<img src="figures/genome/busco-bar/preview.png" width="200" alt="BUSCO 堆积条形">
<img src="figures/genome/chromosome-ideogram/preview.png" width="200" alt="染色体示意图与密度">
<img src="figures/genome/circos/preview.png" width="200" alt="基因组圈图">
<img src="figures/genome/coverage-track/preview.png" width="200" alt="覆盖度与信号轨道">

### 系统发育 `phylogeny`（2）

<img src="figures/phylogeny/phylo-tree/preview.png" width="200" alt="分组着色系统树">
<img src="figures/phylogeny/tree-heatmap/preview.png" width="200" alt="树加热图或条形注释">

### 网络 `network`（2）

<img src="figures/network/chord/preview.png" width="200" alt="弦图">
<img src="figures/network/network/preview.png" width="200" alt="相关性网络">

### 微生物与生态 `microbiome-ecology`（5）

<img src="figures/microbiome-ecology/mantel-plot/preview.png" width="200" alt="Mantel 检验图">
<img src="figures/microbiome-ecology/rarefaction/preview.png" width="200" alt="稀释曲线">
<img src="figures/microbiome-ecology/rda-biplot/preview.png" width="200" alt="RDA 双序图">
<img src="figures/microbiome-ecology/stamp-diffbar/preview.png" width="200" alt="STAMP 差异条形">

### 临床 `clinical`（3）

<img src="figures/clinical/forest/preview.png" width="200" alt="森林图">
<img src="figures/clinical/km/preview.png" width="200" alt="Kaplan-Meier 生存曲线">
<img src="figures/clinical/roc/preview.png" width="200" alt="ROC 曲线">

### 拼图 `layout`（2）

<img src="figures/layout/composite-figure/preview.png" width="200" alt="四面板拼图">
<img src="figures/layout/house-small-multiples/preview.png" width="200" alt="小多图与面板内趋势（house 风格）">
<!-- CATALOG:END -->

## 快速开始 / Quick start

复制一个图文件夹，按该目录 `meta.yaml` 的 `data_columns` 替换 `data.csv`，再出图。

Copy a figure folder, replace `data.csv` using `data_columns` in `meta.yaml`, then plot.

```bash
cp -R figures/differential-expression/volcano ./volcano
cd volcano
# 按 data_columns 编辑 data.csv
Rscript plot.R
```

新图用 house style：`styles/r/theme_house.R` 的 `theme_house()` 与 `pv_save_house()`；已有的图仍用 `styles/r/theme_viz.R` 的 `theme_viz()` 与 `pv_save()`。两者都同时写出 PDF、600 dpi PNG 和 1200 px 宽的 `preview.png`。`layout` 拼图同样是 R 图：一份 `plot.R` 读 `data.csv`，用 `patchwork` 等拼成多面板。

CRAN：

```r
install.packages(c(
  "MASS", "ape", "circlize", "cowplot", "ggalluvial", "ggbeeswarm", "ggplot2",
  "ggraph", "ggrepel", "ggridges", "ggseqlogo", "ggvenn", "igraph", "maps",
  "pROC", "patchwork", "scales", "scatterpie", "survival", "vegan"
))
```

Bioconductor：

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install(c("ComplexHeatmap", "ggplotify", "ggtree"))
```

两张 Python 图另需 `matplotlib` 与 `numpy`。不要把本机绝对路径写进仓库。

## House style（新图默认）/ House style (default for new figures)

规范页 / Style page: <https://xuzhen-li.github.io/paper-viz/house-style/>

新加的图一律用 house style：紧凑、字多、留白少。单栏 89 mm / 双栏 183 mm；双栏图刻度 7 pt、轴标题 8 pt，单栏只放一个面板时 9/10 pt（`pv_save_house()` 自动加 2 pt）；四边 0.5 pt 黑框、刻度向外 1 mm、无网格；轴标题不加粗；系列名直接写在图里，不画图例；分类色用 `pv_palette("house")`，一张图最多 6 个彩色系列。R 里 `source("../../../styles/r/theme_house.R")`（会顺带加载 `theme_viz.R`），然后 `theme_house()`、`pv_palette("house")`、`pv_save_house(p, "figure", width = "single" | "double", height_mm = ...)`；Python 用 `styles/python/house.py` 的 `apply_house_style()`、`house_figure()`、`save_house()`。九个参考实现在 `figures/*/house-*/`，完整规则见 [styles/style-contract.md](styles/style-contract.md)。已有的图不重渲染，继续用 `theme_viz()`。

New figures use the house style: compact, text-dense, little white space. 89 mm single / 183 mm double column; 7 pt ticks and 8 pt axis titles on double-column figures, 9/10 pt for a single panel on 89 mm (`pv_save_house()` adds the 2 pt); four-sided 0.5 pt frame, ticks outward 1 mm, no grid; plain (not bold) axis titles; direct labels instead of legends; category colours from `pv_palette("house")`, at most 6 coloured series per figure. In R, `source("../../../styles/r/theme_house.R")` (it also loads `theme_viz.R`), then use `theme_house()`, `pv_palette("house")` and `pv_save_house(p, "figure", width = "single" | "double", height_mm = ...)`. In Python, use `apply_house_style()`, `house_figure()` and `save_house()` from `styles/python/house.py`. The nine reference folders are `figures/*/house-*/`; full rules in [styles/style-contract.md](styles/style-contract.md). Existing figures are not re-rendered and keep `theme_viz()`.

```r
# figures/<category>/<slug>/plot.R
source("../../../styles/r/theme_house.R")   # also loads theme_viz.R
df <- utils::read.csv("data.csv")
p <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = group)) +
  ggplot2::geom_line(linewidth = pv_house_lw("main")) +
  ggplot2::scale_colour_manual(values = unname(pv_palette("house", 3))) +
  theme_house()                              # 7/8 pt; theme_house(legend = "inside") if a legend is unavoidable
pv_save_house(p, "figure", width = "single", height_mm = 76)  # 89 mm single panel -> +2 pt (9/10 pt)
```

## 给 agent 用 / For agents

用法在 [AGENTS.md](AGENTS.md)。用下面的命令检索，或读 [catalog.json](catalog.json)（`tools/build_catalog.py` 生成，不要手改）。给大模型的纯文本索引是 [docs/llms.txt](docs/llms.txt)。技能说明仍见 [skills/paper-viz-gallery/SKILL.md](skills/paper-viz-gallery/SKILL.md)。

How an AI agent should use this library is in [AGENTS.md](AGENTS.md). Search with the commands below, or read [catalog.json](catalog.json) (generated by `tools/build_catalog.py`; do not edit it by hand). The plain-text index is [docs/llms.txt](docs/llms.txt). The skill note is [skills/paper-viz-gallery/SKILL.md](skills/paper-viz-gallery/SKILL.md).

```bash
python3 tools/find_figure.py volcano
python3 tools/find_figure.py 差异基因
python3 tools/find_figure.py --category population-genetics
python3 tools/find_figure.py --column pvalue
python3 tools/find_figure.py --slug volcano --json
```

## 目录 / Layout

| 路径 | 内容 |
|------|------|
| `figures/<category>/<slug>/` | `make_data.R`、`data.csv`、`plot.R`、`preview.png`、`meta.yaml` |
| `styles/` | 期刊风格，见 [styles/style-contract.md](styles/style-contract.md) |
| `catalog.json` | 全库索引 |
| `AGENTS.md` | AI agent 怎么检索、换数据、出图 |
| `docs/llms.txt` | 给大模型的一行一条主图索引 |
| `docs/` | GitHub Pages 画廊（`main` 分支 `/docs`） |
| `extras/web/` | 静态嵌图与 Plotly 草稿 |
| `skills/paper-viz-gallery/` | agent 取图说明 |
| `tools/` | 目录生成与质量门 |

## 贡献 / Contributing

1. 新建 `figures/<category>/<slug>/`。`category` 只能是：`distribution`、`comparison`、`correlation`、`composition`、`heatmap`、`dimension-reduction`、`differential-expression`、`enrichment`、`population-genetics`、`genome`、`phylogeny`、`network`、`microbiome-ecology`、`clinical`、`layout`。
2. `make_data.R` 固定随机种子，写出小于 200KB 的 `data.csv`。`plot.R` 只读数据，`source("../../../styles/r/theme_house.R")`（会顺带加载 `theme_viz.R`），用 `theme_house()`、`pv_palette("house")` 和 `pv_save_house()`。已有图里的 `theme_viz()` / `pv_save()` 保持不动，复制旧图时沿用它原来的接口。`layout` 也走这一套，多面板写在同一份 `plot.R` 里。
3. `meta.yaml` 必填：`title`、`title_zh`、`slug`、`category`、`tags`（英文）、`packages`、`data_columns`、`when_to_use`、`customize`、`lang`（`R` 或 `Python`）。`title_zh`、`when_to_use`、`customize` 不能为空。
4. 质量门：`bash tools/check_figure.sh figures/<category>/<slug>` 必须通过，然后 `python3 tools/build_catalog.py`。

同一图型只留一版。变体写进 `plot.R` 顶部参数，并记在 `customize`。

## License

MIT. Copyright (c) 2026 Xuzhen Li. See [LICENSE](LICENSE).
