# Cleveland dot plot: categories sorted by value, multi-group points.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

# 可调参数
sort_by_group <- "Urban"   # which group drives category order
show_segment <- TRUE       # light guide from min to max within row
point_size <- 2.0
group_levels <- c("Urban", "Rural")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
# Order categories by the chosen group's value (ascending = low at bottom)
ord_vals <- df$value[df$group == sort_by_group]
names(ord_vals) <- df$category[df$group == sort_by_group]
cat_order <- names(sort(ord_vals, decreasing = FALSE))
df$category <- factor(df$category, levels = cat_order)

cols <- setNames(pv_palette("categorical", length(group_levels)), group_levels)

# Per-category min/max for optional Cleveland guide segments
seg <- aggregate(value ~ category, data = df, FUN = function(x) c(min = min(x), max = max(x)))
seg <- data.frame(
  category = seg$category,
  xmin = seg$value[, "min"],
  xmax = seg$value[, "max"],
  stringsAsFactors = FALSE
)

p <- ggplot2::ggplot()
if (isTRUE(show_segment)) {
  p <- p + ggplot2::geom_segment(
    data = seg,
    ggplot2::aes(x = xmin, xend = xmax, y = category, yend = category),
    linewidth = 0.35,
    colour = "grey70"
  )
}
p <- p +
  ggplot2::geom_point(
    data = df,
    ggplot2::aes(value, category, colour = group),
    size = point_size
  ) +
  ggplot2::scale_colour_manual(values = cols, name = NULL) +
  ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.02, 0.06))) +
  ggplot2::labs(x = "Score", y = NULL) +
  theme_viz() +
  ggplot2::theme(legend.position = "top")

pv_save(p, "figure", width_mm = 100, height_mm = 110)
message("wrote preview.png")
