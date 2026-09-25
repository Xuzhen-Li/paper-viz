---
name: viz-router
description: >-
  Route plotting/charting requests to the right skill so figures stay readable.
  Trigger on 画图、作图、配图、图表、chart、plot、可视化、dashboard、公众号图、论文图、选图、示意图.
  First hop: open a live gallery URL when the user is picking a look.
  Prefer nature-figure for manuscript data plots; schematic-design for
  architecture/flow/sequence HTML+SVG; draw.io for native .drawio or paper redraw.
---

# Viz Router（画图路由）

每次画图先走本路由，再 Read 目标 `SKILL.md`。不要把 viz-gallery 或 753 dump 当品味源。

## 路由表（硬规则）

| 场合 | 用哪个 | 路径 |
|------|--------|------|
| 选图 / 火山图 / 热图 / 配色 — 先打开别人的站 | **LIVE URL** | `python3 visualization/skill/query.py routes --need …` |
| 论文数据图 / Nature 向 / ggplot·matplotlib | **nature-figure** | `~/.cursor/skills/nature-figure/SKILL.md` |
| 架构 / 流程 / 时序 / 编辑示意图（HTML+SVG） | **schematic-design** | `~/.cursor/skills/schematic-design/SKILL.md` |
| 论文栅格重绘 / 原生 `.drawio` | **drawio** | `~/.agents/skills/drawio-skill/SKILL.md` |
| 公众号 / 汇报 / dashboard / 彩色 HTML 页 | **visualize-html** | `~/.cursor/skills/visualize-html/SKILL.md` |
| 明确要单色编辑感 / Lupi / 年报海报灰阶 | **lieflat-charts** | `~/.cursor/skills/lieflat-charts/SKILL.md` |

**默认（用户没指定风格）：**

1. 「找一张火山图/热图长什么样」→ `query.py routes`，打开 LIVE URL
2. 「自己画」论文数据图 → `nature-figure`（先问 Python or R）
3. 架构 / 流程 / 时序 → **schematic-design**（不要用 bar/line 代替 volcano）
4. 其它「做成好看的图/页」→ `visualize-html`
5. 仅当用户说「单色 / Lupi / lieflat / 编辑灰阶」→ `lieflat-charts`

## 关于给 lieflat 加颜色

lieflat 的产品定义就是 **Mono 灰阶**（`mono-tokens.js`）。需要彩色时换 `visualize-html`，不要 internally 当默认。

## 每次交付自检

- [ ] 读过目标 skill 的 SKILL.md
- [ ] 选图任务打开了 LIVE URL，没有 clone
- [ ] 数据图没有用 schematic-design 的示意图资产冒充 volcano/heatmap
- [ ] 没有再把示意图指到第三方 `diagram-design` 入口

## 本库笔记

见 `AI_lib/ai-use-note/tools/viz-skills-routing.md`。Fork 说明：`visualization/references/diagram-design-fork.md`。
