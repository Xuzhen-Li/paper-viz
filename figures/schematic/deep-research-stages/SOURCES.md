# deep-research-stages：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- Deep Research survey (Zhang et al.), 2025. https://arxiv.org/abs/2508.12752 , Fig. 1（TARGETS.md S44）

标题、URL 和图号沿用 `TARGETS.md`（标为已核对 ✓）；本轮未上网复核，未下载论文或任何期刊图。
版式是自拟的通用示意图，只借用“分阶段/分层”的思路；文字为通用标签，不是原图的逐字复制。

## 图标来源

- 全部图标由 `build.py` 用矩形、椭圆和折线画出（套件 `Fig.icon()` 加本图 `gicon()`）。
- 无位图、无 AI 生成图标、无外部图标库、无期刊原图；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 183 x 89 mm（4 x 2 格，全宽导出约定）；字号 6-7.5 pt；线宽 0.5-1.2 pt；字体 Arial（回退 Liberation Sans）。
- 颜色只用 house 色板及其 `tint()`/`mid()`/`dark()` 派生色，文字 #1A1A1A 或深色派生；标注全部在画框内。
- 绘图套件逐字复制自 `redraws/tree-of-thoughts-v2/build.py`（第 16-454 行）+ 两项附加检查（连线穿字、游离标签压框线），未用 house.py / pvr.py / pvr_flow / `_apply_canvas`。
- preview.png 由 librsvg 按 600 dpi 从 figure.svg 渲染（4323 x 2103 px）。
