# Stacked area (house style). chart_mode: stack, stream, or percent.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

chart_mode <- "stack"
part_levels <- c("CD4 T", "CD8 T", "B cell", "NK", "Myeloid")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$part <- factor(df$part, levels = part_levels)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
pal <- stats::setNames(unname(hp[seq_along(part_levels)]), part_levels)
footnote <- "Simulated data for illustration; not biological results"

stack_bounds <- function(d, center) {
  parts <- levels(d$part)
  times <- sort(unique(d$time))
  out <- vector("list", length(times))
  for (i in seq_along(times)) {
    sub <- d[d$time == times[i], ]
    sub <- sub[match(parts, as.character(sub$part)), ]
    v <- sub$value
    top <- cumsum(v)
    bot <- c(0, utils::head(top, -1))
    if (center) {
      mid <- sum(v) / 2
      top <- top - mid
      bot <- bot - mid
    }
    out[[i]] <- data.frame(time = times[i], part = parts, ymin = bot, ymax = top)
  }
  do.call(rbind, out)
}

if (chart_mode == "percent") {
  y_lab <- "Share of cells"
  p <- ggplot2::ggplot(df, ggplot2::aes(time, value, fill = part)) +
    ggplot2::geom_area(position = "fill", colour = "white", linewidth = 0.15, alpha = 1) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(), expand = c(0, 0))
} else {
  center <- chart_mode == "stream"
  y_lab <- if (center) "Centered abundance" else "Cell abundance"
  bands <- stack_bounds(df, center = center)
  bands$part <- factor(bands$part, levels = part_levels)
  p <- ggplot2::ggplot(bands, ggplot2::aes(time, ymin = ymin, ymax = ymax, fill = part)) +
    ggplot2::geom_ribbon(colour = "white", linewidth = 0.15, alpha = 1) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.02, 0.04)))
}

p <- p +
  scale_fill_manual(values = pal, name = NULL) +
  scale_x_continuous(breaks = c(1, 10, 20, 30), expand = c(0, 0)) +
  labs(x = "Day", y = y_lab, caption = footnote) +
  theme_house() +
  theme(legend.position = "top", legend.justification = "left", legend.text = element_text(size = 7),
        plot.margin = margin(1, 3, 1, 1, unit = "mm"),
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
