---
name: drawio-source-redraw
description: Reconstructs paper or legacy raster figures as source-aligned, editable draw.io diagrams. Use when the user asks for a same-look redraw, pixel-aligned redraw, raster-to-drawio conversion, tight icon crops, native-first editing, or precise connector and typography matching.
---

# Source-Figure Draw.io Redraw

## English Summary

Companion to the official draw.io agent skill. It preserves the source figure's coordinate frame, keeps panels/text/edges editable, and rasterizes only paper-specific artwork that has no faithful native draw.io equivalent.

The method was validated on MATA Fig.1 from [arXiv:2602.09642](https://arxiv.org/abs/2602.09642). Keep the source figure read-only. Write diagrams, sprites, manifests, tests, and QC next to the working file, not over the original raster.

## Non-negotiable goals

1. **Source fidelity first:** use the original raster as the visual reference, not a rough flowchart interpretation.
2. **Native-first editability:** panels, labels, text, tables, callouts, cylinders, server racks, and connectors should remain editable when draw.io can represent them adequately.
3. **Minimal rasterization:** crop only identity-bearing or paper-specific artwork; never embed the whole source figure as the final diagram layer.
4. **Coordinate determinism:** record source boxes and routes explicitly; do not compensate for a global error with many local offsets.
5. **Evidence and regression:** compare source and redraw in the same coordinate frame, then run structural validation and small regression tests.

## Workflow

### 1. Freeze the source frame

- Read the original image and record its exact pixel dimensions.
- Set `mxGraphModel.pageWidth` and `pageHeight` to the source dimensions.
- Keep all important vertex and route coordinates in source pixels.
- Do not resize panels into a hand-built canvas before the first comparison.
- For source-aligned preview exports, use:

```bash
drawio -x -f png --size page --width 2000 -o redraw.png input.drawio
```

The default draw.io `diagram` export crops to diagram content and changes the visible origin. That crop can make every correctly source-positioned element look globally shifted. Use `--size page` for calibration; use the default cropped export only when a cropped presentation image is explicitly desired.

### 2. Audit native draw.io capability

Before cropping anything:

1. List the visible elements: panels, tabs, text blocks, tables, callouts, icons, widgets, and routes.
2. Search the official shape index with `shapesearch.py` instead of guessing style strings.
3. Classify each element:
   - **Native:** visually adequate and editable.
   - **Native approximation:** editable but visibly different; use only if exact artwork is not required.
   - **Fine sprite:** no faithful native equivalent.
4. Record the decision in an element inventory.

Do not turn a complex paper illustration into one large screenshot merely because it is faster.

### 3. Build a tight sprite manifest

For every fine sprite, record:

- `source_box`: the original source-coordinate crop.
- `trim_offset`: the non-transparent component bounds within that crop.
- `output_size`: the actual RGBA sprite dimensions.
- `role` and whether panel/connector colors were removed.

Crop with vision guidance when the component boundary is ambiguous. Then:

- remove uniform panel fills and connector colors only when they are not part of the artwork;
- preserve anti-aliased edges and transparency;
- trim to the visible component;
- inspect a contact sheet at 100% scale;
- test RGBA mode, dimensions, non-empty alpha, and transparent corners.

The manifest is the source of truth for placement. Do not hand-enter a second, conflicting crop coordinate in the generator.

### 4. Generate from a deterministic builder

Use a Python builder when the redraw contains more than a few calibrated elements:

- start from a known base only when its source-coordinate geometry is understood;
- use stable cell IDs and helper functions for vertices, images, text, and edges;
- remove coarse raster cells explicitly;
- keep native, sprite, text, and edge layers distinguishable;
- regenerate the `.drawio` file after each layout change;
- make changes in the generator rather than manually patching the generated XML.

Read the official XML authoring reference before hand-writing cells:
[`xml-authoring.md`](../drawio-skill/references/xml-authoring.md).

### 5. Route connectors from source centerlines

Do not rely on draw.io's automatic router for a source-matching redraw.

1. Isolate connector colors in the source image.
2. Inspect straight and orthogonal segments at high resolution.
3. Record explicit source-point, waypoint, and target-point coordinates.
4. Add arrowheads only where the source has them.
5. Recheck every route after moving or resizing a target shape.

For crowded branches, use absolute `<mxPoint>` waypoints. A passing XML validator does not prove that a connector visually matches the source.

### 6. Calibrate typography separately

Native text is usually the largest remaining source of visual drift.

- Measure each source text block's visible bounds with vision or OCR.
- Set the cell box, font size, alignment, vertical anchor, and line breaks deliberately.
- Split multi-line labels into separate editable cells when one wrapped cell produces the wrong line spacing.
- Widen cells before increasing font size if a label wraps unexpectedly.
- Check for clipping behind callouts, icons, panels, or neighboring labels.
- Compare source and redraw after scaling both to the same page frame.

Do not assume a source pixel font size equals draw.io's `fontSize` value. Render, measure, and retune.

### 7. Run the visual QC loop

Review in this order:

1. global page origin and scale;
2. panel and major shape anchors;
3. sprite boxes;
4. native text bounds and line breaks;
5. connector centerlines and arrowheads;
6. colors, strokes, and small custom widgets.

Useful QC artifacts:

- source/redraw alpha blend;
- source connector mask versus redraw route overlay;
- per-region side-by-side crops;
- OCR or component-bound measurements for text and colored widgets.

Fix a global transform before applying local offsets. If three local alignment passes fail, question the coordinate/export architecture instead of adding a fourth set of offsets.

### 8. Validate before presenting

Run all of the following when available:

```bash
python3 ai-use-note/skills/drawio-skill/scripts/validate.py input.drawio
python3 path/to/test_assets.py
```

Minimum regression coverage for a source redraw:

- source boxes fit within the source image;
- sprites are RGBA and match their manifest;
- important anchors have expected coordinates;
- critical routes have expected waypoints;
- custom cells and required editable labels exist;
- no duplicate IDs or structural errors.

Layered panels and their children may produce intentional overlap warnings. Report the count, but never hide structural errors or use warnings as proof of visual correctness.

### 9. Export only after approval

Preview/self-check export: no `-e`, width capped, `--size page` for source-aligned work.

Final editable PNG export:

```bash
drawio -x -f png -e -s 2 -o diagram.drawio.png input.drawio
python3 ai-use-note/skills/drawio-skill/scripts/repair_png.py diagram.drawio.png
```

SVG/PDF exports can use `-e` without the PNG repair step. Open the `.drawio` file in the desktop app for the user's final inspection.

## Anti-patterns learned from MATA Fig.1

- A `raster2drawio` skeleton can be structurally valid while visually unusable.
- A whole-figure PNG makes the result look exact but destroys the requested editability.
- Rough contour crops capture labels, panel fills, or connector fragments.
- Default diagram-content export can masquerade as a layout error.
- Moving icons without moving their labels and edge endpoints creates cascading drift.
- Increasing font size without widening the cell causes new wrapping and clipping.
- Replacing a custom score table or crossed-tools mark with an unrelated native glyph can be less faithful than a tiny transparent crop.
- A legacy script is a clue, not a trusted coordinate or style source.

## MATA case-study references

- Canonical redraw: [`visualization/drawio/redraws/mata-fig1-source-aligned-native-first.drawio`](../../../visualization/drawio/redraws/mata-fig1-source-aligned-native-first.drawio)
- Builder: [`build_native_first.py`](../../../visualization/drawio/assets/mata-fig1/_vision/build_native_first.py)
- Asset manifest: [`manifest.json`](../../../visualization/drawio/assets/mata-fig1/assets-fine-v4/manifest.json)
- Regression tests: [`test_assets_fine.py`](../../../visualization/drawio/assets/mata-fig1/_vision/test_assets_fine.py)
- Element audit: [`element-inventory.md`](../../../visualization/drawio/assets/mata-fig1/element-inventory.md)
- Pipeline notes: [`PIPELINE.md`](../../../visualization/drawio/assets/mata-fig1/_vision/PIPELINE.md)
- Official draw.io skill: [Agents365-ai/drawio-skill](https://github.com/Agents365-ai/drawio-skill)
