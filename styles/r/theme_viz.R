# visualization/r — ggplot helpers for AI_lib
# Canonical recipes live in coding/r/visualization/; this file is the thin callable theme.
# See: ../../coding/r/visualization/nature-figure-ggplot2-patterns.md
#      ../../coding/r/visualization/r-ggplot2.md

viz_sans_family <- function() {
  candidates <- c("Arial", "Helvetica", "DejaVu Sans")
  if (requireNamespace("systemfonts", quietly = TRUE)) {
    fam <- tryCatch(unique(systemfonts::system_fonts()$family), error = function(e) character())
    hit <- candidates[candidates %in% fam]
    if (length(hit)) return(hit[[1]])
  }
  sys <- Sys.info()[["sysname"]]
  if (sys %in% c("Darwin", "Windows")) "Arial" else "DejaVu Sans"
}

theme_viz <- function(base_size = 6.5, base_family = viz_sans_family()) {
  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      axis.line = ggplot2::element_line(linewidth = 0.35, colour = "black"),
      axis.ticks = ggplot2::element_line(linewidth = 0.35, colour = "black"),
      panel.grid = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(size = 7),
      legend.text = ggplot2::element_text(size = 6),
      plot.tag = ggplot2::element_text(face = "bold", size = 8),
      legend.background = ggplot2::element_blank(),
      legend.key = ggplot2::element_blank()
    )
}

palette_viz <- function(n = 6) {
  cols <- c("#1e3a5f", "#2A629A", "#D98324", "#518B60", "#C75050", "#6B6B6B")
  if (n <= length(cols)) cols[seq_len(n)] else grDevices::colorRampPalette(cols)(n)
}

save_pub <- function(plot, filename, width_mm = 183, height_mm = 120, dpi = 600) {
  w <- width_mm / 25.4
  h <- height_mm / 25.4
  ggplot2::ggsave(paste0(filename, ".pdf"), plot, width = w, height = h, device = grDevices::cairo_pdf)
  ggplot2::ggsave(paste0(filename, ".png"), plot, width = w, height = h, dpi = dpi)
}

# Colorblind-friendly palettes. name: categorical | sequential | diverging.
# categorical = Okabe-Ito; sequential = single-hue blue; diverging = blue–orange.
pv_palette <- function(name = "categorical", n = NULL) {
  name <- match.arg(name, c("categorical", "sequential", "diverging"))
  stops <- switch(name,
    categorical = c(
      "#0072B2", "#E69F00", "#009E73", "#D55E00",
      "#CC79A7", "#56B4E9", "#F0E442", "#000000"
    ),
    sequential = c("#F7FBFF", "#C6DBEF", "#6BAED6", "#2171B5", "#08306B"),
    diverging = c("#2166AC", "#67A9CF", "#D1E5F0", "#F7F7F7", "#FEE0B6", "#FDB863", "#E08214")
  )
  if (is.null(n)) return(stops)
  n <- as.integer(n)
  if (n < 1) stop("n must be >= 1")
  if (name == "categorical" && n <= length(stops)) return(stops[seq_len(n)])
  grDevices::colorRampPalette(stops)(n)
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
