# Alluvial / Sankey. Highlight one label, rename axes, optional stratum bubbles.
# Run from this directory.
source("../../../styles/r/theme_viz.R")
library(ggalluvial)

highlight <- "CR"
axis_labels <- c("Cohort", "Subtype", "Response")
show_bubbles <- FALSE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$stage1 <- factor(df$stage1, levels = c("Control", "Case", "Treated"))
df$stage2 <- factor(df$stage2, levels = c("LumA", "LumB", "HER2", "Basal"))
df$stage3 <- factor(df$stage3, levels = c("CR", "PR", "SD", "PD", "NE"))
df$on <- df$stage1 == highlight | df$stage2 == highlight | df$stage3 == highlight
pal <- pv_palette("categorical", nlevels(df$stage1))
names(pal) <- levels(df$stage1)

p <- ggplot2::ggplot(
  df,
  ggplot2::aes(y = value, axis1 = stage1, axis2 = stage2, axis3 = stage3)
) +
  ggalluvial::geom_alluvium(
    ggplot2::aes(fill = stage1, alpha = on),
    width = 0.22, colour = NA, curve_type = "sigmoid"
  ) +
  ggalluvial::geom_stratum(width = 0.22, fill = "grey96", colour = "grey35", linewidth = 0.25) +
  ggplot2::geom_text(
    stat = "stratum",
    ggplot2::aes(label = after_stat(stratum)),
    size = 2.1
  ) +
  ggplot2::scale_x_discrete(limits = axis_labels, expand = ggplot2::expansion(add = 0.28)) +
  ggplot2::scale_fill_manual(values = pal, name = NULL) +
  ggplot2::scale_alpha_manual(values = c(`TRUE` = 0.9, `FALSE` = 0.22), guide = "none") +
  ggplot2::labs(x = NULL, y = "Patients") +
  theme_viz() +
  ggplot2::theme(legend.position = "none")

if (isTRUE(show_bubbles)) {
  p <- p + ggplot2::geom_point(
    stat = "stratum",
    ggplot2::aes(size = after_stat(y)),
    shape = 21, fill = "white", colour = "grey30"
  ) +
    ggplot2::scale_size_area(max_size = 6, guide = "none")
}

pv_save(p, "figure", width_mm = 170, height_mm = 110)
message("wrote preview.png")
