# Scatter with optional regression, group colour, and 2D density.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

show_regression <- TRUE
colour_by_group <- TRUE
show_density <- FALSE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = c("MCF7", "A549", "HepG2"))
pal <- pv_palette("categorical", 3)
names(pal) <- levels(df$group)

p <- ggplot2::ggplot(df, ggplot2::aes(x, y))
if (isTRUE(show_density)) {
  if (isTRUE(colour_by_group)) {
    p <- p + ggplot2::geom_density_2d(ggplot2::aes(colour = group), linewidth = 0.3, bins = 5)
  } else {
    p <- p + ggplot2::geom_density_2d(linewidth = 0.3, colour = "#E0E0E0", bins = 5)
  }
}
if (isTRUE(colour_by_group)) {
  p <- p + ggplot2::geom_point(ggplot2::aes(colour = group), size = 2.2, alpha = 0.85)
  p <- p + ggplot2::scale_colour_manual(values = pal, name = NULL)
} else {
  p <- p + ggplot2::geom_point(colour = pal[[1]], size = 2.2, alpha = 0.85)
}
if (isTRUE(show_regression)) {
  if (isTRUE(colour_by_group)) {
    p <- p + ggplot2::geom_smooth(
      ggplot2::aes(colour = group, fill = group),
      method = "lm", se = TRUE, linewidth = 0.45, alpha = 0.15
    ) +
      ggplot2::guides(colour = ggplot2::guide_legend(override.aes = list(fill = NA)))
  } else {
    p <- p + ggplot2::geom_smooth(
      method = "lm", se = TRUE, linewidth = 0.45,
      colour = pal[[1]], fill = "#E0E0E0", alpha = 0.25
    )
  }
  p <- p + ggplot2::scale_fill_manual(values = pal, guide = "none")
}
p <- p +
  ggplot2::labs(
    x = "Gene A expression (log2 CPM)",
    y = "Gene B expression (log2 CPM)"
  ) +
  theme_viz(base_size = 7) +
  ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = c(0.02, 0.98),
    legend.justification.inside = c(0, 1),
    legend.key.height = ggplot2::unit(3.2, "mm"),
    legend.key.width = ggplot2::unit(5, "mm")
  )

pv_save(p, "figure", width_mm = 85, height_mm = 60)
message("wrote preview.png")
