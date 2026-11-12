# ai-scientist-loop（v2，改法 A）：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- 主来源：Lu C. et al. The AI Scientist: Towards Fully Automated Open-Ended Scientific Discovery (2024). https://arxiv.org/abs/2408.06292 , Fig. 1（想法 -> 写代码/跑实验 -> 写论文 -> 自动评审 -> 存档，开放式反复）
- 相关（非本图来源）：Ghareeb A. E. et al. Robin: A multi-agent system for automating scientific discovery (2025). https://arxiv.org/abs/2505.13400 , Fig. 1（假说-实验-再假说；含湿实验，本图不画）

本图按 Primary 选定的改法 A 保留 AI Scientist 定位。环内步骤依据方法审报告（`reviews/methods_expert_agent_schematics_review_v1.md` ①-2）所引 arXiv 2408.06292 摘要原文：“generates novel research ideas, writes code, executes experiments, visualizes results, describes its findings by writing a full scientific paper, and then runs a simulated review process for evaluation ... repeated to iteratively develop ideas in an open-ended fashion and add them to a growing archive of knowledge”。Idea 卡上的 “check novelty” 与起点 “code template” 按 Fig. 1 的通常读法写入 [待确认：本轮未打开原文核对 Fig. 1 细节]。论文标题、arXiv 号和图号沿用 `TARGETS.md` S10；本轮未上网复核，未下载论文或任何期刊图。

## v2 相对 v1 的改动（方法审 ①-2，改法 A）

- 环内依次为 Idea（提出想法、查新）-> Experiments（write code, run computational experiments）-> Write paper -> Automated review（LLM 评审打分）-> Archive（想法、论文、评分的增长存档）-> next idea。
- 删去 `run lab experiments`；写作不再画在环外，删去 `Findings` / `write up` / `if conclusive` 出口。
- 终止条件写作 “repeat until the compute budget is spent”（顺带处理 ②-10）。
- 版式不再用 reflexion-cycle 的 2 x 2 环 + 左入口 + 右出口：改为上排四步横向流水线 + 下方通栏存档条，评审 -> 存档 -> 下一轮想法构成回路；没有 pass/fail 分支，也没有“反思”步（顺带处理 ②-13）。
- v1 目录 `redraws/ai-scientist-loop/` 原样保留，未改动。

## 图标来源

- 全部图标（文档、灯泡、代码括号、对勾、数据库）由 `build.py` 里的 `Fig.icon()` 用矩形、椭圆和折线脚本自绘；代码括号 `code` 为 v2 新增的折线图形。
- 没有使用 AI 生成的位图图标，没有使用任何外部图标库或期刊原图；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 183 x 89 mm（4 x 2 格）；字号 6-7.5 pt（分区标题 7.5、卡片标题 7、正文 6.5、注释 6）；线宽：分区外框 0.5 pt、卡片 0.8 pt、主连线 1.2 pt、图标 0.8 pt。
- 颜色只用 house 色板（#1F72AE #F77E12 #119B76 #595594 #62B4E7）及其浅色/深色派生，文字 #1A1A1A；直接标注，全部在画框内。
- 字体 Arial（回退 Liberation Sans）。preview.png 用 librsvg（ctypes 调用）按 600 dpi 由 figure.svg 实际渲染。
