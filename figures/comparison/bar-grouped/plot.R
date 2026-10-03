# Grouped bars. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

bar_width <- 0.72
dodge_width <- 0.8
show_legend <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = unique(df$group))
df$series <- factor(df$series, levels = unique(df$series))
n_series <- nlevels(df$series)
cols <- pv_palette("categorical", n_series)

p <- ggplot2::ggplot(df, ggplot2::aes(group, value, fill = series)) +
  ggplot2::geom_col(
    width = bar_width,
    position = ggplot2::position_dodge(width = dodge_width),
    colour = NA
  ) +
  ggplot2::scale_fill_manual(values = cols) +
  ggplot2::labs(x = NULL, y = "Value", fill = NULL) +
  theme_viz(base_size = 7)

if (!isTRUE(show_legend)) {
  p <- p + ggplot2::theme(legend.position = "none")
} else {
  p <- p + ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = c(0.98, 0.98),
    legend.justification.inside = c(1, 1),
    legend.key.height = ggplot2::unit(3.2, "mm"),
    legend.key.width = ggplot2::unit(4, "mm")
  )
}

pv_save(p, "figure", width_mm = 85, height_mm = 60)
message("wrote preview.png")
