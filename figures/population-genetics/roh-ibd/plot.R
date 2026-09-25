# ROH and IBD length distributions. Reads data.csv.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
kinds_show <- c("ROH", "IBD")
pop_order <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")
log_y <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$kind %in% kinds_show, ]
df$pop <- factor(df$pop, levels = pop_order)
df$kind <- factor(df$kind, levels = kinds_show)
pal <- pv_palette("categorical", length(pop_order))
names(pal) <- pop_order
y_breaks <- c(0.5, 1, 2, 5, 10, 20)

p <- ggplot2::ggplot(df, ggplot2::aes(pop, length_mb, fill = pop)) +
  ggplot2::geom_violin(scale = "width", linewidth = 0.25, colour = "grey20", alpha = 0.9) +
  ggplot2::geom_boxplot(
    width = 0.12, outlier.size = 0.25, linewidth = 0.25,
    fill = "white", colour = "grey20", alpha = 0.7, show.legend = FALSE
  ) +
  ggplot2::facet_grid(kind ~ .) +
  ggplot2::scale_fill_manual(values = pal, guide = "none") +
  ggplot2::labs(x = NULL, y = "Length (Mb)") +
  theme_viz() +
  ggplot2::theme(
    strip.background = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(size = 6.5, hjust = 0),
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1, vjust = 1)
  )
if (isTRUE(log_y)) {
  p <- p + ggplot2::scale_y_log10(breaks = y_breaks)
}

pv_save(p, "figure", width_mm = 160, height_mm = 120)
message("wrote preview.png")
