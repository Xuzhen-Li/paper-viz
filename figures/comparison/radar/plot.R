# Radar (house style): polygons in cartesian space so edges stay straight; group names with their
# mean score written as a coloured key inside the panel (no legend). Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
fill_polygon <- TRUE
facet_groups <- FALSE
axis_levels <- c("Growth", "Stress", "Yield", "Size", "Color", "Firm")
group_levels <- c("Line A", "Line B", "Line C", "Line D")
radius_max <- 100

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$axis <- factor(df$axis, levels = axis_levels)
df$group <- factor(df$group, levels = group_levels)
n_ax <- length(axis_levels)
ang_of <- function(axis) {
  pi / 2 - (as.numeric(axis) - 1) * 2 * pi / n_ax
}
df$x <- df$value * cos(ang_of(df$axis))
df$y <- df$value * sin(ang_of(df$axis))
closed <- do.call(rbind, lapply(split(df, df$group), function(g) rbind(g, g[1, ])))
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green, purple: all >= 3:1 on white, so the key keeps the line colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]], hp[["magenta"]],
                          hp[["brown"]])[seq_along(group_levels)], group_levels)
footnote <- "Simulated data for illustration; not biological results"
key <- data.frame(group = factor(group_levels, levels = group_levels), i = seq_along(group_levels))
key$m <- vapply(group_levels, function(g) mean(df$value[df$group == g]), numeric(1))
key$lab <- sprintf("%s  mean %.0f", key$group, key$m)

ring_n <- 160
rings <- do.call(rbind, lapply(c(25, 50, 75, 100), function(r) {
  a <- seq(0, 2 * pi, length.out = ring_n)
  data.frame(x = r * cos(a), y = r * sin(a), ring = r)
}))
spoke_a <- ang_of(factor(axis_levels, levels = axis_levels))
spokes <- data.frame(
  x = 0, y = 0,
  xend = radius_max * cos(spoke_a),
  yend = radius_max * sin(spoke_a)
)
lab_r <- radius_max + 12
labs <- data.frame(
  x = lab_r * cos(spoke_a),
  y = lab_r * sin(spoke_a),
  label = axis_levels,
  stringsAsFactors = FALSE
)

# ring values on the lower-left bisector between two axes, clear of the key
ring_a <- spoke_a[1] - pi + pi / n_ax
ring_lab <- data.frame(x = c(25, 50, 75, 100) * cos(ring_a), y = c(25, 50, 75, 100) * sin(ring_a),
                       label = c(25, 50, 75, 100))
lim <- 128

draw_one <- function(dat, with_key = TRUE) {
  g <- ggplot() +
    geom_path(data = rings, aes(x, y, group = ring), colour = grey[["light"]], linewidth = pv_house_lw("frame")) +
    geom_segment(data = spokes, aes(x = x, y = y, xend = xend, yend = yend), colour = grey[["light"]],
                 linewidth = pv_house_lw("frame")) +
    geom_text(data = ring_lab, aes(x, y, label = label), colour = grey[["mid"]], vjust = -0.3) +
    geom_polygon(data = dat, aes(x, y, group = group, colour = group, fill = group),
                 alpha = if (fill_polygon) 0.12 else 0, linewidth = pv_house_lw("main")) +
    geom_point(data = dat[!duplicated(interaction(dat$group, dat$axis)), ],
               aes(x, y, fill = group), shape = HOUSE_POINT$shape, size = 1.6, stroke = HOUSE_POINT$stroke,
               colour = "black") +
    geom_text(data = labs, aes(x, y, label = label))
  if (with_key) {
    g <- g + geom_text(data = key, aes(x = -lim, y = lim - (i - 1) * 13, label = lab, colour = group),
                       hjust = 0, vjust = 1)
  }
  g +
    scale_colour_manual(values = cols, guide = "none") +
    scale_fill_manual(values = cols, guide = "none") +
    scale_x_continuous(breaks = NULL) +
    scale_y_continuous(breaks = NULL) +
    coord_equal(xlim = c(-lim, lim), ylim = c(-lim, lim), expand = FALSE, clip = "off") +
    labs(x = NULL, y = NULL, caption = footnote) +
    theme_house() +
    theme(panel.border = element_blank(),
          plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                      margin = margin(t = 0.8, unit = "mm")),
          plot.caption.position = "plot")
}

if (facet_groups) {
  p <- draw_one(closed, with_key = FALSE) + facet_wrap(~group)
} else {
  p <- draw_one(closed)
}

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
