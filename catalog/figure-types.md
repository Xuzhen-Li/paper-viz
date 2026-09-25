# 常用图型 / Figure types

> **English Summary:** A short catalog of common paper figures. Each row names the chart, when to use it, and a recipe link when this repo already has one.

有 recipe 的写相对链接；没有的标「待写」。

## 差异分析

| 图型 | 何时用 | recipe |
|------|--------|--------|
| 火山图 volcano | 两组差异基因，同时看倍数和显著性 | [R](../figures/differential-expression/volcano/plot.R) · [Python](../figures/differential-expression/volcano/plot.py) |
| MA 图 | 看表达量与倍数的关系，检查低表达偏差 | 待写 |
| 分组箱线图 + 显著性 | 少数组的连续指标，要标两两比较 | [R](../figures/comparison/grouped-boxplot-signif/plot.R) |
| 分组柱状图 | 类别均值对比，组数少 | [Python](../figures/comparison/bar-grouped/plot.py) |
| 小提琴图 | 要看分布形状而不只看四分位 | 待写 |
| 分面小提琴 | 同一指标按第二个因子拆开 | 待写 |
| 云雨图 | 同时给原始点、密度和汇总 | 待写 |
| 哑铃图 | 两组前后或配对差值 | 待写 |
| 棒棒糖图 | 排序后的单指标，强调端点 | 待写 |
| 成对差异 / 配对连线 | 同一对象处理前后 | 待写 |
| 误差棒柱状图 | 均值加不确定度，重复数已定义 | 待写 |
| 蜂群图 | 点不多，又不想被箱线挡住 | 待写 |

## 生存与临床

| 图型 | 何时用 | recipe |
|------|--------|--------|
| Kaplan–Meier 曲线 | 时间-事件，比较分组生存 | [R](../figures/clinical/km/plot.R) |
| 森林图 | 多个研究或亚组的效应量和区间 | [R](../figures/clinical/forest/plot.R) |
| ROC | 二分类判别能力 | 待写 |
| 列线图 nomogram | 把回归系数变成个体风险 | 待写 |
| DCA 决策曲线 | 比较模型和默认策略的净获益 | 待写 |
| Oncoplot | 突变样本 × 基因的临床矩阵 | 待写 |
| 瀑布图 | 按效应大小排序的单样本变化 | 待写 |

## 组成与多样性

| 图型 | 何时用 | recipe |
|------|--------|--------|
| 堆叠柱状图 | 样本间组成比例 | 待写 |
| 饼图 / 环形图 | 一个总体的少数类别占比 | 待写 |
| 稀释曲线 | 测序深度是否够覆盖多样性 | 待写 |
| Alpha 多样性箱线 | 组间丰富度或均匀度 | 待写 |
| PCA | 连续变量的线性降维 | [Python biplot](../figures/dimension-reduction/pca-biplot/plot.py) |
| PCoA | 距离矩阵的主坐标 | [R](../figures/dimension-reduction/pcoa/plot.R) |
| NMDS | 距离矩阵的非度量排序 | [R](../figures/dimension-reduction/nmds/plot.R) |
| PLS-DA / OPLS-DA | 有监督的组间分离 | 待写 |
| t-SNE | 非线性嵌入，看簇不看轴解释 | 待写 |
| 三元图 | 三个组分的相对比例 | 待写 |
| STAMP 扩展误差条 | 两组分类单元的差异与区间 | 待写 |

## 相关性

| 图型 | 何时用 | recipe |
|------|--------|--------|
| 表达热图 | 基因 × 样本，看模块和分组 | [R](../figures/heatmap/heatmap/plot.R) |
| 相关性热图 | 变量两两相关，常加显著性 | 待写 |
| 散点 + 回归 | 两个连续变量的趋势 | 待写 |
| 折线 | 有序自变量上的轨迹 | [Python](../figures/correlation/line-basic/plot.py) |
| 网络图 | 相关或互作超过阈值的边 | 待写 |
| 气泡图 | 第三维用点大小编码 | 待写 |

## 基因组与进化

| 图型 | 何时用 | recipe |
|------|--------|--------|
| 曼哈顿图 | 全基因组关联的位点扫描 | [Plotly 草稿](../extras/web/interactive/plotly_manhattan.py) |
| Circos | 染色体间连锁、共线或互作 | 待写 |
| 基因结构 / 结构域 | 外显子、结构域沿转录本排列 | 待写 |
| 系统发育树 | 物种或基因的分支关系 | 待写 |
| 多序列比对 | 位点保守和差异 | 待写 |
| 共线性 / 点图 | 两条序列或两个基因组的对齐 | 待写 |

## 富集与通路

| 图型 | 何时用 | recipe |
|------|--------|--------|
| GO/KEGG 柱状图 | 少量通路的富集倍数或基因数 | 待写 |
| 富集气泡图 | 同时编码基因数、比例和显著性 | 待写 |
| GSEA | 排序基因列表上的通路偏移 | 待写 |
| 桑基图 | 类别之间的流量 | 待写 |
| 富集网络 | 通路共享基因时的连接 | 待写 |

## 流程与示意

| 图型 | 何时用 | recipe |
|------|--------|--------|
| 流程图 | 实验或分析步骤 | [schematic-design](../skills/schematic-design/SKILL.md) |
| 架构 / 时序图 | 模块关系和调用顺序 | [schematic-design](../skills/schematic-design/SKILL.md) |
| 论文原图重绘 | 栅格终图改成可编辑 draw.io | [drawio-source-redraw](../skills/drawio-source-redraw/SKILL.md) |
| 静态报告嵌图 | 把已有 PNG 嵌进 HTML | [build_report.py](../extras/web/static-embed/build_report.py) |
| 交互散点 | 需要悬停查看点身份 | [plotly_scatter.py](../extras/web/interactive/plotly_scatter.py) |

## 其他常见版式

| 图型 | 何时用 | recipe |
|------|--------|--------|
| 韦恩 / UpSet | 集合重叠；超过三组用 UpSet | 待写 |
| 雷达图 | 少量轴上的多对象轮廓 | 待写 |
| 地图 | 采样点或发病率的地理分布 | 待写 |
| 华夫图 | 用格子表示计数占比 | 待写 |
| 面积图 | 有序轴上的量能堆起来 | 待写 |
| 直方 / 密度 | 单变量分布 | 待写 |
| 所有uvial / 冲击图 | 分类随时间或步骤的去向 | 待写 |
