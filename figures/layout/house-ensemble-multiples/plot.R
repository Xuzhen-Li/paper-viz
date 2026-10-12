# House example: 2 x 5 small multiples. Each panel: every replicate as a thin grey line,
# the regime mean in colour, regime name and n top-left, the trend (mean +- SE of per-replicate slopes)
# top-right, and a narrow side box of the final values. Shared x; y shared within a row; only outer
# x-axis labels; no strips.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)
w <- read.csv("data.csv", check.names = FALSE)   # wide: regime, replicate, g0..g80
gcols <- grep("^g[0-9]+$", names(w), value = TRUE)
d <- data.frame(regime = rep(w$regime, length(gcols)), replicate = rep(w$replicate, length(gcols)),
                generation = rep(as.integer(sub("g", "", gcols)), each = nrow(w)),
                shift_sd = unlist(w[gcols], use.names = FALSE))
grey <- pv_palette("house_grey")
regs <- unique(d$regime)
cols <- setNames(pv_palette("geo", length(regs)), regs)
lw <- pv_house_lw("main")

stats <- do.call(rbind, lapply(regs, function(r) {
  x <- d[d$regime == r, ]
  sl <- vapply(split(x, x$replicate), function(z) 10 * coef(lm(shift_sd ~ generation, z))[[2]], 0)
  fin <- vapply(split(x, x$replicate), function(z) mean(z$shift_sd[z$generation >= 71]), 0)
  data.frame(regime = r, n = length(sl), slope = mean(sl), se = sd(sl) / sqrt(length(sl)),
             q1 = quantile(fin, .25), med = median(fin), q3 = quantile(fin, .75),
             lo = min(fin), hi = max(fin), mean_fin = mean(fin))
}))
stopifnot(all(stats$n == tapply(d$replicate, d$regime, max)[stats$regime]))
mean_line <- aggregate(shift_sd ~ regime + generation, d, mean)

row_of <- setNames((seq_along(regs) - 1) %/% 2 + 1, regs)
ylims <- lapply(1:5, function(i) {
  v <- d$shift_sd[row_of[d$regime] == i]
  c(min(v) - 0.05 * diff(range(v)), max(v) + 0.32 * diff(range(v)))   # headroom for the panel text
})

panel <- function(r) {
  i <- row_of[[r]]; s <- stats[stats$regime == r, ]; yl <- ylims[[i]]; bottom <- i == 5
  main <- ggplot(d[d$regime == r, ], aes(generation, shift_sd)) +
    geom_line(aes(group = replicate), colour = grey[["ci"]], linewidth = pv_pt2lw(0.4)) +
    geom_line(data = mean_line[mean_line$regime == r, ], colour = cols[[r]], linewidth = lw) +
    annotate("text", x = 3, y = yl[2], hjust = 0, vjust = 1.25, lineheight = 0.95,
             label = sprintf("%s\nn = %d", r, s$n)) +
    annotate("text", x = 79, y = yl[2], hjust = 1, vjust = 1.25,
             label = sprintf("%+.3f \u00b1 %.3f SD per 10 gen", s$slope, s$se)) +
    scale_x_continuous(breaks = seq(0, 60, 20)) +   # no tick at 80: it would sit on the box divider
    coord_cartesian(xlim = c(0, 80), ylim = yl, expand = FALSE) +
    labs(x = if (bottom) "Generation" else NULL, y = NULL) +
    theme_house() +
    theme(plot.margin = margin(0, 0, 0, 0),
          axis.ticks.length.y = unit(1, "mm"),
          axis.text.x = if (bottom) element_text() else element_blank(),
          axis.ticks.length.x = unit(if (bottom) 1 else 0.6, "mm"))
  box <- ggplot(s) +
    geom_segment(aes(x = 0.5, xend = 0.5, y = lo, yend = hi), linewidth = pv_pt2lw(0.5)) +
    geom_rect(aes(xmin = 0.25, xmax = 0.75, ymin = q1, ymax = q3), fill = cols[[r]],
              colour = "black", linewidth = pv_pt2lw(0.5)) +
    geom_segment(aes(x = 0.25, xend = 0.75, y = med, yend = med), linewidth = pv_pt2lw(0.8)) +
    geom_point(aes(0.5, mean_fin), size = 0.7) +
    coord_cartesian(xlim = c(0, 1), ylim = yl, expand = FALSE) +
    labs(x = NULL, y = NULL) +
    theme_house() +
    theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks.x = element_blank(),
          axis.ticks.y = element_blank(), axis.ticks.length = unit(0, "mm"), plot.margin = margin(0, 0, 0, 0))
  list(main, box)
}
tiles <- unlist(lapply(regs, panel), recursive = FALSE)
grid <- wrap_plots(tiles, ncol = 4, widths = c(4.2, 0.9, 4.2, 0.9))
ytitle <- ggplot() + annotate("text", x = 0, y = 0, angle = 90, size = pv_pt2size(8),
                              family = house_family(), label = "Trait shift (phenotypic SD)") +
  theme_void() + theme(plot.margin = margin(0, 0, 0, 0))
fig <- (ytitle | grid) + plot_layout(widths = c(0.3, 10.2)) +
  plot_annotation(caption = paste("Side box: last 10 generations (71\u201380), one value per replicate;",
                                  "line = median, dot = mean. Simulated data for illustration; not biological results"),
                  theme = theme(plot.caption = element_text(hjust = 0, colour = grey[["mid"]], size = 7,
                                                            family = house_family()),
                                plot.margin = margin(1, 1, 1, 0.5, "mm")))
pv_save_house(fig, "figure", cells = "4x4")
