# Multi-group ECDF. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

line_width <- 0.55
show_legend <- TRUE
group_levels <- c("Group A", "Group B", "Group C")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
cols <- stats::setNames(pv_palette("categorical", nlevels(df$group)), group_levels)

p <- ggplot2::ggplot(df, ggplot2::aes(value, colour = group)) +
  ggplot2::stat_ecdf(linewidth = line_width, pad = FALSE) +
  ggplot2::scale_colour_manual(values = cols, name = NULL) +
  ggplot2::labs(x = "Value", y = "ECDF") +
  theme_viz()

if (!isTRUE(show_legend)) {
  p <- p + ggplot2::theme(legend.position = "none")
} else {
  p <- p + ggplot2::theme(legend.position = "top")
}

pv_save(p, "figure", width_mm = 110, height_mm = 75)
message("wrote preview.png")
