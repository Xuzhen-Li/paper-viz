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

**New figures use the house style.** Source `styles/r/theme_house.R` (it also loads `theme_viz.R`) and use `theme_house()`, `pv_palette("house")`, and `pv_save_house()`. Python: `styles/python/house.py` (`apply_house_style()`, `house_figure()`, `save_house()`).

- Canvas: 89 mm single column (`width = "single"`) or 183 mm double column (`width = "double"`).
- Text: 7 pt ticks, 8 pt plain (not bold) axis titles, 10 pt bold lowercase panel tags (`patchwork::plot_annotation(tag_levels = "a")`), nothing under 6 pt. A single-column single panel gets +2 pt (9/10 pt); `pv_save_house()` adds it automatically.
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
