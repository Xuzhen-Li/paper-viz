# LD decay. Reads data.csv. X axis is distance in kb.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_loess <- TRUE
pops_show <- c("Wild N", "Landrace E", "Cultivar A", "Cultivar B")
log_x <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$pop %in% pops_show, ]
df$pop <- factor(df$pop, levels = pops_show)
pal <- pv_palette("categorical", length(pops_show))
names(pal) <- pops_show

p <- ggplot2::ggplot(df, ggplot2::aes(dist_kb, r2, colour = pop, group = pop)) +
  ggplot2::geom_point(size = 1.15, alpha = 0.9)
if (isTRUE(show_loess)) {
  p <- p + ggplot2::geom_smooth(
    method = "loess", formula = y ~ x, se = FALSE, span = 0.65, linewidth = 0.45
  )
}
if (isTRUE(log_x)) {
  p <- p + ggplot2::scale_x_log10(
    breaks = c(1, 10, 100, 400),
    labels = c("1", "10", "100", "400")
  )
}
p <- p +
  ggplot2::scale_colour_manual(values = pal, name = "Population") +
  ggplot2::scale_y_continuous(limits = c(0, 0.85), expand = ggplot2::expansion(mult = c(0, 0.04))) +
  ggplot2::labs(x = "Distance (kb)", y = expression(italic(r)^2)) +
  theme_viz() +
  ggplot2::theme(legend.key = ggplot2::element_blank())

pv_save(p, "figure", width_mm = 140, height_mm = 90)
message("wrote preview.png")
