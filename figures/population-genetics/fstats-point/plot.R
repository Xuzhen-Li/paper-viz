# f / D point range. Reads data.csv. Example numbers are on the D scale.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_ci <- TRUE
z_cut <- 3
statistic <- "D"
order_by_estimate <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$class <- ifelse(
  abs(df$z) < z_cut, "ns",
  ifelse(df$estimate >= 0, "positive", "negative")
)
if (isTRUE(order_by_estimate)) {
  df$test <- factor(df$test, levels = df$test[order(df$estimate)])
}
pal <- c(ns = "#6B6B6B", positive = pv_palette("categorical", 1), negative = pv_palette("categorical", 4)[4])
x_lab <- switch(statistic,
  f3 = "f3 statistic",
  f4 = "f4 statistic",
  "D statistic"
)

p <- ggplot2::ggplot(df, ggplot2::aes(estimate, test, colour = class)) +
  ggplot2::geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.3)
if (isTRUE(show_ci)) {
  p <- p + ggplot2::geom_errorbar(
    ggplot2::aes(xmin = low, xmax = high),
    width = 0.18, linewidth = 0.3, orientation = "y"
  )
}
p <- p +
  ggplot2::geom_point(size = 1.4) +
  ggplot2::scale_colour_manual(
    values = pal,
    breaks = c("positive", "negative", "ns"),
    labels = c(sprintf("Z >= %g", z_cut), sprintf("Z <= -%g", z_cut), sprintf("|Z| < %g", z_cut)),
    name = NULL
  ) +
  ggplot2::labs(x = x_lab, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    legend.key = ggplot2::element_blank(),
    legend.position = "bottom",
    axis.text.y = ggplot2::element_text(size = 5.5)
  )

pv_save(p, "figure", width_mm = 160, height_mm = 150)
message("wrote preview.png")
