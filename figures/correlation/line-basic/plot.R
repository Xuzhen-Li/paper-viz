# Line chart. Multi-series, ribbon, area, or connected points.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

series_keep <- c("Control", "Low dose", "High dose")
show_ribbon <- TRUE
show_area <- FALSE
show_points <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$series %in% series_keep, , drop = FALSE]
df$series <- factor(df$series, levels = series_keep)
pal <- pv_palette("categorical", length(series_keep))
names(pal) <- series_keep

p <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = series, fill = series))
if (isTRUE(show_area)) {
  p <- p + ggplot2::geom_area(
    ggplot2::aes(group = series),
    alpha = 0.18, linewidth = 0, position = "identity"
  )
}
if (isTRUE(show_ribbon)) {
  p <- p + ggplot2::geom_ribbon(
    stat = "smooth", method = "loess", formula = y ~ x, span = 0.45,
    alpha = 0.18, colour = NA, show.legend = FALSE
  )
}
p <- p + ggplot2::geom_line(linewidth = 0.55)
if (isTRUE(show_points)) {
  p <- p + ggplot2::geom_point(size = 1.1)
}
p <- p +
  ggplot2::scale_colour_manual(values = pal, name = NULL) +
  ggplot2::scale_fill_manual(values = pal, guide = "none") +
  ggplot2::labs(x = "Day", y = "Relative abundance") +
  theme_viz(base_size = 7) +
  ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = c(0.98, 0.02),
    legend.justification.inside = c(1, 0)
  )

pv_save(p, "figure", width_mm = 85, height_mm = 60)
message("wrote preview.png")
