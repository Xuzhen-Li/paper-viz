# tree-of-thoughts（v2）：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- Yao S. et al. Tree of Thoughts: Deliberate Problem Solving with Large Language Models (2023). https://arxiv.org/abs/2305.10601 , Fig. 1（ToT 树状展开）；生成/评价/BFS/DFS 三步见正文方法部分 [待确认 节号]

图中步骤是该类方法的通用流程，不是某篇论文独有的定名流程；文字由脚本写入，未增加原文没有的方法步骤。论文标题、arXiv 号和图号沿用 `TARGETS.md`（2026-11-12 冲刺清单）的核对结果，本轮未再上网复核，也未下载论文或任何期刊图。

## v2 相对 v1 的改动（方法审 ①-1）

- 左侧示例树只示一种搜索：广度优先、beam b = 2，图上左上角标 `Example: BFS, b = 2`。
- 去掉死路标记和回溯箭头。
- 每层按 v 排序保留前 2 名，其余剪枝且不展开：第 1 层 {0.9, 0.6, 0.2} 留 0.9、0.6；第 2 层 {0.8, 0.4, 0.3, 0.1} 留 0.8、0.4；第 3 层 {0.95, 0.7, 0.3} 留 0.95、0.7；最后取 v 最高的 0.95 输出。每个被剪节点的 v 都严格低于同层所有被保留的节点。
- 右栏三步（Generate / Evaluate / Search）文字未改。
- v1 目录 `redraws/tree-of-thoughts/` 原样保留，未改动。

## 图标来源

- 本图没有用图标；节点和卡片都是 `build.py` 脚本画的矩形和文字。`build.py` 里的 `Fig.icon()` 只用矩形、椭圆和折线画图形。
- 没有使用 AI 生成的位图图标，没有使用任何外部图标库或期刊原图；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 183 x 89 mm（4 x 2 格）；字号 6-7.5 pt（分区标题 7.5、卡片标题 7、正文 6.5、注释 6）；线宽：分区外框 0.5 pt、卡片 0.8 pt、主连线 1.2 pt、次要连线 0.8 pt。
- 颜色只用 house 色板（#1F72AE #F77E12 #119B76 #595594）及其浅色/深色派生，文字 #1A1A1A；直接标注，全部在画框内。
- 字体 Arial（回退 Liberation Sans）。preview.png 用 librsvg（ctypes 调用）按 600 dpi 由 figure.svg 实际渲染。
