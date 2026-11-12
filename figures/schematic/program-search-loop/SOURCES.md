# program-search-loop（v1）：来源说明

## 方法来源（只写 URL + 图号，不附原图，未描摹原图）

- Romera-Paredes B., Barekatain M. et al. Mathematical discoveries from program search with large language models. Nature 625, 468-475 (2024; published online 2023-12-14). https://www.nature.com/articles/s41586-023-06924-6 , DOI 10.1038/s41586-023-06924-6 , Fig. [待确认]

图号按 `TARGETS.md`（S22：Fig. 1 [待确认]）写成 `Fig. [待确认]`，本轮未确认。只借用图型（流程闭环），节点文字取自论文正文/摘要的文字描述，没有下载、保存、复制或描摹任何期刊图，也没有用到论文里的数值。

读过的本地文字（已在盘上，只读，未复制图片）：

- `paper-viz/lit_selection/raw/xref/10_1038_s41586_023_06924_6.json`：摘要（FunSearch = 函数空间里的进化搜索，预训练 LLM 配系统化评估器；搜索"怎么解"的程序而非解本身；程序更可解释；cap set 与 online bin packing）。
- `paper-viz/internal_refs/html/nat_10.1038_s41586-023-06924-6.html`：只抽正文与图注文字（FunSearch 概述段、Specification、Prompt、Evolutionary method and program selection、Programs database、Distributed approach、Extended Data Fig. 1/2 图注文字）。

## 节点与论文文字的对应

| 图中节点 / 连线 | 论文文字依据（意译） |
|---|---|
| Function to evolve（初始版本可很简单） | 输入包括要进化的函数的初始实现，可以是 trivial 的 |
| Skeleton (optional)，solve() | 可选把 solve 写成骨架（样板代码 + 已知结构），只进化关键函数（如 priority） |
| evaluate() | 问题规格以 evaluate 函数给出，为候选解打分 |
| Programs database / islands | 程序库保存正确程序的种群；岛屿模型，各岛独立进化；先抽岛、再在岛内抽程序，偏向高分、较短程序；周期性清掉最差一半岛屿，用存活岛屿的最佳程序克隆重建 |
| Prompt（best-shot，k 个程序按分数排序） | best-shot prompting：从一个岛抽 k 个程序，按分数排序并编号 v0、v1… 合成一个提示 |
| Pretrained LLM（sampler） | 提示送入预训练（冻结）LLM 生成新程序；sampler 用预训练 LLM 生成新函数 |
| Evaluator（运行 main()、打分、丢弃错误） | evaluator 在用户给定输入上执行 main 并打分；超时、超内存或输出无效的程序被丢弃 |
| scored programs (if correct) 写回 | 新程序打分后若正确则存入程序库，闭环 |
| Best programs / retrieve | 用户可随时取出目前最高分的程序 |
| Interpretable | 程序描述"怎么解"而非"解是什么"，比原始解更可解释 |
| samplers and evaluators run asynchronously | 分布式实现：程序库、sampler、evaluator 三类 worker 异步通信、并行 |

未加入 AlphaEvolve 等后续方法才有的部件（MAP-Elites、diff 编辑、LLM 评审、失败重试、Gemini 等）。

## 图标来源

- 图标全部是 `build.py` 里 `Fig.icon()` 用矩形、椭圆和折线画的几何图形（code、doc、check、db、chip、gear）；没有位图、AI 生成图标、外部图标库或期刊原图；figure.svg 不含 `<image>`、`data:image/` 或 `<foreignObject>`。

## 版式

- 画布 183 x 89 mm；字号 6-7.5 pt（无上标、无 mathtext）；线宽 0.5-1.2 pt。
- 颜色只用 house 色板（blue、purple、orange、green、red、灰）及其 tint()/mid()/dark() 派生色；所有文字为 #1A1A1A / #595959，不用色板色作文字；文字对比度脚本检查 >= 4.5:1。直接标注，全部在画框内。
- 字体 Arial（回退 Liberation Sans）。preview.png 用 librsvg 按 600 dpi 由 figure.svg 渲染。
- 绘图工具段（drawing kit）逐字取自 `redraws/event-stream-runtime-v2/build.py`（即 `redraws/tree-of-thoughts-v2/build.py` 的工具段 + 连线穿字检查，只读参考），figure 段为本图新写；未用 house.py / pvr.py / _apply_canvas。
- 与 S21 `evolutionary-llm-search-loop`（matplotlib 2x1 版）只作版式对照，未复制其文件。
