# Mirrored or faceted histograms, optional density overlay. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数
layout <- "mirrored" # mirrored | facet
show_density <- TRUE
n_bins <- 26
group_levels <- c("Control", "Case")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
cols <- setNames(pv_palette("categorical", 2), group_levels)
breaks <- seq(min(df$value) - 0.2, max(df$value) + 0.2, length.out = n_bins + 1)
bin_w <- diff(breaks)[1]

hist_one <- function(values, group) {
  h <- graphics::hist(values, breaks = breaks, plot = FALSE)
  data.frame(
    group = group,
    x = h$mids,
    count = h$counts,
    stringsAsFactors = FALSE
  )
}
tabs <- do.call(rbind, lapply(group_levels, function(g) hist_one(df$value[df$group == g], g)))

dens_one <- function(values, group, sign = 1) {
  d <- stats::density(values, n = 200)
  data.frame(
    group = group,
    x = d$x,
    y = sign * d$y * sum(df$group == group) * bin_w,
    stringsAsFactors = FALSE
  )
}

if (layout == "mirrored") {
  tabs$y <- ifelse(tabs$group == group_levels[2], -tabs$count, tabs$count)
  p <- ggplot2::ggplot(tabs, ggplot2::aes(x, y, fill = group)) +
    ggplot2::geom_col(width = bin_w * 0.92, colour = NA) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::scale_fill_manual(values = cols, name = NULL) +
    ggplot2::labs(x = "Measurement", y = "Count") +
    theme_viz() +
    ggplot2::theme(legend.position = "top")
  if (show_density) {
    dens <- rbind(
      dens_one(df$value[df$group == group_levels[1]], group_levels[1], 1),
      dens_one(df$value[df$group == group_levels[2]], group_levels[2], -1)
    )
    p <- p + ggplot2::geom_line(
      data = dens,
      ggplot2::aes(x, y, colour = group),
      inherit.aes = FALSE,
      linewidth = 0.5
    ) +
      ggplot2::scale_colour_manual(values = cols, guide = "none")
  }
} else {
  p <- ggplot2::ggplot(tabs, ggplot2::aes(x, count, fill = group)) +
    ggplot2::geom_col(width = bin_w * 0.92, colour = NA, show.legend = FALSE) +
    ggplot2::facet_wrap(~group, ncol = 1) +
    ggplot2::scale_fill_manual(values = cols) +
    ggplot2::labs(x = "Measurement", y = "Count") +
    theme_viz()
  if (show_density) {
    dens <- do.call(rbind, lapply(group_levels, function(g) dens_one(df$value[df$group == g], g, 1)))
    p <- p + ggplot2::geom_line(
      data = dens,
      ggplot2::aes(x, y),
      inherit.aes = FALSE,
      linewidth = 0.5,
      colour = "grey20"
    )
  }
}

pv_save(p, "figure", width_mm = 89, height_mm = 85)
message("wrote preview.png")
