# visualization/r — ggplot helpers for AI_lib
# Canonical recipes live in coding/r/visualization/; this file is the thin callable theme.
# See: ../../coding/r/visualization/nature-figure-ggplot2-patterns.md
#      ../../coding/r/visualization/r-ggplot2.md

theme_viz <- function(base_size = 8, base_family = "") {
  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      axis.line = ggplot2::element_line(linewidth = 0.4, colour = "black"),
      axis.ticks = ggplot2::element_line(linewidth = 0.4, colour = "black"),
      panel.grid = ggplot2::element_blank(),
      plot.tag = ggplot2::element_text(face = "bold", size = base_size + 1),
      legend.background = ggplot2::element_blank()
    )
}

palette_viz <- function(n = 6) {
  cols <- c("#1e3a5f", "#2A629A", "#D98324", "#518B60", "#C75050", "#6B6B6B")
  if (n <= length(cols)) cols[seq_len(n)] else grDevices::colorRampPalette(cols)(n)
}

save_pub <- function(plot, filename, width_mm = 89, height_mm = 70, dpi = 300) {
  w <- width_mm / 25.4
  h <- height_mm / 25.4
  ggplot2::ggsave(paste0(filename, ".pdf"), plot, width = w, height = h, device = grDevices::cairo_pdf)
  ggplot2::ggsave(paste0(filename, ".png"), plot, width = w, height = h, dpi = dpi)
}
