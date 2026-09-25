# Raincloud: points, box, and a half density. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数
show_signif <- TRUE
use_facet <- FALSE
group_levels <- c("Ctrl", "Low", "Mid", "High")
comparisons <- list(c("Ctrl", "Low"), c("Mid", "High"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
cols <- setNames(pv_palette("categorical", nlevels(df$group)), group_levels)
df$x <- as.numeric(df$group)
set.seed(42)
df$x_pt <- df$x - 0.22 + runif(nrow(df), -0.07, 0.07)

half_poly <- function(values, x0, width = 0.32, id = "a") {
  d <- stats::density(values, n = 128, from = min(values) - 0.15, to = max(values) + 0.15)
  y <- d$y / max(d$y) * width
  data.frame(
    x = c(x0, x0 + y, x0),
    y = c(d$x[1], d$x, d$x[length(d$x)]),
    id = id
  )
}
polys <- lapply(seq_along(group_levels), function(i) {
  sub <- df[df$group == group_levels[i], ]
  poly <- half_poly(sub$value, i + 0.02, id = group_levels[i])
  poly$group <- group_levels[i]
  poly
})
poly_df <- do.call(rbind, polys)

star <- function(p) {
  if (p < 0.001) return("***")
  if (p < 0.01) return("**")
  if (p < 0.05) return("*")
  "ns"
}

p <- ggplot2::ggplot() +
  ggplot2::geom_polygon(
    data = poly_df,
    ggplot2::aes(x, y, group = id, fill = group),
    colour = NA, alpha = 0.85
  ) +
  ggplot2::geom_boxplot(
    data = df,
    ggplot2::aes(x = x, y = value, group = group),
    width = 0.12, outlier.shape = NA, fill = "white", linewidth = 0.3
  ) +
  ggplot2::geom_point(
    data = df,
    ggplot2::aes(x_pt, value, colour = group),
    size = 0.55, alpha = 0.65
  ) +
  ggplot2::scale_fill_manual(values = cols, guide = "none") +
  ggplot2::scale_colour_manual(values = cols, guide = "none") +
  ggplot2::scale_x_continuous(breaks = seq_along(group_levels), labels = group_levels) +
  ggplot2::labs(x = NULL, y = "Response score") +
  theme_viz()

if (show_signif) {
  step <- diff(range(df$value)) * 0.1
  br <- do.call(rbind, lapply(seq_along(comparisons), function(i) {
    pair <- comparisons[[i]]
    sub <- df[df$group %in% pair, ]
    pval <- stats::wilcox.test(value ~ group, data = sub)$p.value
    data.frame(
      x = match(pair[1], group_levels),
      xend = match(pair[2], group_levels),
      y = max(df$value) + step * i,
      label = star(pval)
    )
  }))
  p <- p +
    ggplot2::geom_segment(
      data = br, ggplot2::aes(x = x, xend = xend, y = y, yend = y),
      inherit.aes = FALSE, linewidth = 0.3
    ) +
    ggplot2::geom_text(
      data = br,
      ggplot2::aes(x = (x + xend) / 2, y = y + step * 0.28, label = label),
      inherit.aes = FALSE, size = 2.2
    ) +
    ggplot2::coord_cartesian(ylim = c(min(df$value) - 0.15, max(br$y) + step * 0.6), clip = "off")
}

if (use_facet) {
  df$panel <- ifelse(df$group %in% group_levels[1:2], "Lower doses", "Higher doses")
  poly_df$panel <- ifelse(poly_df$group %in% group_levels[1:2], "Lower doses", "Higher doses")
  p <- p + ggplot2::facet_wrap(~panel, scales = "free_x")
}

pv_save(p, "figure", width_mm = 120, height_mm = 82)
message("wrote preview.png")
