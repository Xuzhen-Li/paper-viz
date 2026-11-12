# planner-state-machine v2：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- Huang K. et al. CRISPR-GPT: An LLM Agent for Automated Design of Gene-Editing Experiments (2024). https://arxiv.org/abs/2404.18021 , Fig. 1 / Fig. 3

本轮未上网复核，也未下载论文或任何期刊图；内容按方法专家审查意见（①-1）的转述改写。

## 相对 v1 的内容改动（v1 目录未改动）

- 删除 v1 右栏的 S3「LLM checks against task requirements」和 pass / 「fail: revise inputs → S1」校验—重试环；不再把 LLM 画成审核器。
- 右栏改为状态链 Start → State 1 → State 2 → … → State n → Next task；放大框画出「每个状态 = 一轮交互」：1 说明并索取所需输入 → 2 用户或代用户的 LLM agent 回复 → 3 输出与反馈（状态内可调用工具）→ 下一状态。
- 顶部新增「Human user supervises the whole process / can correct any state or take over」，绿色虚线箭头指向各状态。
- 左栏四个通用任务（Task 1-4）与 v1 相同；工具区标题由「used by tool states, e.g. S2」改为「called inside a state」。不含真实基因名或编辑靶点。

## 图标来源

- 图标全部是 `build.py` 里 `Fig.icon()` 用几何图形画的；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 181 x 89 mm；字号 6-7.5 pt；线宽 0.5-1.2 pt；house 色板及派生色。
- 绘图工具段（drawing kit）逐字取自 v1 `build.py`（v1 取自 `redraws/tree-of-thoughts-v2/build.py`），figure 段为本版新写；未用 house.py / pvr.py / _apply_canvas。
