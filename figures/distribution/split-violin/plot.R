# Split violin: two conditions as mirrored densities, with a median mark.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

group_levels <- c("Liver", "Lung", "Kidney", "Spleen")
condition_levels <- c("Control", "Treated")
half_width <- 0.36

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
df$condition <- factor(df$condition, levels = condition_levels)
cols <- stats::setNames(pv_palette("categorical", 2), condition_levels)

half_poly <- function(values, x0, side, width, id) {
  pad <- 0.25 * stats::sd(values)
  d <- stats::density(values, n = 128, from = min(values) - pad, to = max(values) + pad)
  dens <- d$y / max(d$y) * width
  poly <- data.frame(
    x = c(x0, x0 + side * dens, x0),
    y = c(d$x[1], d$x, d$x[length(d$x)]),
    id = id,
    stringsAsFactors = FALSE
  )
  med <- stats::median(values)
  hw <- stats::approx(d$x, dens, xout = med, rule = 2)$y
  med_row <- data.frame(
    x = x0,
    xend = x0 + side * hw * 0.92,
    y = med,
    stringsAsFactors = FALSE
  )
  list(poly = poly, med = med_row)
}

polys <- list()
meds <- list()
for (i in seq_along(group_levels)) {
  for (j in seq_along(condition_levels)) {
    g <- group_levels[[i]]
    cond <- condition_levels[[j]]
    sub <- df$value[df$group == g & df$condition == cond]
    side <- if (j == 1L) -1 else 1
    pid <- paste(g, cond, sep = "|")
    built <- half_poly(sub, i, side, half_width, pid)
    built$poly$condition <- cond
    polys[[pid]] <- built$poly
    meds[[pid]] <- built$med
  }
}
poly_df <- do.call(rbind, polys)
med_df <- do.call(rbind, meds)

p <- ggplot2::ggplot() +
  ggplot2::geom_polygon(
    data = poly_df,
    ggplot2::aes(x = x, y = y, group = id, fill = condition),
    colour = NA,
    alpha = 0.92
  ) +
  ggplot2::geom_segment(
    data = med_df,
    ggplot2::aes(x = x, xend = xend, y = y, yend = y),
    inherit.aes = FALSE,
    linewidth = 0.55,
    colour = "black",
    lineend = "butt"
  ) +
  ggplot2::scale_fill_manual(values = cols, name = NULL) +
  ggplot2::scale_x_continuous(
    breaks = seq_along(group_levels),
    labels = group_levels,
    expand = ggplot2::expansion(mult = 0.08)
  ) +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.06, 0.14))) +
  ggplot2::labs(x = NULL, y = "Expression (log2)") +
  theme_viz(base_size = 7) +
  ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = c(0.99, 0.98),
    legend.justification.inside = c(1, 1),
    legend.key.height = ggplot2::unit(3.2, "mm"),
    legend.key.width = ggplot2::unit(4.5, "mm")
  )

pv_save(p, "figure", width_mm = 85, height_mm = 60)
message("wrote preview.png")
