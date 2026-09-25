# Diverging bars centered at zero. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数
sort_bars <- TRUE
center_at_zero <- TRUE
class_levels <- c("Decreased", "Increased")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$class <- factor(df$class, levels = class_levels)
if (sort_bars) {
  df$item <- factor(df$item, levels = df$item[order(df$value)])
} else {
  df$item <- factor(df$item, levels = rev(unique(df$item)))
}
cols <- setNames(pv_palette("diverging", 7)[c(1, 7)], class_levels)

p <- ggplot2::ggplot(df, ggplot2::aes(value, item, fill = class)) +
  ggplot2::geom_col(width = 0.72) +
  ggplot2::geom_vline(xintercept = if (center_at_zero) 0 else stats::median(df$value), linewidth = 0.3) +
  ggplot2::scale_fill_manual(values = cols, name = NULL) +
  ggplot2::scale_x_continuous(labels = function(x) paste0(x, "%")) +
  ggplot2::labs(x = "Change from baseline", y = NULL) +
  theme_viz() +
  ggplot2::theme(legend.position = "top")

pv_save(p, "figure", width_mm = 110, height_mm = 125)
message("wrote preview.png")
