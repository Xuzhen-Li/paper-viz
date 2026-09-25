# Ternary scatter in Cartesian barycentric coordinates. Cluster colours are a switch.
# ggtern did not install against this ggplot2; the triangle is drawn here.
source("../../../styles/r/theme_viz.R")

colour_by_cluster <- TRUE
group_levels <- c("Cluster 1", "Cluster 2", "Cluster 3")
vertex_labels <- c(a = "Component A", b = "Component B", c = "Component C")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
h <- sqrt(3) / 2
df$x <- df$b * 0 + df$c * 1 + df$a * 0.5
df$y <- df$a * h
if (isTRUE(colour_by_cluster)) {
  df$group <- factor(df$group, levels = group_levels)
  pal <- stats::setNames(pv_palette("categorical", 3), group_levels)
} else {
  df$group <- factor(rep("All", nrow(df)))
  pal <- c(All = pv_palette("categorical", 1))
}

grid_line <- function(fixed, value, n = 40) {
  others <- setdiff(c("a", "b", "c"), fixed)
  t <- seq(0, 1 - value, length.out = n)
  comp <- list(a = 0, b = 0, c = 0)
  comp[[fixed]] <- value
  comp[[others[1]]] <- t
  comp[[others[2]]] <- 1 - value - t
  data.frame(
    x = comp$b * 0 + comp$c * 1 + comp$a * 0.5,
    y = comp$a * h,
    which = fixed,
    value = value
  )
}
grid <- do.call(rbind, lapply(c("a", "b", "c"), function(ax) {
  do.call(rbind, lapply(c(0.25, 0.5, 0.75), function(v) grid_line(ax, v)))
}))
grid$id <- paste(grid$which, grid$value, sep = "-")

tri <- data.frame(x = c(0.5, 0, 1), y = c(h, 0, 0))
labs <- data.frame(
  x = c(0.5, -0.02, 1.02),
  y = c(h + 0.045, -0.04, -0.04),
  label = unname(vertex_labels),
  hjust = c(0.5, 1, 0),
  vjust = c(0, 1, 1)
)

p <- ggplot2::ggplot() +
  ggplot2::geom_polygon(data = tri, ggplot2::aes(x, y), fill = NA, colour = "black", linewidth = 0.35) +
  ggplot2::geom_path(
    data = grid,
    ggplot2::aes(x, y, group = id),
    colour = "#D0D0D0",
    linewidth = 0.25
  ) +
  ggplot2::geom_point(
    data = df,
    ggplot2::aes(x, y, colour = group),
    size = 1.35,
    alpha = 0.9
  ) +
  ggplot2::geom_text(
    data = labs,
    ggplot2::aes(x, y, label = label, hjust = hjust, vjust = vjust),
    size = 2.15,
    colour = "black"
  ) +
  ggplot2::scale_colour_manual(values = if (isTRUE(colour_by_cluster)) pal else c(All = pal[[1]]), name = NULL) +
  ggplot2::coord_equal(clip = "off", xlim = c(-0.08, 1.08), ylim = c(-0.08, h + 0.1)) +
  theme_viz() +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    legend.position = "right",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.margin = ggplot2::margin(3, 3, 3, 6, "mm")
  )

pv_save(p, "figure", width_mm = 130, height_mm = 118)
message("wrote preview.png")
