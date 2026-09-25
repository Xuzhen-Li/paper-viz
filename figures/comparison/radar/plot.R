# Radar polygons in cartesian space so edges stay straight. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数
fill_polygon <- TRUE
facet_groups <- FALSE
axis_levels <- c("Growth", "Stress", "Yield", "Size", "Color", "Firm")
group_levels <- c("Line A", "Line B", "Line C", "Line D")
radius_max <- 100

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$axis <- factor(df$axis, levels = axis_levels)
df$group <- factor(df$group, levels = group_levels)
n_ax <- length(axis_levels)
ang_of <- function(axis) {
  pi / 2 - (as.numeric(axis) - 1) * 2 * pi / n_ax
}
df$x <- df$value * cos(ang_of(df$axis))
df$y <- df$value * sin(ang_of(df$axis))
closed <- do.call(rbind, lapply(split(df, df$group), function(g) rbind(g, g[1, ])))
cols <- setNames(pv_palette("categorical", nlevels(df$group)), group_levels)

ring_n <- 160
rings <- do.call(rbind, lapply(c(25, 50, 75, 100), function(r) {
  a <- seq(0, 2 * pi, length.out = ring_n)
  data.frame(x = r * cos(a), y = r * sin(a), ring = r)
}))
spoke_a <- ang_of(factor(axis_levels, levels = axis_levels))
spokes <- data.frame(
  x = 0, y = 0,
  xend = radius_max * cos(spoke_a),
  yend = radius_max * sin(spoke_a)
)
lab_r <- radius_max + 12
labs <- data.frame(
  x = lab_r * cos(spoke_a),
  y = lab_r * sin(spoke_a),
  label = axis_levels,
  stringsAsFactors = FALSE
)

draw_one <- function(dat) {
  ggplot2::ggplot() +
    ggplot2::geom_path(
      data = rings,
      ggplot2::aes(x, y, group = ring),
      colour = "grey88", linewidth = 0.25
    ) +
    ggplot2::geom_segment(
      data = spokes,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      colour = "grey88", linewidth = 0.25
    ) +
    ggplot2::geom_polygon(
      data = dat,
      ggplot2::aes(x, y, group = group, colour = group, fill = group),
      alpha = if (fill_polygon) 0.12 else 0,
      linewidth = 0.5
    ) +
    ggplot2::geom_point(
      data = dat[!duplicated(interaction(dat$group, dat$axis)), ],
      ggplot2::aes(x, y, colour = group),
      size = 1.2
    ) +
    ggplot2::geom_text(
      data = labs,
      ggplot2::aes(x, y, label = label),
      size = 2.2
    ) +
    ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::scale_fill_manual(values = cols, guide = "none") +
    ggplot2::coord_equal(xlim = c(-125, 125), ylim = c(-125, 125), clip = "off") +
    theme_viz() +
    ggplot2::theme(
      axis.line = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      legend.position = "bottom",
      plot.margin = ggplot2::margin(8, 8, 4, 8)
    )
}

if (facet_groups) {
  p <- draw_one(closed) + ggplot2::facet_wrap(~group)
} else {
  p <- draw_one(closed)
}

pv_save(p, "figure", width_mm = 120, height_mm = 125)
message("wrote preview.png")
