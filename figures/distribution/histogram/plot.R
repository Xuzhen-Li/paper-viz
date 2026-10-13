# Mirrored or faceted histograms (house style), optional density overlay in the group colour,
# group names and means written in the panel. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
layout <- "mirrored" # mirrored | facet
show_density <- TRUE
n_bins <- 26
group_levels <- c("Control", "Case")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue and red: both >= 3:1 on white, so the labels keep the group colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]]), group_levels)
footnote <- "Simulated data for illustration; not biological results"
breaks <- seq(min(df$value) - 0.2, max(df$value) + 0.2, length.out = n_bins + 1)
bin_w <- diff(breaks)[1]

hist_one <- function(values, group) {
  h <- graphics::hist(values, breaks = breaks, plot = FALSE)
  data.frame(group = group, x = h$mids, count = h$counts, stringsAsFactors = FALSE)
}
tabs <- do.call(rbind, lapply(group_levels, function(g) hist_one(df$value[df$group == g], g)))
tabs$group <- factor(tabs$group, levels = group_levels)
dens_one <- function(values, group, sign = 1) {
  d <- stats::density(values, n = 200)
  data.frame(group = group, x = d$x, y = sign * d$y * length(values) * bin_w, stringsAsFactors = FALSE)
}
info <- data.frame(group = factor(group_levels, levels = group_levels),
                   m = vapply(group_levels, function(g) mean(df$value[df$group == g]), numeric(1)),
                   s = vapply(group_levels, function(g) stats::sd(df$value[df$group == g]), numeric(1)),
                   n = as.integer(table(df$group)[group_levels]))
info$lab <- sprintf("%s: mean %.2f \u00b1 %.2f (n = %d)", info$group, info$m, info$s, info$n)
pw <- stats::wilcox.test(value ~ group, data = df)$p.value
cap_theme <- theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                               margin = margin(t = 0.8, unit = "mm")),
                   plot.caption.position = "plot")

if (layout == "mirrored") {
  tabs$y <- ifelse(tabs$group == group_levels[2], -tabs$count, tabs$count)
  ymax <- max(abs(tabs$y)) * 1.25
  info$y <- c(ymax, -ymax) * 0.97
  p <- ggplot(tabs, aes(x, y, fill = group)) +
    geom_col(width = bin_w, colour = "white", linewidth = pv_house_lw(0.3), alpha = 0.6) +
    geom_hline(yintercept = 0, linewidth = pv_house_lw("ref"))
  if (isTRUE(show_density)) {
    dens <- rbind(dens_one(df$value[df$group == group_levels[1]], group_levels[1], 1),
                  dens_one(df$value[df$group == group_levels[2]], group_levels[2], -1))
    p <- p + geom_line(data = dens, aes(x, y, colour = group), inherit.aes = FALSE,
                       linewidth = pv_house_lw(1.2))
  }
  p <- p +
    geom_text(data = info, aes(x = -Inf, y = y, label = lab, colour = group), hjust = -0.03,
              vjust = c(1, 0), inherit.aes = FALSE) +
    annotate("text", x = Inf, y = ymax * 0.97, hjust = 1.05, vjust = 1, parse = TRUE,
             label = paste0("'Wilcoxon '*", pv_fmt_p(pw))) +
    scale_y_continuous(limits = c(-ymax, ymax), labels = function(b) format(abs(b)), expand = c(0, 0))
} else {
  info$y <- max(tabs$count) * 1.3 * 0.97
  p <- ggplot(tabs, aes(x, count, fill = group)) +
    geom_col(width = bin_w, colour = "white", linewidth = pv_house_lw(0.3), alpha = 0.6) +
    facet_wrap(~group, ncol = 1) +
    theme(strip.text = element_blank())
  if (isTRUE(show_density)) {
    dens <- do.call(rbind, lapply(group_levels, function(g) dens_one(df$value[df$group == g], g, 1)))
    dens$group <- factor(dens$group, levels = group_levels)
    p <- p + geom_line(data = dens, aes(x, y, colour = group), inherit.aes = FALSE,
                       linewidth = pv_house_lw(1.2))
  }
  p <- p +
    geom_text(data = info, aes(x = -Inf, y = y, label = lab, colour = group), hjust = -0.03, vjust = 1, inherit.aes = FALSE) +
    scale_y_continuous(limits = c(0, max(tabs$count) * 1.3), expand = c(0, 0))
}
p <- p +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  labs(x = "Measurement", y = "Count", caption = footnote) +
  theme_house() + cap_theme
if (layout == "facet") p <- p + theme(strip.text = element_blank())

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
