# Bubble chart. Size, a third colour scale, or a categorical x axis.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

map_size <- TRUE
colour_by <- "group"
x_categorical <- FALSE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = c("Liver", "Lung", "Kidney", "Brain"))
if (isTRUE(x_categorical)) {
  df$x_plot <- cut(df$x, breaks = 4, labels = c("Q1", "Q2", "Q3", "Q4"))
} else {
  df$x_plot <- df$x
}
pal <- pv_palette("categorical", 4)
names(pal) <- levels(df$group)

df$sz <- if (isTRUE(map_size)) df$size else 40
p <- ggplot2::ggplot(df, ggplot2::aes(x_plot, y))
if (colour_by == "size") {
  p <- p + ggplot2::geom_point(
    ggplot2::aes(size = sz, fill = size),
    shape = 21, colour = "grey30", stroke = 0.2, alpha = 0.9
  )
  p <- p + ggplot2::scale_fill_gradientn(
    colours = pv_palette("sequential", 5), name = "N"
  )
} else {
  p <- p + ggplot2::geom_point(
    ggplot2::aes(size = sz, fill = group),
    shape = 21, colour = "grey30", stroke = 0.2, alpha = 0.9
  )
  p <- p + ggplot2::scale_fill_manual(values = pal, name = NULL)
}
p <- p +
  ggplot2::scale_size_area(max_size = 9, name = "N") +
  ggplot2::labs(
    x = if (isTRUE(x_categorical)) "Effect-size quartile" else "Effect size",
    y = expression(-log[10](italic(p)))
  ) +
  theme_viz() +
  ggplot2::theme(legend.position = "right")

pv_save(p, "figure", width_mm = 130, height_mm = 95)
message("wrote preview.png")
