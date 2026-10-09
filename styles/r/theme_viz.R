# visualization/r — ggplot helpers for AI_lib
# Canonical recipes live in coding/r/visualization/; this file is the thin callable theme.
# See: ../../coding/r/visualization/nature-figure-ggplot2-patterns.md
#      ../../coding/r/visualization/r-ggplot2.md

viz_sans_family <- function() {
  candidates <- c("Helvetica", "Arial", "DejaVu Sans")
  if (requireNamespace("systemfonts", quietly = TRUE)) {
    fam <- tryCatch(unique(systemfonts::system_fonts()$family), error = function(e) character())
    hit <- candidates[candidates %in% fam]
    if (length(hit)) return(hit[[1]])
  }
  sys <- Sys.info()[["sysname"]]
  if (sys %in% c("Darwin", "Windows")) "Arial" else "DejaVu Sans"
}

# 12 pt on the working canvas. Gallery previews are all 1200 px wide, so 6.5 pt
# on a 183 mm figure shrank to about 15 px. 12 pt is about twice that.
# The main panel is a closed rectangle, not an L-shaped axis.
theme_viz <- function(base_size = 12, base_family = viz_sans_family()) {
  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      axis.line = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_line(linewidth = 0.5, colour = "black"),
      axis.text = ggplot2::element_text(size = base_size, colour = "black"),
      axis.title = ggplot2::element_text(size = base_size + 1, colour = "black"),
      panel.border = ggplot2::element_rect(colour = "black", fill = NA, linewidth = 0.5),
      panel.grid = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(size = base_size + 1),
      legend.text = ggplot2::element_text(size = base_size - 1),
      legend.title = ggplot2::element_text(size = base_size),
      legend.position = "inside",
      legend.position.inside = c(0.98, 0.98),
      legend.justification.inside = c(1, 1),
      legend.key.height = ggplot2::unit(3.2, "mm"),
      legend.key.width = ggplot2::unit(4, "mm"),
      plot.tag = ggplot2::element_text(face = "bold", size = base_size + 2),
      legend.background = ggplot2::element_blank(),
      legend.key = ggplot2::element_blank(),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
}

# ggplot2::geom_text(size=) is in millimetres. 12 pt is about 4.2 mm.
pv_text_mm <- function(pt = 12) pt / 72 * 25.4

palette_viz <- function(n = 6) {
  cols <- c("#134aa3", "#f6a3b1", "#0b5475", "#dc1f26", "#835ca6", "#f7922c", "#fbee61", "#981b1e")
  if (n <= length(cols)) cols[seq_len(n)] else grDevices::colorRampPalette(cols)(n)
}

save_pub <- function(plot, filename, width_mm = 183, height_mm = 120, dpi = 600) {
  w <- width_mm / 25.4
  h <- height_mm / 25.4
  ggplot2::ggsave(paste0(filename, ".pdf"), plot, width = w, height = h, device = grDevices::cairo_pdf)
  ggplot2::ggsave(paste0(filename, ".png"), plot, width = w, height = h, dpi = dpi)
}

# Palettes. name: categorical | sequential | diverging (legacy, unchanged)
#                | house | house_div | ssp | house_warm | house_grey (house style, styles/r/theme_house.R).
# categorical = chip-paper fixed order; sequential = single-hue blue; diverging = blue–orange.
# Control / background point clouds (not a data category): #E0E0E0.
# house = 9 categorical colours from FINAL STYLE.md §4 (use <= 6 coloured series per figure);
# house_div = blue–red diverging (centre #F7F7F7); ssp = named scenario colours;
# house_warm = warm sequential; house_grey = neutral greys (text, reference lines, CI bands).
pv_palette <- function(name = "categorical", n = NULL) {
  name <- match.arg(name, c(
    "categorical", "sequential", "diverging",
    "house", "house_div", "ssp", "house_warm", "house_grey"
  ))
  stops <- switch(name,
    categorical = c(
      "#134aa3", "#f6a3b1", "#0b5475", "#dc1f26",
      "#835ca6", "#f7922c", "#fbee61", "#981b1e"
    ),
    sequential = c("#F7FBFF", "#C6DBEF", "#6BAED6", "#2171B5", "#08306B"),
    diverging = c("#2166AC", "#67A9CF", "#D1E5F0", "#F7F7F7", "#FEE0B6", "#FDB863", "#E08214"),
    house = c(
      blue = "#1F72AE", orange = "#F77E12", green = "#119B76", red = "#CC312C",
      purple = "#595594", sky = "#62B4E7", gold = "#E6C32A", magenta = "#A8127F",
      brown = "#8A4C38"
    ),
    house_div = c(
      "#1D7CBB", "#4A82B0", "#8EBDDA", "#DEE4F0", "#F7F7F7",
      "#F6DEDE", "#E19193", "#C4454B", "#CB2223"
    ),
    ssp = c(
      "Historical" = "#000000", "SSP1-2.6" = "#3A9CFE", "SSP2-4.5" = "#F79423",
      "SSP3-7.0" = "#FD3B3B", "SSP5-8.5" = "#9C2125"
    ),
    house_warm = c("#FBD6A0", "#F5BA7A", "#F38F64", "#CC635F", "#965459"),
    house_grey = c(
      text = "#000000", dark = "#333333", mid = "#6B6B6B", ref = "#757575",
      ci = "#BFBFBF", light = "#E0E0E0", bg = "#F0F0F0"
    )
  )
  if (is.null(n)) return(stops)
  n <- as.integer(n)
  if (n < 1) stop("n must be >= 1")
  if (name == "categorical" && n <= length(stops)) return(stops[seq_len(n)])
  if (name %in% c("house", "ssp", "house_grey")) {
    if (n > length(stops)) {
      stop(sprintf("pv_palette(\"%s\") has %d colours; n = %d is too many (grey out the rest)",
                   name, length(stops), n))
    }
    return(stops[seq_len(n)])
  }
  grDevices::colorRampPalette(unname(stops))(n)
}

# Write <file>.pdf and 600 dpi <file>.png, plus preview.png (1200 px wide)
# in the same directory. `file` is a path without extension.
pv_save <- function(plot, file, width_mm, height_mm) {
  w_in <- width_mm / 25.4
  h_in <- height_mm / 25.4
  base <- sub("\\.(png|pdf|tiff|tif)$", "", file, ignore.case = TRUE)
  out_dir <- dirname(base)
  if (!nzchar(out_dir) || out_dir == ".") out_dir <- "."
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  pdf_dev <- if (isTRUE(capabilities("cairo"))) grDevices::cairo_pdf else "pdf"
  ggplot2::ggsave(paste0(base, ".pdf"), plot, width = w_in, height = h_in, device = pdf_dev)
  ggplot2::ggsave(paste0(base, ".png"), plot, width = w_in, height = h_in, dpi = 600)
  preview_dpi <- 1200 / w_in
  ggplot2::ggsave(
    file.path(out_dir, "preview.png"),
    plot, width = w_in, height = h_in, dpi = preview_dpi
  )
  invisible(base)
}
