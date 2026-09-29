# Hybrid Editable SVG

关键不是“把整张图矢量化”，而是做成一种 Hybrid Editable SVG（混合可编辑 SVG）：

- 版式、框、箭头、文字 = 真正 SVG
- 复杂图标、科研小图 = 从参考图精准提取的透明高清 PNG
- 最后所有 PNG 直接嵌入 SVG，变成一个单文件

这也是最后那个 Pixelmator 单文件版比前面几版好的原因。

以后不要只说“帮我矢量化”。应该说：

> 请做 Hybrid Editable SVG：结构和文字原生 SVG；复杂科学图标及图表从原图精准提取成透明高清独立图层；最后全部 base64 嵌入单文件 SVG，并实际渲染验证。

适合 SCI graphical abstract、workflow、bioinformatics pipeline，以及 Pixelmator Pro。

## 1. 成功采用的技术路线

### 1. 先锁定原图尺寸和布局

参考图如果是 1746 × 950 px，SVG 必须严格：

```xml
<svg
  xmlns="http://www.w3.org/2000/svg"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  width="1746"
  height="950"
  viewBox="0 0 1746 950">
```

不重新设计，不改变四栏比例。四栏是 INPUT、PROCESSING、ANALYSIS、REPORT。

外层布局重新用 SVG：`<rect>`、`<path>`、`<line>`、`<polygon>`、`<text>`。这些东西都不要截图。

如果手头的参考图不是 1746 × 950，宽高跟那张参考图走，保持同一长宽比。`converted-600dpi.pdf` 的页面是 4096 × 2308。

### 2. 把真正难画的部分从参考图精准提取

不要手工重绘这些小图标，否则形状走样、线条奇怪、比例不一致：

QC、Relatedness、PCA、ADMIXTURE、NJ、Damage pattern、GWAS / Selection、f3 / f4、Site annotation、Overlapped。

REPORT 里面也不要重新模拟，全部优先精准 crop：

- PCA scatter
- ADMIXTURE plot
- heatmap
- phylogenetic tree
- Manhattan plot
- damage curve
- site annotation tracks
- overlap / Venn
- geographic map
- scatter / regression

### 3. 去背景时不能简单删除所有白色

`白色 → transparent` 会吃掉图内部的白色，比如 heatmap 浅色格子、PCA 背景、tree 内部、document icon 内部。

只删除和裁图边缘连通的浅色背景，类似 Photoshop 的“选择连续背景”：

```
从图片四周开始 flood fill
    ↓
判断像素是不是接近背景颜色
    ↓
只把与边界连通的背景设为 alpha=0
    ↓
内部白色区域保留
```

判定：

```
abs(R - background_R) < threshold
abs(G - background_G) < threshold
abs(B - background_B) < threshold
```

threshold 在 15–35 之间按每张图调。这一步比 “remove all white pixels” 重要得多。

### 4. crop 完以后再放大

```
crop
  ↓
去背景
  ↓
trim transparent margin
  ↓
3×–6× upscale（Image.Resampling.LANCZOS）
  ↓
PNG RGBA
```

AI 重建是第二选择，精准 crop 是第一选择。参考图本身已经是 4096 宽时，小图不必再放大到糊，够清晰即可。

### 5. SVG 本身只负责版式

SVG 负责：panel、title、text、border、arrow、bracket、spacing、card、separators、background、gradient。

小图只负责 `<image>`。一个图坏了，只替换这一张 PNG。

### 6. 文字永远重新输入

绝对不要把 ANALYSIS、QC、Relatedness、PCA 矢量描摹成 path。必须是 `<text>`，这样 Pixelmator / Illustrator 里还能改字。

```xml
<text
   x="925"
   y="147"
   font-family="Arial, Helvetica, sans-serif"
   font-size="22"
   font-weight="600"
   fill="#15345b">
   QC
</text>
```

### 7. 最后把所有 PNG 塞进 SVG 本体

`href="assets/qc.png"` 在 Pixelmator 里会找不到旁边的素材。成功版用：

```
href="data:image/png;base64,..."
```

最终一个文件，例如 `GrapeAncestry_Pixelmator_singlefile.svg`，不再需要 `assets/`。

### 8. 最终必须进行真实渲染测试

不要生成完 SVG 就交付。

```bash
inkscape GrapeAncestry_Pixelmator_singlefile.svg \
    --export-type=png \
    --export-filename=preview.png
```

渲染结果应和参考图同一尺寸，没掉图、没乱码、没错位，再交付。成功那版大约是 embedded 27 assets，SVG ≈ 2.2 MB，preview = 1746 × 950。

XML 没报错 ≠ 图是对的。要同时满足：SVG 能解析、能渲染、渲染视觉正确。

## 2. 交给模型的完整要求

You are reconstructing a scientific graphical abstract into a Pixelmator-Pro-compatible editable SVG.

I will provide ONE reference PNG.

Your goal is NOT to redesign it.

Your goal is high-fidelity reconstruction.

### Final deliverable

Create `GrapeAncestry_Pixelmator_singlefile.svg`.

The SVG must:

1. Have exactly the same aspect ratio as the supplied reference.
2. Use `width="1746"` `height="950"` `viewBox="0 0 1746 950"` if the supplied reference image is 1746 × 950.
3. Open directly in Pixelmator Pro without requiring an external assets directory.
4. Preserve editable SVG elements wherever practical.
5. Preserve all text as real SVG `<text>` elements.
6. Embed all raster assets INSIDE the SVG as base64 PNG data URIs.
7. Do NOT embed the entire reference image as one image.
8. Do NOT convert the whole figure into one giant path.
9. Do NOT vector-trace the text.
10. Do NOT redesign the composition.

### Design strategy

VECTOR ELEMENTS — reconstruct as native SVG:

- four main background panels
- panel headers
- rounded rectangles
- borders
- separators
- arrows
- arrowheads
- analysis bracket
- lines
- text
- labels
- background fills
- panel gradients
- cards
- reference-data container
- Interactive badge if it can be reproduced cleanly

RASTER ELEMENTS — complex scientific icons and mini-plots:

Do NOT manually redraw them unless the result is essentially exact.

1. Precisely crop them from the supplied reference image.
2. Remove only the external connected background.
3. Preserve all internal colors and details.
4. Trim transparent margins.
5. Upscale the isolated item using high-quality Lanczos interpolation.
6. Save as transparent RGBA PNG.
7. Insert each as an independent SVG `<image>` object.

Each scientific item must remain independently moveable and resizable.

### Background removal

Do NOT simply make every white or beige pixel transparent. That destroys internal light-colored regions of plots.

Use connected-component / flood-fill background removal:

- Estimate the local background color from the crop corners.
- Begin flood fill from the crop boundaries.
- Pixels sufficiently close to the background color are background.
- Only delete pixels connected to the outer edge.
- Retain interior white or light-colored pixels.
- Use a tolerance roughly 15–35 RGB levels, tuned per crop.
- Feather only 0–1 pixel if necessary.

Output must retain smooth antialiased edges.

### Structure

Four vertical panels: INPUT, PROCESSING, ANALYSIS, REPORT. No overall figure title.

INPUT — blue panel. Three vertically aligned file stacks: FASTQ, BAM, VCF. Preserve the paper-stack graphic and short horizontal-line content.

Arrows:

- FASTQ → Trim
- BAM → Markdup
- VCF → central VCF box
- There must NOT be a BAM → Trim connection.

PROCESSING — green panel. Vertical aligned workflow:

```
Trim
↓
MAP
↓
Markdup
↓
bcftools
SNP calling
↓
VCF
```

Trim side label:

```
PE: fastp
SE (aDNA):
AdapterRemoval
```

MAP side label:

```
VS-1
genome
```

Below the VCF box: `GrapeAncestry` / `target sites`, with an arrow pointing upward into VCF.

All processing boxes should be vertically aligned and centered. Use the same x-center wherever possible.

ANALYSIS — warm sand / beige panel. A vertical bracket enters from the central VCF. Ten modules, exactly:

1. QC
2. Relatedness
3. PCA
4. ADMIXTURE
5. NJ
6. Damage pattern
7. GWAS / Selection
8. f3 / f4
9. Site annotation
10. Overlapped

Every analysis row uses the same visual grammar: `[icon] | [title]`. Icon on the left, thin vertical divider, title on the right. Do NOT place full scientific plots inside the Analysis rows. Use the isolated scientific icon extracted from the reference. Keep all row dimensions identical.

At the bottom: `Reference data (used in analysis)`, four small cards:

- core / genotypes
- PCA / ADMIXTURE / references
- VIVC / passport
- OIV / descriptors

REPORT — rose / light red panel. Top-right badge: `Interactive`. The REPORT section contains scientific mini-figures, not labels, extracted directly from the reference, in approximately a 2-column grid:

- PCA scatter plot
- ADMIXTURE stacked bars
- relatedness heatmap
- phylogenetic tree
- GWAS / Manhattan plot
- damage pattern curve
- site annotation tracks
- overlap / Venn visualization
- geographic map visualization
- scatter / regression visualization

Do NOT simplify these plots into rough icons.

### Typography

Real `<text>` elements. Preferred font: Arial, Helvetica, or another modern sans-serif fallback. Do not convert text to paths. Dark navy text matching the reference. Panel headings INPUT, PROCESSING, ANALYSIS, REPORT are large bold white sans-serif.

### Color palette

Match the reference. Approximate categories:

- INPUT: soft blue
- PROCESSING: sage / soft green
- ANALYSIS: warm sand / beige
- REPORT: muted rose / red
- Main dark line/text: deep navy

Do not use pure black unless the source explicitly contains it.

### SVG organization

Groups with ids:

```xml
<g id="input-panel">
<g id="processing-panel">
<g id="analysis-panel">
<g id="report-panel">
```

Nested groups such as `analysis-qc`, `analysis-relatedness`, `analysis-pca`, `report-pca`, `report-admixture`.

### Single-file requirement

The final SVG must not contain `href="assets/..."`. Every image href is `data:image/png;base64,...`. The only file to open is `GrapeAncestry_Pixelmator_singlefile.svg`.

### Quality control

1. Parse the SVG as XML.
2. Confirm there are no missing image references.
3. Confirm every image is embedded.
4. Confirm the reference PNG itself is NOT embedded as a whole.
5. Confirm text is still `<text>`.
6. Render the SVG to PNG using Inkscape, librsvg, Chromium, or another SVG renderer.
7. Confirm the rendered PNG matches the SVG size.
8. Compare the render with the supplied reference.
9. Correct obvious spacing, arrow, panel-width, icon-position, text-position, and plot errors.
10. Only then deliver.

Also deliver `GrapeAncestry_Pixelmator_singlefile_preview.png`.

### Do not

- redesign
- beautify beyond the source
- invent additional analyses
- change arrow directions
- change scientific labels
- add a title
- omit any analysis
- turn the whole reference into one embedded PNG
- manually approximate complex report plots
- create crude replacement icons
- flatten text
- convert everything to paths
- depend on external assets

Priority:

1. Scientific correctness
2. Visual fidelity to the reference
3. Correct arrows and relationships
4. Pixelmator compatibility
5. Editability
6. Clean SVG structure

### 最重要的经验

The previous attempts failed because the model tried to redraw tiny scientific icons and report plots from scratch.

Do not repeat that mistake.

When a small icon or scientific plot is visually complex, fidelity is more important than forcing it to be vector.

Precisely extract the element from the reference image, remove its outer background, upscale it, and embed it as an independent raster layer inside the otherwise editable SVG.

The SVG should be structurally editable, not dogmatically 100% vector.

## 3. 边缘连通去背景

只删除与外部边缘连通的背景，而不是 `if pixel is white: alpha = 0`。

```python
from collections import deque

import numpy as np
from PIL import Image


def remove_connected_background(input_path, output_path, tolerance=25, upscale=4):
    im = Image.open(input_path).convert("RGBA")
    arr = np.array(im)
    rgb = arr[:, :, :3].astype(np.int16)
    height, width = rgb.shape[:2]
    corners = np.array([
        rgb[0, 0],
        rgb[0, width - 1],
        rgb[height - 1, 0],
        rgb[height - 1, width - 1],
    ])
    background = np.median(corners, axis=0)
    diff = np.abs(rgb - background)
    candidate = np.max(diff, axis=2) <= tolerance
    visited = np.zeros((height, width), dtype=bool)
    queue = deque()
    for x in range(width):
        if candidate[0, x]:
            queue.append((0, x))
        if candidate[height - 1, x]:
            queue.append((height - 1, x))
    for y in range(height):
        if candidate[y, 0]:
            queue.append((y, 0))
        if candidate[y, width - 1]:
            queue.append((y, width - 1))
    while queue:
        y, x = queue.popleft()
        if visited[y, x] or not candidate[y, x]:
            continue
        visited[y, x] = True
        arr[y, x, 3] = 0
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < height and 0 <= nx < width and not visited[ny, nx]:
                queue.append((ny, nx))
    out = Image.fromarray(arr)
    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    if upscale > 1:
        out = out.resize((out.width * upscale, out.height * upscale), Image.Resampling.LANCZOS)
    out.save(output_path)
```

## 4. 把素材嵌进 SVG

```python
import base64
import mimetypes
import re
from pathlib import Path

root = Path("project")
svg_path = root / "GrapeAncestry.svg"
svg = svg_path.read_text(encoding="utf-8")
pattern = re.compile(r'href="(assets/[^"]+)"')


def embed(match):
    rel = match.group(1)
    asset = root / rel
    data = asset.read_bytes()
    mime = mimetypes.guess_type(asset.name)[0] or "application/octet-stream"
    encoded = base64.b64encode(data).decode("ascii")
    return f'href="data:{mime};base64,{encoded}"'


svg_path.with_name("GrapeAncestry_Pixelmator_singlefile.svg").write_text(
    pattern.sub(embed, svg),
    encoding="utf-8",
)
```

原来的 `<image href="assets/qc.png"/>` 会变成 `<image href="data:image/png;base64,iVBORw0KGgoAAA..."/>`。同时写上 `xlink:href`，老版本 Pixelmator / Illustrator 才认。

## 5. 渲染检查

```bash
inkscape GrapeAncestry_Pixelmator_singlefile.svg \
  --export-type=png \
  --export-filename=GrapeAncestry_preview.png
file GrapeAncestry_preview.png
```

应看到与 SVG `width` / `height` 一致的 PNG，再打开 preview 人眼检查。
