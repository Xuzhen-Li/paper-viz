# genomic-language-model（v2）：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- Nguyen E. et al. Sequence modeling and design from molecular to genome scale with Evo (2024). https://www.science.org/doi/10.1126/science.ado9336 , Fig. 1 [待确认]

只借用版式思路，未描摹原图。这张图画的是 Evo 的任务分布：任务卡片按审查时已读的原文所写的任务填写（见下方 v2 改动），预测×系统一格在该原文里没有声明任务，所以留空并注明。不含真实基因名或编辑靶点序列；模型规模、上下文长度和数据量没有画。标题、URL 与图号沿用 `TARGETS.md`（S37），Fig. 1 [待确认] 原样保留；本轮未上网复核，未下载论文、补充材料或任何期刊图。

## 图标来源

- 图标都由 `build.py` 用矩形、椭圆和折线画出（kit 的 `Fig.icon()` 与本图的 `g_*` 函数）；无位图、无外部图标库、无 AI 生成图标；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 183 x 89 mm（4 x 2 格，全宽导出约定）；字号 6-7.5 pt；线宽 0.5-1.2 pt；house 色板及其派生色；字体 Arial（回退 Liberation Sans）；preview.png 由 librsvg 按 600 dpi 渲染 figure.svg。
- 绘图 kit 复制自 `redraws/tree-of-thoughts-v2/build.py`（未改原文件），未使用 house.py、pvr.py、pvr_flow 或 `_apply_canvas`。

## v2 改动（只改内容 ①-3.1；v1 目录未改）

- 「Gene essentiality / from the genes around it」由预测×系统移到预测×基因组。
- 删去预测×基因组里的「Region scoring / likelihood of long stretches」（所用原文中找不到依据）。
- 预测×系统不写任务名，改为虚线空格，内注「no task claimed in the source text used here」；没有虚构任务，也没有把占位内容写成 example。
- 顺带吸收 ② 3.2：设计×系统正文改为「co-designed protein–RNA or protein–DNA」。
- 预训练栏、预测×分子、设计×分子、设计×基因组长度生成三张卡片、画布与版式同 v1。
