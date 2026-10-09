# paper-viz house style (default for NEW figures) — R / ggplot2.
# Compact, text-dense, little white space. Spec: styles/style-contract.md ("House style").
#
#   source("../../../styles/r/theme_house.R")   # also loads theme_viz.R (pv_palette, pv_save, theme_viz)
#   p <- ggplot(...) + theme_house()             # 7 pt ticks, 8 pt axis titles, 10 pt bold tags
#   pv_save_house(p, "figure", width = "single", height_mm = 76)   # 89 mm, one panel -> +2 pt
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

HOUSE_PRESETS_MM <- c(single = 89, double = 183)

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
# base_size: tick labels (7 double-column; 9 for a single-column single panel).
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
      plot.margin = ggplot2::margin(1.6, 0.8, 0.4, 0.4, "mm")
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

# Plotmath string for P (italic P, "×10^−k"), e.g. annotate("text", label = pv_fmt_p(p), parse = TRUE).
pv_fmt_p <- function(p, digits = 1) {
  if (p >= 0.001) return(sprintf("italic(P)*' = %s'", formatC(signif(p, 2), format = "fg")))
  e <- floor(log10(p)); m <- round(p / 10^e, digits)
  if (m >= 10) { m <- 1; e <- e + 1 }
  sprintf("italic(P)*' = %s \u00d7 10'^'\u2212%d'", formatC(m, format = "f", digits = digits), -e)
}

# --- +2 pt for a single-column single panel ---------------------------------
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
# Default in-plot text size is 7 pt (tick size); single-column single panels get +2 pt via
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

# --- export -----------------------------------------------------------------
# width: "single" (89 mm), "double" (183 mm) or a number in mm.
# A single-column (<= 89 mm) single panel gets +2 pt on all text so ticks reach 9 pt and axis
# titles 10 pt (STYLE §2). The bump is computed from the current tick size, so a plot already
# built with theme_house(base_size = 9) is not bumped twice. Set bump = 0 to switch it off.
# Writes <file>.pdf (cairo PDF: text stays text, fonts embedded, nothing outlined),
# <file>.png at `dpi` (600) and, if preview = TRUE, preview.png (1200 px wide) next to it.
pv_save_house <- function(plot, file, width = c("double", "single"), height_mm = NULL,
                          bump = NULL, dpi = 600, preview = TRUE) {
  if (is.character(width)) {
    width <- match.arg(width)
    width_mm <- HOUSE_PRESETS_MM[[width]]
  } else {
    width_mm <- as.numeric(width)
  }
  if (is.null(height_mm)) height_mm <- if (width_mm <= 89) 76 else 118
  if (is.null(bump)) {
    bump <- if (width_mm <= 89 + 1e-6 && .pv_is_single_panel(plot)) max(0, 9 - .pv_tick_size(plot)) else 0
  }
  plot <- pv_bump_text(plot, bump)
  plot <- .pv_set_text_family(plot)

  w_in <- width_mm / 25.4
  h_in <- height_mm / 25.4
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
  invisible(list(pdf = paste0(base, ".pdf"), png = paste0(base, ".png"),
                 width_mm = width_mm, height_mm = height_mm, bump = bump))
}
