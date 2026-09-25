# Ranked lollipops. Highlight can follow the signif column. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数
rank_items <- TRUE
highlight_signif <- TRUE
map_importance <- FALSE
signif_colour <- pv_palette("categorical", 4)[4]
base_colour <- pv_palette("categorical", 1)

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$signif <- as.logical(df$signif)
if (rank_items) {
  df <- df[order(df$value), ]
}
df$item <- factor(df$item, levels = df$item)
df$mark <- ifelse(highlight_signif & df$signif, "Marked", "Other")
cols <- c(Other = base_colour, Marked = signif_colour)
pt <- if (map_importance) pmax(1.2, df$value) else rep(1.9, nrow(df))

p <- ggplot2::ggplot(df, ggplot2::aes(value, item)) +
  ggplot2::geom_segment(
    ggplot2::aes(x = 0, xend = value, y = item, yend = item, colour = mark),
    linewidth = 0.4
  ) +
  ggplot2::geom_point(ggplot2::aes(colour = mark, size = pt)) +
  ggplot2::scale_colour_manual(values = cols, name = NULL) +
  ggplot2::scale_size_identity() +
  ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.06))) +
  ggplot2::labs(x = "Importance", y = NULL) +
  theme_viz() +
  ggplot2::theme(legend.position = "top")

pv_save(p, "figure", width_mm = 100, height_mm = 140)
message("wrote preview.png")
