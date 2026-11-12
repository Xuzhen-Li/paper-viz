# hierarchical-memory：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- Packer C. et al. MemGPT: Towards LLMs as Operating Systems (2023). https://arxiv.org/abs/2310.08560 , Fig. 3（TARGETS.md S32）

图是该类方法的通用示意，版式为本脚本原创布局，不是对原图的描摹；文字是通用描述，没有抄录原文。论文、URL 和图号沿用 `TARGETS.md` 与任务书，本轮未上网复核，未下载论文或任何期刊图。

## 图标来源

- 图标全部由 `build.py` 用矩形、椭圆和折线画出；没有位图、没有 AI 生成图标、没有外部图标库或期刊原图；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 183 x 89 mm（4 x 2 格，43 mm 网格）；字号 6-7.5 pt；线宽 0.5-1.2 pt（分区 0.5、卡片/图标 0.8、主连线 1.2）。
- 颜色只用 house 色板及其 tint/dark 派生；字体 Arial（回退 Liberation Sans）；文字为 SVG `<text>`。
- 绘图工具段原样复制自 `redraws/tree-of-thoughts-v2/build.py`，另加两项检查：连线穿过文字、游离标签压框线。未用 house.py / pvr / `_apply_canvas`。
- preview.png 由 librsvg 按 600 dpi 从 figure.svg 渲染。
