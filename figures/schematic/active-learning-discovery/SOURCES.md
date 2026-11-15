# active-learning-discovery（v2）：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- Merchant A. et al. Scaling deep learning for materials discovery (2023). https://www.nature.com/articles/s41586-023-06735-9 , Fig. 1 [待确认]

只借用版式思路，未描摹原图；所有标签为通用名称，不含真实材料名或化学式，数量与命中率没有画。标题、URL 与图号沿用 `TARGETS.md`（S41），Fig. 1 [待确认] 原样保留（裁定里的 Fig. 1a 只留给以后的 catalog，本目录不写成已确认）；本轮未上网复核，未下载论文、补充材料或任何期刊图。

## 图标来源

- 图标都由 `build.py` 用矩形、椭圆和折线画出（kit 的 `Fig.icon()` 与本图的 `g_*` 函数）；无位图、无外部图标库、无 AI 生成图标；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 183 x 89 mm（4 x 2 格，全宽导出约定）；字号 6-7.5 pt；线宽 0.5-1.2 pt；house 色板及其派生色；字体 Arial（回退 Liberation Sans）；preview.png 由 librsvg 按 600 dpi 渲染 figure.svg。
- 绘图 kit 复制自 `redraws/tree-of-thoughts-v2/build.py`（未改原文件），未使用 house.py、pvr.py、pvr_flow 或 `_apply_canvas`。

## v2 改动（只改内容 ①-4.1；v1 目录未改）

- 组成路线改为：新组成（放宽氧化态规则）→ GNoME 组成模型过滤（输入是约化化学式，无结构）→ 过滤之后用 AIRSS 为每个保留组成初始化 100 个随机结构 → DFT。过滤之前不再出现 random structures。
- 过滤区画成两个图网络模型：上泳道组成模型、下泳道结构模型；结构路线仍是替换 → 结构 GNN 过滤 → DFT。
- 两条回边保持 v1 原样：全部新 DFT 标签回灌重训过滤（「retrain on all new DFT labels」）；稳定结果作为下一轮替换的种子。
- 顺带吸收 ② 4.4：替换卡片写「partial substitutions (SAPS) in known structures」。未吸收 ② 4.2（聚类 / 多晶型排序），以免把它错放到组成路线上。
- 顺带吸收版式 ②-3：第 4 栏收窄，底部空带改由两条回路和脚注占用；画布仍 183 x 89 mm。
