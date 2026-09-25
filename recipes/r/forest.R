# Synthetic forest plot. Run from recipes/r: Rscript forest.R
set.seed(2)
source("../../styles/r/theme_viz.R")

studies <- paste0("Study ", LETTERS[1:8])
loghr <- rnorm(8, 0.25, 0.35)
se <- runif(8, 0.12, 0.4)
df <- data.frame(
  study = factor(studies, levels = rev(studies)),
  hr = exp(loghr),
  lo = exp(loghr - 1.96 * se),
  hi = exp(loghr + 1.96 * se)
)
cols <- palette_viz(2)

p <- ggplot2::ggplot(df, ggplot2::aes(hr, study)) +
  ggplot2::geom_vline(xintercept = 1, linetype = "dashed", linewidth = 0.3) +
  ggplot2::geom_errorbarh(ggplot2::aes(xmin = lo, xmax = hi), height = 0.15, linewidth = 0.4) +
  ggplot2::geom_point(size = 2, colour = cols[1]) +
  ggplot2::scale_x_log10() +
  ggplot2::labs(x = "Hazard ratio", y = NULL) +
  theme_viz()

ggplot2::ggsave("../../gallery/forest.png", p, width = 89 / 25.4, height = 80 / 25.4, dpi = 300)
message("wrote ../../gallery/forest.png")
