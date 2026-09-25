# Overlapping ridgelines with an optional quantile line. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数
ridge_scale <- 1.35
show_quantile <- TRUE
quantiles <- 0.5
sort_by_median <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
if (sort_by_median) {
  med <- tapply(df$value, df$group, stats::median)
  df$group <- factor(df$group, levels = names(sort(med)))
} else {
  df$group <- factor(df$group, levels = unique(df$group))
}
cols <- grDevices::colorRampPalette(pv_palette("categorical", 6))(nlevels(df$group))

p <- ggplot2::ggplot(df, ggplot2::aes(value, group, fill = group)) +
  ggridges::geom_density_ridges(
    scale = ridge_scale,
    rel_min_height = 0.03,
    quantile_lines = show_quantile,
    quantiles = quantiles,
    alpha = 0.85,
    colour = "white",
    linewidth = 0.25
  ) +
  ggplot2::scale_fill_manual(values = cols, guide = "none") +
  ggplot2::scale_y_discrete(expand = ggplot2::expansion(add = c(0.35, 2.4))) +
  ggplot2::labs(x = "Score", y = NULL) +
  theme_viz()

pv_save(p, "figure", width_mm = 100, height_mm = 120)
message("wrote preview.png")
