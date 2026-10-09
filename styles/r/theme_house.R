# paper-viz house style (default for NEW figures) — R / ggplot2.
# Compact, text-dense, little white space. Spec: styles/style-contract.md ("House style").
#
#   source("../../../styles/r/theme_house.R")   # also loads theme_viz.R (pv_palette, pv_save, theme_viz)
#   p <- ggplot(...) + theme_house()             # 7 pt ticks, 8 pt axis titles, 10 pt bold tags
#   pv_save_house(p, "figure", cells = "2x2")   # 89x89 mm, single 2x2 panel -> +2 pt
#   pv_save_house(p, "figure", cells = "2x1")   # 89x43 mm, stays 7/8 pt
# Sizes snap to the 43 mm grid (cells = c(w, h) or "WxH", 1-4 each). Only a figure holding a
# single 2x2 panel gets +2 pt; every other size and every multi-panel figure stays 7/8 pt.
#
# Old interfaces stay as they were: theme_viz(), pv_save(), pv_palette("categorical") (chip eight).

local({
  # Load the sibling theme_viz.R so pv_palette() (legacy + house names) and pv_save() exist.
  here <- NULL
  for (i in rev(seq_len(sys.nframe()))) {
    f <- sys.frame(i)$ofile
    if (!is.null(f)) { here <- dirname(normalizePath(f)); break }
  }
  viz <- if (!is.null(here)) file.path(here, "theme_viz.R") else NA_character_
  if (!is.na(viz) && file.exists(viz)) {
    sys.source(viz, envir = globalenv())
  } else if (!exists("theme_viz", mode = "function")) {
    stop("theme_house.R needs theme_viz.R in the same directory; source that first.")
  }
})

# --- units ------------------------------------------------------------------
# geom_text()/annotate() size is in mm: size = pt / .pt (7 pt = 2.46, 8 pt = 2.81, 6 pt = 2.11).
pv_pt2size <- function(pt) pt / ggplot2::.pt
# linewidth is in units of 0.75 * .pt points: 0.5 pt -> 0.234, 1.5 pt -> 0.703, 2.0 pt -> 0.937.
pv_pt2lw <- function(pt) pt / (ggplot2::.pt * 72 / 96)

# Line widths in pt (STYLE §6). Use pv_house_lw("main") etc. as linewidth.
HOUSE_LW_PT <- c(frame = 0.5, tick = 0.5, main = 1.5, emph = 2.0, minor = 0.8,
                 ref = 0.5, errorbar = 0.7)
pv_house_lw <- function(what = "main") {
  if (is.numeric(what)) return(pv_pt2lw(what))
  what <- match.arg(what, names(HOUSE_LW_PT))
  pv_pt2lw(HOUSE_LW_PT[[what]])
}
# Points (STYLE §5): shape 21, size 2.3, stroke 0.3 — the ggplot values of the locked demo A.
# Physical size: fill diameter about 1.89 mm, outline about 0.43 pt, outer diameter about 2.04 mm.
# STYLE §5 also quotes 1.2–1.4 mm; that does not match its own ggplot values (size 2.2–2.6).
# The ggplot values / demo A win. Python house.POINT / house.SCATTER give the same physical size.
HOUSE_POINT <- list(shape = 21, size = 2.3, stroke = 0.3, colour = "#000000")
# Physical size of a ggplot point (shape 21): grid draws the circle with radius 0.375 * fontsize,
# where fontsize = size * .pt + stroke * .stroke / 2 (pt); the outline is stroke * .stroke / 2 lwd.
pv_point_dims <- function(size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke) {
  stroke_lwd <- stroke * ggplot2::.stroke / 2
  fontsize <- size * ggplot2::.pt + stroke_lwd
  path_pt <- 0.75 * fontsize                # circle path diameter
  outline_pt <- stroke_lwd * 72 / 96        # lwd is 1/96 in
  c(path_mm = path_pt / 72 * 25.4, outline_pt = outline_pt,
    outer_mm = (path_pt + outline_pt) / 72 * 25.4)
}

# --- font -------------------------------------------------------------------
house_family <- function() {
  candidates <- c("Arial", "Helvetica", "Liberation Sans", "DejaVu Sans")
  if (requireNamespace("systemfonts", quietly = TRUE)) {
    fam <- tryCatch(unique(systemfonts::system_fonts()$family), error = function(e) character())
    hit <- candidates[candidates %in% fam]
    if (length(hit)) return(hit[[1]])
  }
  if (Sys.info()[["sysname"]] %in% c("Darwin", "Windows")) "Arial" else "sans"
}

# --- theme ------------------------------------------------------------------
# base_size: tick labels (7 by default; 9 only for a figure holding a single 2x2 panel).
# Axis titles base_size + 1, plain (not bold). Panel tags bold, 10 pt at base 7.
# Lowercase tags come from patchwork::plot_annotation(tag_levels = "a").
# legend = "none" (direct labels, default) or "inside" (top-right, inside the frame, no box).
theme_house <- function(base_size = 7, title_size = base_size + 1,
                        tag_size = max(10, base_size + 3),
                        base_family = house_family(), legend = c("none", "inside")) {
  legend <- match.arg(legend)
  el <- ggplot2::element_text
  lw <- pv_pt2lw(0.5)
  th <- ggplot2::`%+replace%`(ggplot2::theme_classic(base_size = base_size, base_family = base_family),
    ggplot2::theme(
      panel.border = ggplot2::element_rect(fill = NA, colour = "black", linewidth = lw),
      axis.line = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_line(linewidth = lw, colour = "black"),
      axis.ticks.length = ggplot2::unit(1, "mm"),
      axis.text = el(size = base_size, colour = "black"),
      axis.text.x = el(size = base_size, colour = "black", margin = ggplot2::margin(t = 0.7, unit = "mm")),
      axis.text.y = el(size = base_size, colour = "black", hjust = 1,
                       margin = ggplot2::margin(r = 0.7, unit = "mm")),
      axis.title = el(size = title_size, colour = "black", face = "plain"),
      axis.title.x = el(size = title_size, face = "plain", margin = ggplot2::margin(t = 0.8, unit = "mm")),
      axis.title.y = el(size = title_size, face = "plain", angle = 90,
                        margin = ggplot2::margin(r = 0.8, unit = "mm")),
      plot.title = el(size = title_size, hjust = 0, margin = ggplot2::margin(b = 0.8, unit = "mm")),
      plot.tag = el(size = tag_size, face = "bold", hjust = 0, vjust = 1),
      plot.tag.position = c(0, 1),
      strip.background = ggplot2::element_blank(),
      strip.text = el(size = base_size, hjust = 0, margin = ggplot2::margin(b = 0.5, unit = "mm")),
      legend.position = "none",
      legend.text = el(size = base_size),
      legend.title = el(size = base_size),
      legend.background = ggplot2::element_blank(),
      legend.key = ggplot2::element_blank(),
      legend.key.size = ggplot2::unit(3, "mm"),
      panel.grid = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank(),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      # bottom 0.9 mm: PNG devices (ragg, cairo-png) set text a little lower than cairo PDF;
      # with 0.4 mm the x-title descenders touched the last pixel row of the 600 dpi PNG
      plot.margin = ggplot2::margin(1.6, 0.8, 0.9, 0.4, "mm")
    ))
  if (legend == "inside") {
    th <- th + ggplot2::theme(
      legend.position = "inside",
      legend.position.inside = c(0.98, 0.98),
      legend.justification.inside = c(1, 1)
    )
  }
  th
}

# Plotmath string for P, e.g. annotate("text", label = pv_fmt_p(p), parse = TRUE).
# p < 0.001 gives "P < 0.001" by default. exact = TRUE gives "P = m × 10^−k", but plotmath draws
# superscripts at 0.7 x, so the exponent stays >= 6 pt only for text >= 8.6 pt: use exact = TRUE
# only in a bumped (9/10 pt, single 2x2 panel) figure, never in 7/8 pt figures.
pv_fmt_p <- function(p, digits = 1, exact = FALSE) {
  if (p >= 0.001) return(sprintf("italic(P)*' = %s'", formatC(signif(p, 2), format = "fg")))
  if (!isTRUE(exact)) return("italic(P)*' < 0.001'")
  e <- floor(log10(p)); m <- round(p / 10^e, digits)
  if (m >= 10) { m <- 1; e <- e + 1 }
  sprintf("italic(P)*' = %s \u00d7 10'^'\u2212%d'", formatC(m, format = "f", digits = digits), -e)
}

# --- +2 pt for a single 2x2 panel -------------------------------------------
.pv_get <- function(x, name) {
  if (inherits(x, "S7_object")) {
    out <- tryCatch(S7::prop(x, name), error = function(e) NULL)
    if (!is.null(out)) return(out)
  }
  out <- tryCatch(x[[name]], error = function(e) NULL)    # plain lists / ggplot2 < 4
  if (is.null(out)) out <- tryCatch(do.call(`$`, list(x, name)), error = function(e) NULL)
  out
}

.pv_tick_size <- function(plot) {
  th <- .pv_get(plot, "theme")
  for (nm in c("axis.text.x", "axis.text")) {
    el <- if (length(th)) th[[nm]] else NULL
    s <- if (!is.null(el)) .pv_get(el, "size") else NULL
    if (is.numeric(s) && !inherits(s, "rel")) return(as.numeric(s))
  }
  7
}

# Add `pt` points to every absolute text size in the plot theme and to explicit
# geom_text / geom_label / ggrepel sizes. Returns a new plot; the input is untouched.
pv_bump_text <- function(plot, pt = 2) {
  if (!pt) return(plot)
  th <- .pv_get(plot, "theme")
  add <- list()
  for (nm in names(th)) {
    el <- th[[nm]]
    if (!inherits(el, c("element_text", "ggplot2::element_text"))) next
    s <- .pv_get(el, "size")
    if (is.numeric(s) && length(s) == 1 && !inherits(s, "rel")) {
      add[[nm]] <- ggplot2::element_text(size = s + pt)
    }
  }
  if (length(add)) plot <- plot + do.call(ggplot2::theme, add)
  text_geoms <- .pv_text_geoms
  layers <- .pv_get(plot, "layers")
  for (i in seq_along(layers)) {
    l <- layers[[i]]
    if (!inherits(l$geom, text_geoms)) next
    s <- l$aes_params$size
    if (is.null(s) && !("size" %in% names(l$mapping))) s <- HOUSE_TEXT_PT / ggplot2::.pt  # house default
    if (!is.numeric(s)) next
    nl <- rlang::env_clone(l)                # shallow copy, so the input plot is not modified
    class(nl) <- class(l)
    assign("aes_params", utils::modifyList(l$aes_params, list(size = s + pt / ggplot2::.pt)), envir = nl)
    layers[[i]] <- nl
  }
  if (inherits(plot, "S7_object")) S7::prop(plot, "layers") <- layers else plot$layers <- layers
  plot
}

# In-plot text (geom_text / annotate / geom_label / ggrepel) uses the theme font, not the
# device default (otherwise cairo PDFs mix in e.g. NimbusSans). Two layers of defence:
# 1. sourcing this file sets the text/label geom defaults (new-figure scripts only; theme_viz.R
#    alone does not touch them, so legacy figures are unchanged);
# 2. pv_save_house() sets `family` on every text layer that has none, including patchwork panels.
# Default in-plot text size is 7 pt (tick size); only a single 2x2 panel gets +2 pt via
# pv_save_house(), which also bumps layers that rely on this default.
HOUSE_TEXT_PT <- 7
pv_house_geom_defaults <- function(family = house_family(), size_pt = HOUSE_TEXT_PT) {
  new <- list(family = family, size = size_pt / ggplot2::.pt)
  for (g in c("text", "label")) ggplot2::update_geom_defaults(g, new)
  if (requireNamespace("ggrepel", quietly = TRUE)) {
    for (g in c(ggrepel::GeomTextRepel, ggrepel::GeomLabelRepel)) {
      try(ggplot2::update_geom_defaults(g, new), silent = TRUE)
    }
  }
  invisible(family)
}
pv_house_geom_defaults()

.pv_text_geoms <- c("GeomText", "GeomLabel", "GeomTextRepel", "GeomLabelRepel")

.pv_set_text_family <- function(plot, family = house_family()) {
  if (inherits(plot, "patchwork")) {
    patches <- plot$patches
    if (!is.null(patches$plots)) {
      patches$plots <- lapply(patches$plots, .pv_set_text_family, family = family)
      plot$patches <- patches
    }
  }
  if (!inherits(plot, c("ggplot", "ggplot2::ggplot"))) return(plot)
  layers <- .pv_get(plot, "layers")
  changed <- FALSE
  for (i in seq_along(layers)) {
    l <- layers[[i]]
    if (!inherits(l$geom, .pv_text_geoms)) next
    fam <- l$aes_params$family
    if (!is.null(fam) && nzchar(fam)) next
    if ("family" %in% names(l$mapping)) next
    nl <- rlang::env_clone(l)
    class(nl) <- class(l)
    assign("aes_params", utils::modifyList(as.list(l$aes_params), list(family = family)), envir = nl)
    layers[[i]] <- nl
    changed <- TRUE
  }
  if (changed) {
    if (inherits(plot, "S7_object")) S7::prop(plot, "layers") <- layers else plot$layers <- layers
  }
  plot
}

.pv_is_single_panel <- function(plot) {
  if (inherits(plot, "patchwork")) return(FALSE)
  fac <- .pv_get(plot, "facet")
  is.null(fac) || inherits(fac, c("FacetNull"))
}

# --- grid -------------------------------------------------------------------
# Every house figure is snapped to one grid: a 43 mm square cell, 3 mm gap between cells
# (horizontal and vertical), at most 4 cells per side.
#   span(n) = n * 43 + (n - 1) * 3  ->  1: 43, 2: 89, 3: 135, 4: 181 mm
# Canvas rule (canvas = the exported PDF/PNG page, i.e. what pv_save_house writes):
#   * A figure is a tile. On an axis spanning 1-3 cells the canvas is exactly the span
#     (43 / 89 / 135 mm) and carries NO outer margin.
#   * The 1 mm outer margin belongs to the page. It is added only on an axis that spans all
#     4 cells: canvas = 1 + 181 + 1 = 183 mm (the double column), and the plot is drawn into
#     the centred 181 mm content box. Width and height follow the same rule.
#   * So inside a 183 mm page, a tile of column c (1-based) starts at x = 1 + 46 * (c - 1) mm;
#     tiles of 1+1+1+1, 1+1+2, 2+2, 1+3 or 4 cells with 3 mm gaps fill 1..182 mm and
#     reproduce the 183 mm composite exactly; a 4-cell figure's content box covers the same
#     1..182 mm, so edges line up when 1-cell and 4-cell figures are stacked.
#   * Single column = 2 cells = 89 mm canvas (no margin: a single column is a tile).
# Old presets: "single" = 2 cells (89 mm), "double" = 4 cells (183 mm canvas incl. margins).
HOUSE_CELL_MM <- 43
HOUSE_GAP_MM <- 3
HOUSE_PAGE_MARGIN_MM <- 1
HOUSE_MAX_CELLS <- 4L
HOUSE_PRESETS_MM <- c(single = 89, double = 183)      # canvas mm, kept for old calls
HOUSE_PRESETS_CELLS <- c(single = 2L, double = 4L)

# span of n cells in mm (content, no margin)
pv_grid_span <- function(n) n * HOUSE_CELL_MM + (n - 1) * HOUSE_GAP_MM

# canvas mm of an n-cell side: the span, plus 1 mm on each end when n = 4
pv_grid_canvas <- function(n) pv_grid_span(n) + ifelse(n == HOUSE_MAX_CELLS, 2 * HOUSE_PAGE_MARGIN_MM, 0)

# Parse cells: c(w, h), "2x1" (also "2X1", "2×1") -> integer c(w, h); errors off the grid.
pv_house_cells <- function(cells) {
  if (is.character(cells)) {
    if (length(cells) != 1 || !grepl("^\\s*[0-9]+\\s*[xX\u00d7]\\s*[0-9]+\\s*$", cells)) {
      stop(sprintf("cells = %s: use c(w, h) or \"WxH\", e.g. \"2x1\"", deparse(cells)), call. = FALSE)
    }
    cells <- as.numeric(strsplit(gsub("\\s", "", cells), "[xX\u00d7]")[[1]])
  }
  if (!is.numeric(cells) || length(cells) != 2 || anyNA(cells) || any(cells != round(cells)) ||
      any(cells < 1) || any(cells > HOUSE_MAX_CELLS)) {
    stop(sprintf("cells = %s is off the house grid: width and height must each be 1-%d whole cells",
                 paste(deparse(cells), collapse = ""), HOUSE_MAX_CELLS), call. = FALSE)
  }
  as.integer(cells)
}

# mm of one canvas side -> cells; errors unless it is a grid canvas (43, 89, 135, 183).
.pv_mm_to_cells <- function(mm, what) {
  ok <- pv_grid_canvas(seq_len(HOUSE_MAX_CELLS))
  if (length(mm) != 1 || !is.finite(mm)) {   # NA / NaN / Inf / non-numeric: say so, no "nearest" size
    stop(sprintf("%s = %s is not a finite size in mm (allowed canvas: %s mm). Use cells = c(w, h).",
                 what, paste(deparse(mm), collapse = ""), paste(ok, collapse = ", ")), call. = FALSE)
  }
  hit <- which(abs(ok - mm) < 1e-6)
  if (!length(hit)) {
    near <- ok[which.min(abs(ok - mm))]
    stop(sprintf(paste0("%s = %s mm is off the house grid (allowed canvas: %s mm). ",
                        "Use cells = c(w, h); nearest grid size: %s mm."),
                 what, format(mm), paste(ok, collapse = ", "), near), call. = FALSE)
  }
  hit
}

# Canvas / content geometry for a cells spec. Returns mm.
pv_house_canvas <- function(cells) {
  cells <- pv_house_cells(cells)
  m <- ifelse(cells == HOUSE_MAX_CELLS, HOUSE_PAGE_MARGIN_MM, 0)
  list(cells = cells,
       width_mm = pv_grid_canvas(cells[1]), height_mm = pv_grid_canvas(cells[2]),
       content_width_mm = pv_grid_span(cells[1]), content_height_mm = pv_grid_span(cells[2]),
       margin_x_mm = m[1], margin_y_mm = m[2])
}

# Draw-time grob: builds the ggplot/patchwork grob only when drawn (inside the output device,
# so no stray Rplots.pdf) and places it in a viewport. Used for the 4-cell page margin and for
# mosaic tiles.
.pv_placed <- function(plot, x_mm, y_mm, w_mm, h_mm) {
  grid::gTree(plot = plot, cl = "pv_placed",
              vp = grid::viewport(x = grid::unit(x_mm, "mm"), y = grid::unit(y_mm, "mm"),
                                  width = grid::unit(w_mm, "mm"), height = grid::unit(h_mm, "mm"),
                                  just = c("left", "bottom")))
}
makeContent.pv_placed <- function(x) {
  p <- x$plot
  g <- if (inherits(p, "grob")) p else if (inherits(p, "patchwork")) patchwork::patchworkGrob(p) else
    ggplot2::ggplotGrob(p)
  grid::setChildren(x, grid::gList(g))
}
registerS3method("makeContent", "pv_placed", makeContent.pv_placed, envir = asNamespace("grid"))

# Mosaic: several standalone plots on one grid page (draw-time grob, pass it to pv_save_house
# with the same cells). tiles: list of list(plot = <ggplot/patchwork/grob>, at = c(col, row),
# cells = c(w, h)); col/row are 1-based from the top-left cell. Tiles must stay inside the page
# and must not overlap. Each tile occupies exactly its span; the page margin (4-cell sides) is
# added by pv_save_house, so tile edges land on 1 + 46 * (k - 1) mm of the exported canvas.
pv_house_mosaic <- function(tiles, cells) {
  page <- pv_house_cells(cells)
  occ <- matrix(FALSE, page[2], page[1])
  kids <- vector("list", length(tiles))
  h_page <- pv_grid_span(page[2])
  for (i in seq_along(tiles)) {
    t <- tiles[[i]]
    tc <- pv_house_cells(t$cells)
    at <- as.integer(t$at)
    cols <- at[1] + seq_len(tc[1]) - 1L
    rows <- at[2] + seq_len(tc[2]) - 1L
    if (length(at) != 2 || min(at) < 1 || max(cols) > page[1] || max(rows) > page[2]) {
      stop(sprintf("mosaic tile %d (at %s, cells %s) does not fit a %dx%d page", i,
                   paste(at, collapse = ","), paste(tc, collapse = "x"), page[1], page[2]), call. = FALSE)
    }
    if (any(occ[rows, cols])) stop(sprintf("mosaic tile %d overlaps another tile", i), call. = FALSE)
    occ[rows, cols] <- TRUE
    x0 <- (at[1] - 1) * (HOUSE_CELL_MM + HOUSE_GAP_MM)
    top <- (at[2] - 1) * (HOUSE_CELL_MM + HOUSE_GAP_MM)
    hh <- pv_grid_span(tc[2])
    p <- t$plot
    if (!inherits(p, "grob")) p <- .pv_set_text_family(p)
    kids[[i]] <- .pv_placed(p, x0, h_page - top - hh, pv_grid_span(tc[1]), hh)
  }
  structure(grid::gTree(children = do.call(grid::gList, kids), cl = "pv_mosaic"),
            pv_cells = page)
}

# --- export -----------------------------------------------------------------
# cells: c(w, h) or "WxH" in grid cells (1-4 each); see the grid rule above. Preferred.
# width / height_mm: old interface. width "single" = 2 cells, "double" = 4 cells; numbers and
#   height_mm must be a grid canvas (43, 89, 135 or 183 mm) and are converted to cells.
#   Anything else is an ERROR, not a warning: the only callers are the house examples (all on
#   the grid), and a warning would let an off-grid figure pass CI and ship.
#   height_mm defaults to 1 cell when only width is given.
# plot: ggplot, patchwork, or a grob (e.g. pv_house_mosaic()).
# Text bump: ONLY a single-column figure holding exactly one 2 x 2 (89 x 89 mm) panel gets
#   +2 pt (ticks 9 pt, axis titles 10 pt; STYLE §2). Everything else stays 7/8 pt. Computed from
#   the current tick size, so base_size = 9 plots are not bumped twice; bump = 0 switches it off.
# Writes <file>.pdf (cairo PDF: text stays text, fonts embedded, nothing outlined),
# <file>.png at `dpi` (600) and, if preview = TRUE, preview.png (1200 px wide) next to it.
pv_save_house <- function(plot, file, width = NULL, height_mm = NULL, cells = NULL,
                          bump = NULL, dpi = 600, preview = TRUE) {
  if (is.null(cells)) {
    if (is.null(width)) stop("pv_save_house(): give cells = c(w, h), e.g. cells = \"2x1\"", call. = FALSE)
    if (is.character(width)) {
      if (length(width) != 1 || !width %in% names(HOUSE_PRESETS_CELLS)) {
        stop(sprintf("width = %s: use \"single\", \"double\" or cells = c(w, h)", deparse(width)), call. = FALSE)
      }
      w_cells <- HOUSE_PRESETS_CELLS[[width]]
    } else {
      w_cells <- .pv_mm_to_cells(as.numeric(width), "width")
    }
    h_cells <- if (is.null(height_mm)) 1L else .pv_mm_to_cells(as.numeric(height_mm), "height_mm")
    cells <- c(w_cells, h_cells)
  } else if (!is.null(width) || !is.null(height_mm)) {
    stop("pv_save_house(): give either cells or width/height_mm, not both", call. = FALSE)
  }
  geo <- pv_house_canvas(cells)
  cells <- geo$cells
  if (inherits(plot, "pv_mosaic") && !identical(attr(plot, "pv_cells"), cells)) {
    stop("pv_save_house(): mosaic was built for a different cells size", call. = FALSE)
  }

  is_grob <- inherits(plot, "grob")
  if (is.null(bump)) {
    bump <- if (identical(cells, c(2L, 2L)) && !is_grob && .pv_is_single_panel(plot))
      max(0, 9 - .pv_tick_size(plot)) else 0
  }
  if (!is_grob) {
    plot <- pv_bump_text(plot, bump)
    plot <- .pv_set_text_family(plot)
  }
  if (is_grob || geo$margin_x_mm > 0 || geo$margin_y_mm > 0) {
    plot <- .pv_placed(plot, geo$margin_x_mm, geo$margin_y_mm,
                       geo$content_width_mm, geo$content_height_mm)
  }

  w_in <- geo$width_mm / 25.4
  h_in <- geo$height_mm / 25.4
  base <- sub("\\.(png|pdf|tiff|tif)$", "", file, ignore.case = TRUE)
  out_dir <- dirname(base)
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  pdf_dev <- if (isTRUE(capabilities("cairo"))) grDevices::cairo_pdf else
    function(filename, ...) grDevices::pdf(filename, ..., useDingbats = FALSE)
  png_dev <- if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_png else
    # ggsave only passes units / res to devices that declare them; without them png()
    # reads width/height as pixels and draws a few-pixel canvas.
    function(filename, width, height, units = "in", res = 300, ...)
      grDevices::png(filename, width = width, height = height, units = units, res = res,
                     type = "cairo", ...)

  ggplot2::ggsave(paste0(base, ".pdf"), plot, width = w_in, height = h_in, units = "in",
                  device = pdf_dev, bg = "white")
  ggplot2::ggsave(paste0(base, ".png"), plot, width = w_in, height = h_in, units = "in",
                  dpi = dpi, device = png_dev, bg = "white")
  if (isTRUE(preview)) {
    ggplot2::ggsave(file.path(out_dir, "preview.png"), plot, width = w_in, height = h_in,
                    units = "in", dpi = 1200 / w_in, device = png_dev, bg = "white")
  }
  invisible(list(pdf = paste0(base, ".pdf"), png = paste0(base, ".png"), cells = cells,
                 width_mm = geo$width_mm, height_mm = geo$height_mm,
                 content_width_mm = geo$content_width_mm, content_height_mm = geo$content_height_mm,
                 bump = bump))
}
