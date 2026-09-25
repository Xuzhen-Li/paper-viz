# TE stacked fraction by genome and Kimura divergence landscapes.
source("../../../styles/r/theme_viz.R")

show_stacked <- TRUE
show_landscape <- TRUE
class_order <- c("Gypsy", "Copia", "TIR", "LINE", "Helitron")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
genome_order <- unique(df$genome)
df$genome <- factor(df$genome, levels = genome_order)
df$te_class <- factor(df$te_class, levels = class_order)
cols <- setNames(pv_palette("categorical", 5), class_order)
df$percent <- df$fraction * 100

bar <- aggregate(percent ~ genome + te_class, df, sum)

p_bar <- ggplot2::ggplot(bar, ggplot2::aes(genome, percent, fill = te_class)) +
  ggplot2::geom_col(width = 0.72, colour = NA) +
  ggplot2::scale_fill_manual(values = cols, name = NULL) +
  ggplot2::labs(x = NULL, y = "Genome (%)") +
  theme_viz() +
  ggplot2::theme(
    legend.key.size = ggplot2::unit(3, "mm"),
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)
  )

p_land <- ggplot2::ggplot(df, ggplot2::aes(divergence, percent, fill = te_class)) +
  ggplot2::geom_area(position = "stack", colour = NA, alpha = 0.95) +
  ggplot2::scale_fill_manual(values = cols, name = NULL) +
  ggplot2::facet_wrap(~genome, ncol = 3) +
  ggplot2::labs(x = "Kimura divergence (%)", y = "Genome (%)") +
  theme_viz() +
  ggplot2::theme(
    strip.background = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(size = 6),
    legend.position = "none"
  )

if (isTRUE(show_stacked) && isTRUE(show_landscape)) {
  p <- cowplot::plot_grid(p_bar, p_land, ncol = 1, rel_heights = c(1, 1.35), align = "v")
} else if (isTRUE(show_stacked)) {
  p <- p_bar
} else {
  p <- p_land
}

pv_save(p, "figure", width_mm = 183, height_mm = 140)
message("wrote preview.png")
