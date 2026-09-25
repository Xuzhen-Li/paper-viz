# Dot heatmap (colour and size) or scatter pies.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

mode <- "dot"
map_size <- TRUE

if (mode == "pie") {
  pie <- utils::read.csv("data_pie.csv", stringsAsFactors = FALSE)
  pie$x <- as.numeric(factor(pie$col, levels = unique(pie$col)))
  pie$y <- as.numeric(factor(pie$row, levels = rev(unique(pie$row))))
  p <- ggplot2::ggplot() +
    scatterpie::geom_scatterpie(
      ggplot2::aes(x = x, y = y, r = 0.28 + 0.22 * size),
      data = pie,
      cols = c("Lymphoid", "Myeloid", "Stromal"),
      color = NA
    ) +
    scatterpie::geom_scatterpie_legend(0.28 + 0.22 * c(0.2, 0.8), x = 13.4, y = 4) +
    ggplot2::scale_fill_manual(values = pv_palette("categorical", 3), name = NULL) +
    ggplot2::scale_x_continuous(
      breaks = seq_along(unique(pie$col)),
      labels = unique(pie$col),
      expand = ggplot2::expansion(add = 0.6)
    ) +
    ggplot2::scale_y_continuous(
      breaks = seq_along(unique(pie$row)),
      labels = rev(unique(pie$row)),
      expand = ggplot2::expansion(add = 0.6)
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_viz()
  pv_save(p, "figure", width_mm = 183, height_mm = 160)
  message("wrote preview.png")
  quit(save = "no", status = 0)
}

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$row <- factor(df$row, levels = rev(unique(df$row)))
df$col <- factor(df$col, levels = unique(df$col))
lim <- max(abs(df$value))
p <- ggplot2::ggplot(df, ggplot2::aes(col, row, fill = value))
if (isTRUE(map_size)) {
  p <- p + ggplot2::geom_point(ggplot2::aes(size = size), shape = 21, colour = "grey40", stroke = 0.15)
  p <- p + ggplot2::scale_size_area(max_size = 5.2, name = "Fraction", limits = c(0, 1))
} else {
  p <- p + ggplot2::geom_point(size = 3.2, shape = 21, colour = "grey40", stroke = 0.15)
}
p <- p +
  ggplot2::scale_fill_gradientn(
    colours = pv_palette("diverging", 9), limits = c(-lim, lim), name = "Score"
  ) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = 5),
    panel.grid.major = ggplot2::element_line(colour = "grey92", linewidth = 0.2)
  )

pv_save(p, "figure", width_mm = 160, height_mm = 140)
message("wrote preview.png")
