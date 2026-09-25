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
      legend.background = ggplot2::element_blank()
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
