# Grouped densities with optional mode labels. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数
show_mode_labels <- TRUE
group_levels <- c("Line A", "Line B", "Line C", "Line D")
fill_alpha <- 0.22

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
cols <- setNames(pv_palette("categorical", nlevels(df$group)), group_levels)

modes <- do.call(rbind, lapply(group_levels, function(g) {
  d <- stats::density(df$value[df$group == g], n = 256)
  i <- which.max(d$y)
  data.frame(group = g, x = d$x[i], y = d$y[i], stringsAsFactors = FALSE)
}))

p <- ggplot2::ggplot(df, ggplot2::aes(value, colour = group, fill = group)) +
  ggplot2::geom_density(alpha = fill_alpha, linewidth = 0.55) +
  ggplot2::scale_colour_manual(values = cols, guide = "none") +
  ggplot2::scale_fill_manual(values = cols, name = NULL) +
  ggplot2::labs(x = "Measurement", y = "Density") +
  theme_viz() +
  ggplot2::theme(legend.position = "top")

if (show_mode_labels) {
  p <- p + ggrepel::geom_text_repel(
    data = modes,
    ggplot2::aes(x, y, label = group, colour = group),
    inherit.aes = FALSE,
    size = 2.1,
    direction = "y",
    min.segment.length = 0.2,
    segment.size = 0.2,
    box.padding = 0.25,
    show.legend = FALSE,
    seed = 45
  )
}

pv_save(p, "figure", width_mm = 110, height_mm = 75)
message("wrote preview.png")
