# Stacked area. chart_mode: stack, stream, or percent.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

chart_mode <- "stack"
part_levels <- c("CD4 T", "CD8 T", "B cell", "NK", "Myeloid")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$part <- factor(df$part, levels = part_levels)
pal <- stats::setNames(pv_palette("categorical", length(part_levels)), part_levels)

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
    ggplot2::geom_area(position = "fill", colour = "white", linewidth = 0.15, alpha = 0.95) +
    ggplot2::scale_y_continuous(labels = scales::label_percent(), expand = c(0, 0))
} else {
  center <- chart_mode == "stream"
  y_lab <- if (center) "Centered abundance" else "Cell abundance"
  bands <- stack_bounds(df, center = center)
  bands$part <- factor(bands$part, levels = part_levels)
  p <- ggplot2::ggplot(bands, ggplot2::aes(time, ymin = ymin, ymax = ymax, fill = part)) +
    ggplot2::geom_ribbon(colour = "white", linewidth = 0.15, alpha = 0.95) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.02, 0.04)))
}

p <- p +
  ggplot2::scale_fill_manual(values = pal, name = NULL) +
  ggplot2::scale_x_continuous(breaks = c(1, 10, 20, 30), expand = c(0, 0)) +
  ggplot2::labs(x = "Day", y = y_lab) +
  theme_viz() +
  ggplot2::theme(
    legend.position = "right",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

pv_save(p, "figure", width_mm = 150, height_mm = 78)
message("wrote preview.png")
