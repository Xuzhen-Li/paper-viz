# pairformer-diffusion：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- Abramson J. et al. Accurate structure prediction of biomolecular interactions with AlphaFold 3 (2024). https://www.nature.com/articles/s41586-024-07487-w , Fig. 1 [待确认 面板]

只借用版式思路（通用流程），未描摹原图；所有标签为通用名称，不含真实蛋白、基因、物种或材料名。标题、URL 与图号沿用 `TARGETS.md`，[待确认] 原样保留；本轮未上网复核，未下载论文或任何期刊图。

## 图标来源

- 图标都由 `build.py` 用矩形、椭圆和折线画出（kit 的 `Fig.icon()` 与本图的 `g_*` 函数）；无位图、无外部图标库、无 AI 生成图标；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 183 x 89 mm（4 x 2 格，全宽导出约定）；字号 6-7.5 pt；线宽 0.5-1.2 pt；house 色板及其派生色；字体 Arial（回退 Liberation Sans）；preview.png 由 librsvg 按 600 dpi 渲染 figure.svg。
- 绘图 kit 复制自 `redraws/tree-of-thoughts-v2/build.py`（未改原文件），未使用 house.py、pvr.py、pvr_flow 或 `_apply_canvas`。
