# Dumbbell of two stages, optional arrow. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数
use_arrow <- TRUE
sort_by <- "change" # change | week12 | input
colour_by_stage <- TRUE
stage_levels <- c("Baseline", "Week 12")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$stage <- factor(df$stage, levels = stage_levels)
wide <- reshape(df, idvar = "item", timevar = "stage", direction = "wide")
names(wide) <- c("item", "baseline", "week12")
wide$change <- wide$week12 - wide$baseline
if (sort_by == "change") {
  wide <- wide[order(wide$change), ]
} else if (sort_by == "week12") {
  wide <- wide[order(wide$week12), ]
}
wide$item <- factor(wide$item, levels = wide$item)
long <- rbind(
  data.frame(item = wide$item, stage = stage_levels[1], value = wide$baseline),
  data.frame(item = wide$item, stage = stage_levels[2], value = wide$week12)
)
long$stage <- factor(long$stage, levels = stage_levels)
cols <- setNames(pv_palette("categorical", 2), stage_levels)
arr <- if (use_arrow) grid::arrow(length = grid::unit(1.5, "mm"), type = "closed") else NULL

p <- ggplot2::ggplot() +
  ggplot2::geom_segment(
    data = wide,
    ggplot2::aes(x = baseline, xend = week12, y = item, yend = item),
    linewidth = 0.4,
    colour = "grey55",
    arrow = arr
  ) +
  ggplot2::geom_point(
    data = long,
    ggplot2::aes(value, item, colour = if (colour_by_stage) stage else NULL),
    size = 1.8
  ) +
  ggplot2::scale_colour_manual(values = cols, name = NULL) +
  ggplot2::labs(x = "Score", y = NULL) +
  theme_viz() +
  ggplot2::theme(legend.position = "top")

pv_save(p, "figure", width_mm = 110, height_mm = 115)
message("wrote preview.png")
