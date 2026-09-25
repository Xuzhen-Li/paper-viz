# Synthetic volcano. Run from recipes/r:
#   Rscript volcano.R
set.seed(1)
source("../../styles/r/theme_viz.R")

n <- 800
lfc <- rnorm(n, 0, 1.2)
pval <- 10^(-runif(n, 0.1, 6))
sig <- abs(lfc) > 1 & pval < 0.01
df <- data.frame(lfc = lfc, nlp = -log10(pval), sig = sig)
cols <- palette_viz(6)

p <- ggplot2::ggplot(df, ggplot2::aes(lfc, nlp, colour = sig)) +
  ggplot2::geom_point(size = 0.8, alpha = 0.7) +
  ggplot2::scale_colour_manual(values = c(`FALSE` = cols[6], `TRUE` = cols[5]), guide = "none") +
  ggplot2::geom_vline(xintercept = c(-1, 1), linetype = "dashed", linewidth = 0.3) +
  ggplot2::geom_hline(yintercept = -log10(0.01), linetype = "dashed", linewidth = 0.3) +
  ggplot2::labs(x = "log2 fold change", y = "-log10(p)") +
  theme_viz()

ggplot2::ggsave("../../gallery/volcano-r.png", p, width = 89 / 25.4, height = 70 / 25.4, dpi = 300)
message("wrote ../../gallery/volcano-r.png")
