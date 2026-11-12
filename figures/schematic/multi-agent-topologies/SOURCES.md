# multi-agent-topologies：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- Wu Q. et al. AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation (2023). https://arxiv.org/abs/2308.08155 , Fig. 1

只借用图型（版式思路），按通用流程重画；文字、示例和数值都是脚本写入的通用占位内容。论文标题、arXiv 号和图号沿用 `TARGETS.md`（S05，已核 ✓），本轮未上网复核，也未下载论文或任何期刊图。

## 图标来源

- 图标全部是 `build.py` 里 `Fig.icon()` 用矩形、椭圆和折线画的几何图形；没有位图、AI 生成图标、外部图标库或期刊原图；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 181 x 89 mm（4 x 2 格，43 mm 格 + 3 mm 间距）；字号 6-7.5 pt；线宽 0.5-1.2 pt。
- 颜色只用 house 色板及其浅色/深色派生，文字 #1A1A1A / #595959；直接标注，全部在画框内。
- 字体 Arial（回退 Liberation Sans）。preview.png 用 librsvg（ctypes 调用）按 600 dpi 由 figure.svg 渲染。
- 绘图工具段（drawing kit）逐字取自 `redraws/tree-of-thoughts-v2/build.py`（只读参考），figure 段为本图新写；未用 house.py / pvr.py / _apply_canvas。
