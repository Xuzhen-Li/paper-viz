# Isolation by distance. Reads data.csv.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_regression <- TRUE
by_region <- TRUE
regions_show <- c("North", "Central", "South")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$region %in% regions_show, ]
df$region <- factor(df$region, levels = regions_show)
pal <- pv_palette("categorical", length(regions_show))
names(pal) <- regions_show

p <- ggplot2::ggplot(df, ggplot2::aes(dist_km, fst_linear, colour = region)) +
  ggplot2::geom_point(size = 1.05, alpha = 0.75)
if (isTRUE(show_regression) && isTRUE(by_region)) {
  p <- p + ggplot2::geom_smooth(
    method = "lm", formula = y ~ x, se = FALSE, linewidth = 0.45
  )
} else if (isTRUE(show_regression)) {
  p <- p + ggplot2::geom_smooth(
    method = "lm", formula = y ~ x, se = TRUE, linewidth = 0.5,
    colour = "black", inherit.aes = FALSE,
    ggplot2::aes(dist_km, fst_linear)
  )
}
p <- p +
  ggplot2::scale_colour_manual(values = pal, name = "Region") +
  ggplot2::labs(
    x = "Geographic distance (km)",
    y = expression(italic(F)[ST] / (1 - italic(F)[ST]))
  ) +
  theme_viz() +
  ggplot2::theme(legend.key = ggplot2::element_blank())

pv_save(p, "figure", width_mm = 140, height_mm = 95)
message("wrote preview.png")
