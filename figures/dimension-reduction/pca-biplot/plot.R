# PCA score scatter. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

point_size <- 1.6
point_alpha <- 0.85

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = unique(df$group))
cols <- pv_palette("categorical", nlevels(df$group))

p <- ggplot2::ggplot(df, ggplot2::aes(pc1, pc2, colour = group)) +
  ggplot2::geom_point(size = point_size, alpha = point_alpha) +
  ggplot2::scale_colour_manual(values = cols) +
  ggplot2::labs(x = "PC1", y = "PC2", colour = NULL) +
  theme_viz()

pv_save(p, "figure", width_mm = 89, height_mm = 70)
message("wrote preview.png")
