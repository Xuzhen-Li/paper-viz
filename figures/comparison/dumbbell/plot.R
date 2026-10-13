# Dumbbell (house style): two stages per row joined by a grey segment with an optional arrow,
# stage names as a coloured key and the mean change written inside the panel (no legend).
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
use_arrow <- TRUE
sort_by <- "change" # change | week12 | input
colour_by_stage <- TRUE
stage_levels <- c("Baseline", "Week 12")

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue and red are both >= 3:1 on white, so the stage key keeps the point colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]]), stage_levels)
if (!isTRUE(colour_by_stage)) cols[] <- grey[["dark"]]
footnote <- "Simulated data for\nillustration; not\nbiological results"

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
wide$y <- seq_len(nrow(wide))
long <- rbind(
  data.frame(y = wide$y, stage = stage_levels[1], value = wide$baseline),
  data.frame(y = wide$y, stage = stage_levels[2], value = wide$week12)
)
long$stage <- factor(long$stage, levels = stage_levels)
arr <- if (use_arrow) grid::arrow(length = grid::unit(1.2, "mm"), type = "closed") else NULL
n <- nrow(wide)
x_lim <- range(long$value) + c(-0.05, 0.05) * diff(range(long$value))
key <- data.frame(stage = factor(stage_levels, levels = stage_levels), i = seq_along(stage_levels))
# stop the segment at the edge of the end point so the arrow head stays visible
gap <- 0.035 * diff(x_lim)
wide$xend <- ifelse(abs(wide$change) > 2 * gap, wide$week12 - sign(wide$change) * gap, wide$week12)
stat_lab <- sprintf("Mean change %+.1f\n%d of %d decrease", mean(wide$change), sum(wide$change < 0), n)

p <- ggplot() +
  geom_segment(data = wide, aes(x = baseline, xend = xend, y = y, yend = y),
               linewidth = pv_house_lw("minor"), colour = grey[["mid"]], arrow = arr) +
  geom_point(data = long, aes(value, y, fill = stage), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size,
             stroke = HOUSE_POINT$stroke, colour = "black") +
  geom_text(data = key, aes(x = x_lim[2] - 0.02 * diff(x_lim), y = 2.0 + 0.6 * (nrow(key) - i + 1),
                            label = stage, colour = stage), hjust = 1, vjust = 0) +
  annotate("text", x = x_lim[2] - 0.02 * diff(x_lim), y = 0.6, hjust = 1, vjust = 0, lineheight = 0.95,
           label = stat_lab) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_y_continuous(breaks = wide$y, labels = wide$item) +
  coord_cartesian(xlim = x_lim, ylim = c(0.4, n + 0.6), expand = FALSE) +
  labs(x = "Score", y = NULL, caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x2")
message("wrote preview.png")
