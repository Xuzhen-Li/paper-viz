# Using paper-viz

paper-viz is a free MIT library of journal-style scientific figures. Each figure is a folder with code and synthetic sample data. Gallery: https://xuzhen-li.github.io/paper-viz/ . Repository: https://github.com/Xuzhen-Li/paper-viz (branch `main`).

Search, copy one folder, swap the table, adjust the parameters at the top of the script, and render. Do not redraw a chart from scratch when a folder already matches.

## Find a figure

From the repository root:

```bash
python3 tools/find_figure.py volcano
python3 tools/find_figure.py 差异基因
python3 tools/find_figure.py --category population-genetics
python3 tools/find_figure.py --column pvalue
python3 tools/find_figure.py --slug volcano --json
```

`tools/find_figure.py` is stdlib Python. It reads `catalog.json` and ranks hits: exact `slug` or title, then title or tags, then `when_to_use`, `customize`, and `data_columns`. It prints the top 5 (`--limit` to change). `--json` prints a list. Exit code 1 means no match.

Each hit includes the folder path, column descriptions, the render command, raw file URLs, and the gallery permalink `https://xuzhen-li.github.io/paper-viz/#<slug>`.

You can also filter `catalog.json` → `figures`. Fields that matter: `slug`, `title`, `title_zh`, `category`, `tags`, `lang`, `dir`, `data_columns`, `when_to_use`, `customize`, `parameters`, `variant_of`, `variants`, `downloads`. Do not edit `catalog.json` by hand. Regenerate it with `python3 tools/build_catalog.py`.

`docs/llms.txt` is a short index of main figures, one line each. Variants are toggles on the main card, not separate lines.

## Copy, edit, render

1. Copy the whole folder `figures/<category>/<slug>/`.
2. Replace `data.csv`. Keep the column names in `data_columns`. Replace rows only.
3. Edit the assignments at the top of `plot.R` (cuts, labels, switches). Keep the folder's theme, palette, and save calls (`theme_house()` / `pv_save_house()` in house-style folders, `theme_viz()` / `pv_save()` in older ones).
4. In that directory, run `Rscript plot.R`.

`pv_save` and `pv_save_house` write a PDF, a 600 dpi PNG, and `preview.png`. The script sources `../../../styles/r/theme_viz.R` or `../../../styles/r/theme_house.R`. If you move the folder, copy `styles/r/` with it (`theme_house.R` needs `theme_viz.R` next to it) and fix `source()`.

`lang: Python` uses `python3 plot.py` and the same columns.

Raw downloads follow `https://raw.githubusercontent.com/Xuzhen-Li/paper-viz/main/` plus the path, for `plot.R`, `data.csv`, and `make_data.R`.

A main figure with `variants` has near-duplicate folders. Copy the slug you will actually plot. A variant's `variant_of` names its main figure.

## Style

**New figures use the house style.** Source `styles/r/theme_house.R` (it also loads `theme_viz.R`) and use `theme_house()`, `pv_palette("house")`, and `pv_save_house()`. Python: `styles/python/house.py` (`apply_house_style()`, `house_figure(cells = "2x1")`, `save_house()`). The style page has the nine examples and the schematics: [house style](https://xuzhen-li.github.io/paper-viz/house-style/).

```r
# figures/<category>/<slug>/plot.R
source("../../../styles/r/theme_house.R")   # also loads theme_viz.R
library(ggplot2)
df <- data.frame(x = rep(1:10, 3),
                 y = c(1:10, 0.8 * (1:10) + 1, 0.5 * (1:10) + 2),
                 group = rep(c("a", "b", "c"), each = 10))   # real data: utils::read.csv("data.csv")
p <- ggplot(df, aes(x, y, colour = group)) +
  geom_line(linewidth = pv_house_lw("main")) +
  scale_colour_manual(values = unname(pv_palette("house", 3))) +
  theme_house()                               # 7/8 pt; theme_house(legend = "inside") if a legend is unavoidable
pv_save_house(p, "figure", cells = "2x1")   # 89 x 43 mm; overwrites preview.png in this folder
```

```r
theme_house(base_size = 7, title_size = base_size + 1, tag_size = max(10, base_size + 3),
            base_family = house_family(), legend = c("none", "inside"))
pv_save_house(plot, file, width = NULL, height_mm = NULL, cells = NULL,
              bump = NULL, dpi = 600, preview = TRUE)   # give cells = c(w, h) or "WxH"
pv_house_mosaic(tiles, cells)   # tiles = list(list(plot = , at = c(col, row), cells = c(w, h)), ...)
pv_fmt_p(p, digits = 1, exact = FALSE)
```

中文：source `theme_house.R`；主题 `theme_house()`、颜色 `pv_palette("house")`、导出 `pv_save_house(p, "figure", cells = "2x1")`。尺寸用 43 mm 网格的格数 `cells = c(w, h)`，每边 1–4 格，分别为 43 / 89 / 135 / 181 mm，占满 4 格的边两侧各加 1 mm 成 183 mm；不在网格上的尺寸报错，旧写法 `width = "single", height_mm = 76` 现在会报错。默认 7/8 pt；只有单个面板存成 2×2 时自动 +2 pt，`bump = 0` 关掉。多图拼一页用 `pv_house_mosaic()`。非用图例不可时用 `legend = "inside"`，放框内右上。

- Canvas: a 43 mm grid with 3 mm gaps. Give `cells = c(w, h)` (or `"WxH"`), 1–4 cells per side: 43 / 89 / 135 / 181 mm; a side spanning all 4 cells gets 1 mm on each end and exports at 183 mm. A double column is 4 cells per row (1+1+1+1, 1+1+2, 2+2, 1+3, 4), a single column 2. Off-grid sizes are errors, so the old `width = "single", height_mm = 76` now fails.
- Default cells: scatter, histogram / density, box / violin / raincloud, bar 1×1 (2×1 with many groups or categories); line / time series and stacked composition 2×1; forest 1×2 (2×2 with many rows); heatmap 2×2; small multiples 1×1 per small plot; genome track / Manhattan 4×1. Move one size up or down within the grid if crowded or empty. Full table and the nine examples' cells: `styles/style-contract.md`.
- Several plots on one page: `pv_house_mosaic(list(list(plot = pa, at = c(1, 1), cells = c(1, 1)), list(plot = pb, at = c(2, 1), cells = c(3, 1))), cells = c(4, 1))`, then `pv_save_house(page, "figure", cells = c(4, 1))` with the same cells.
- Text: 7 pt ticks, 8 pt plain (not bold) axis titles, 10 pt bold lowercase panel tags (`patchwork::plot_annotation(tag_levels = "a")`), nothing under 6 pt. Only a single panel saved at 2×2 (89 × 89 mm) gets +2 pt (9/10 pt); `pv_save_house()` adds it automatically. *P* labels: `pv_fmt_p(p)` with `parse = TRUE`; `exact = TRUE` gives m × 10^−k, whose superscript is 0.7×, so use it only for text of 8.6 pt or more.
- Four-sided 0.5 pt frame, ticks outward 1 mm, no grid. Main lines 1.5 pt (`pv_house_lw("main")`), points `shape = 21, stroke = 0.3`.
- Label series directly in the panel in the series colour; no legend by default (`theme_house(legend = "inside")` when one is unavoidable).
- Category colours: `pv_palette("house")`, in order, at most 6 coloured series:

`#1F72AE` `#F77E12` `#119B76` `#CC312C` `#595594` `#62B4E7` `#E6C32A` `#A8127F` `#8A4C38`

  Diverging `pv_palette("house_div")`, scenarios `pv_palette("ssp")`, warm sequential `pv_palette("house_warm")`, greys `pv_palette("house_grey")`.
- Export with `pv_save_house()`: cairo PDF (text stays text) + 600 dpi PNG + `preview.png`.

Existing figures keep the legacy style and are not re-rendered: `theme_viz()`, `pv_save()`, and `pv_palette("categorical")` (chip order `#134aa3` `#f6a3b1` `#0b5475` `#dc1f26` `#835ca6` `#f7922c` `#fbee61` `#981b1e`, control points `#E0E0E0`, 85×60 mm single panels with `theme_viz(base_size = 7)`). When you copy an existing folder, keep its interface. Details for both: `styles/style-contract.md`.

## What not to do

- Do not add real, patient, or third-party data. Shipped `data.csv` files are synthetic.
- Do not use category colours outside the folder's palette (`house` for new figures, `categorical` for legacy ones). Do not mix the two in one figure. Legacy sequential and diverging fills stay on `pv_palette("sequential")` and `pv_palette("diverging")`; house figures use `house_div` / `house_warm`.
- Do not move the legend outside the frame.
- Do not re-render existing figures into the house style unless a task asks for it.
- Do not write a machine-absolute path into a file in this repository.

## Add a figure

1. Create `figures/<category>/<slug>/`.
2. R folder: `make_data.R` (fixed random seed; `data.csv` under 200KB), `data.csv`, `plot.R`, `preview.png`, `meta.yaml`. `plot.R` only reads the CSV, sources `../../../styles/r/theme_house.R`, and calls `theme_house()`, `pv_palette("house")`, and `pv_save_house()`. The `layout` category uses this same folder; multi-panel arrangement stays in `plot.R`.
3. Required `meta.yaml` keys: `title`, `title_zh`, `slug`, `category`, `tags` (English), `packages`, `data_columns` (name → description), `when_to_use`, `customize`, `lang` (`R` or `Python`). `title_zh`, `when_to_use`, and `customize` must be non-empty. `slug` equals the directory name. A gallery toggle also needs `variant_of` and `variant_label`.
4. `category` is one of: `distribution`, `comparison`, `correlation`, `composition`, `heatmap`, `dimension-reduction`, `differential-expression`, `enrichment`, `population-genetics`, `genome`, `phylogeny`, `network`, `microbiome-ecology`, `clinical`, `layout`.
5. Run `python3 tools/build_catalog.py`. That refreshes `catalog.json`, `docs/catalog.json`, `docs/llms.txt`, the README catalog block, and the figures badge.

Keep one main folder per chart type. Small options belong in the parameters at the top of `plot.R` and in `customize`.
