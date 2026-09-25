# Bump chart. Highlight named items; the rest stay grey. Direct labels, no legend.
source("../../../styles/r/theme_viz.R")

highlight_items <- c("TP53", "KRAS")
time_levels <- paste0("T", 1:6)

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$time <- factor(df$time, levels = time_levels)
df$item <- factor(df$item, levels = unique(df$item))
df$mark <- ifelse(df$item %in% highlight_items, as.character(df$item), "Other")
mark_levels <- c(highlight_items, "Other")
df$mark <- factor(df$mark, levels = mark_levels)
hi_cols <- pv_palette("categorical", length(highlight_items))
cols <- stats::setNames(c(hi_cols, "#B0B0B0"), mark_levels)
lw <- ifelse(df$mark == "Other", 0.35, 0.7)

ends <- df[df$time == time_levels[length(time_levels)], , drop = FALSE]

p <- ggplot2::ggplot(df, ggplot2::aes(time, rank, group = item, colour = mark)) +
  ggplot2::geom_line(ggplot2::aes(linewidth = lw)) +
  ggplot2::geom_point(size = 1.6) +
  ggplot2::geom_text(
    data = ends,
    ggplot2::aes(x = time, y = rank, label = item, colour = mark),
    hjust = -0.15, size = 2.05, show.legend = FALSE
  ) +
  ggplot2::scale_colour_manual(values = cols, guide = "none") +
  ggplot2::scale_linewidth_identity() +
  ggplot2::scale_y_reverse(breaks = 1:8, expand = ggplot2::expansion(add = 0.35)) +
  ggplot2::scale_x_discrete(expand = ggplot2::expansion(add = c(0.35, 1.15))) +
  ggplot2::labs(x = "Time point", y = "Rank") +
  theme_viz() +
  ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))

pv_save(p, "figure", width_mm = 150, height_mm = 92)
message("wrote preview.png")
