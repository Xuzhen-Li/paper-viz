# Grouped boxplot with pairwise brackets. Run from recipes/r.
set.seed(4)
source("../../styles/r/theme_viz.R")

df <- data.frame(
  group = rep(c("A", "B", "C"), each = 30),
  value = c(rnorm(30, 2, 0.6), rnorm(30, 3.2, 0.6), rnorm(30, 2.4, 0.5))
)
cols <- palette_viz(3)

p <- ggplot2::ggplot(df, ggplot2::aes(group, value, fill = group)) +
  ggplot2::geom_boxplot(width = 0.6, outlier.size = 0.6) +
  ggplot2::scale_fill_manual(values = cols, guide = "none") +
  ggpubr::stat_compare_means(comparisons = list(c("A", "B"), c("B", "C")), size = 2.2) +
  ggplot2::labs(x = NULL, y = "Value", tag = "c") +
  theme_viz()

ggplot2::ggsave(
  "../../gallery/grouped-boxplot-signif.png", p,
  width = 89 / 25.4, height = 75 / 25.4, dpi = 300
)
message("wrote ../../gallery/grouped-boxplot-signif.png")
