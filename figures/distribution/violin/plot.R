# Split or faceted violins (house style) with Wilcoxon P over brackets; group names written
# in their colour instead of a legend. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
layout <- "split" # split | facet
show_signif <- TRUE
group_levels <- c("Control", "Treated")
facet_levels <- c("Adjacent", "Tumor")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
df$facet <- factor(df$facet, levels = facet_levels)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue and red: both >= 3:1 on white, so the labels keep the group colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]]), group_levels)
footnote <- "Simulated data for illustration;\nnot biological results"
cap_theme <- theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                               margin = margin(t = 0.8, unit = "mm")),
                   plot.caption.position = "plot")
pw <- vapply(facet_levels, function(f) {
  stats::wilcox.test(value ~ group, data = droplevels(df[df$facet == f, ]))$p.value
}, numeric(1))
y_rng <- range(df$value) + c(-0.5, 0.45)   # room for the density tails
y_br <- y_rng[2] + 0.06 * diff(y_rng)
y_top <- y_rng[2] + 0.32 * diff(y_rng)

half_poly <- function(values, x0, side, width = 0.36, id = "a") {
  d <- stats::density(values, n = 128, from = min(values) - 0.2, to = max(values) + 0.2)
  y <- d$y / max(d$y) * width
  data.frame(x = c(x0, x0 + side * y, x0), y = c(d$x[1], d$x, d$x[length(d$x)]), id = id,
             stringsAsFactors = FALSE)
}

if (layout == "split") {
  polys <- list(); meds <- list()
  for (i in seq_along(facet_levels)) {
    for (j in seq_along(group_levels)) {
      sub <- df[df$facet == facet_levels[i] & df$group == group_levels[j], ]
      side <- if (j == 1) -1 else 1
      pid <- paste(facet_levels[i], group_levels[j])
      poly <- half_poly(sub$value, i, side, id = pid)
      poly$group <- group_levels[j]
      polys[[pid]] <- poly
      qs <- stats::quantile(sub$value, c(0.25, 0.5, 0.75))
      meds[[pid]] <- data.frame(x = i, xend = i + side * 0.16, y = qs, w = c(0.5, 0.8, 0.5))
    }
  }
  poly_df <- do.call(rbind, polys)
  poly_df$group <- factor(poly_df$group, levels = group_levels)
  med_df <- do.call(rbind, meds)
  med_df$w <- pv_house_lw(med_df$w)   # 0.5 pt quartiles, 0.8 pt median
  br <- data.frame(x = seq_along(facet_levels) - 0.28, xend = seq_along(facet_levels) + 0.28, y = y_br,
                   lab = vapply(pw, pv_fmt_p, character(1)))
  glab <- data.frame(group = factor(group_levels, levels = group_levels), x = 1.5 + c(-0.05, 0.05),
                     hj = c(1, 0))
  p <- ggplot() +
    geom_polygon(data = poly_df, aes(x, y, group = id, fill = group), colour = NA, alpha = 0.7) +
    geom_segment(data = med_df, aes(x = x, xend = xend, y = y, yend = y, linewidth = w), colour = "black") +
    scale_linewidth_identity() +
    geom_text(data = glab, aes(x = x, y = y_top, label = group, colour = group, hjust = hj), vjust = 1.2,
              fontface = "bold") +
    scale_x_continuous(breaks = seq_along(facet_levels), labels = facet_levels,
                       expand = expansion(add = 0.5))
} else {
  br <- data.frame(facet = factor(facet_levels, levels = facet_levels), x = 1, xend = 2, y = y_br,
                   lab = vapply(pw, pv_fmt_p, character(1)))
  p <- ggplot(df, aes(group, value, fill = group)) +
    geom_violin(scale = "width", trim = FALSE, colour = NA, alpha = 0.7) +
    geom_boxplot(width = 0.12, outlier.shape = NA, fill = "white", linewidth = pv_house_lw("ref")) +
    facet_wrap(~facet)
}
if (isTRUE(show_signif)) {
  p <- p +
    geom_segment(data = br, aes(x = x, xend = xend, y = y, yend = y), inherit.aes = FALSE,
                 linewidth = pv_house_lw("ref")) +
    geom_segment(data = br, aes(x = x, xend = x, y = y, yend = y - 0.04 * diff(y_rng)), inherit.aes = FALSE,
                 linewidth = pv_house_lw("ref")) +
    geom_segment(data = br, aes(x = xend, xend = xend, y = y, yend = y - 0.04 * diff(y_rng)), inherit.aes = FALSE,
                 linewidth = pv_house_lw("ref")) +
    geom_text(data = br, aes(x = (x + xend) / 2, y = y + 0.025 * diff(y_rng), label = lab), parse = TRUE,
              vjust = 0, inherit.aes = FALSE)
}
p <- p +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(ylim = c(y_rng[1], y_top)) +
  labs(x = NULL, y = "Expression (log2)", caption = footnote) +
  theme_house() + cap_theme

pv_save_house(p, "figure", cells = if (layout == "split") "1x1" else "2x1")
message("wrote preview.png")
