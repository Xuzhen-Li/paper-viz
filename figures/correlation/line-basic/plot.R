# Line chart (house style): several noisy series, same-colour loess band, line-end labels,
# slope per series in the panel. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

series_keep <- c("Control", "Low dose", "High dose")
show_ribbon <- TRUE
show_area <- FALSE
show_points <- FALSE   # STYLE: points on the line only when a series has < 30 points

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$series %in% series_keep, , drop = FALSE]
df$series <- factor(df$series, levels = series_keep)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# reference series dark grey, treatments blue / red; all >= 3:1 on white, labels keep the line colour
pal <- stats::setNames(c(grey[["dark"]], hp[["blue"]], hp[["red"]], hp[["green"]],
                         hp[["purple"]])[seq_along(series_keep)], series_keep)
footnote <- "Simulated data for illustration; not biological results"

x_max <- max(df$x)
ends <- do.call(rbind, lapply(series_keep, function(s) {
  d <- df[df$series == s, ]
  fit <- stats::loess(y ~ x, data = d, span = 0.45)
  sl <- summary(stats::lm(y ~ x, data = d))$coefficients
  band <- stats::predict(fit, se = TRUE)
  data.frame(series = factor(s, levels = series_keep), y = stats::predict(fit, data.frame(x = x_max)),
             slope = sl[2, 1], se = sl[2, 2],
             lo = min(band$fit - stats::qt(0.975, band$df) * band$se.fit))
}))
# keep line-end labels at least 0.09 y-units apart
o <- order(ends$y); yy <- ends$y[o]
for (i in seq_along(yy)[-1]) yy[i] <- max(yy[i], yy[i - 1] + 0.14)
ends$ly[o] <- yy
ends$stat <- sprintf("%s %+.3f \u00b1 %.3f per day", ends$series, ends$slope, ends$se)
line_h <- 0.14   # y-units per stat line
y_lim <- c(min(df$y, ends$lo) - 0.03, max(df$y) + 0.05 + line_h * length(series_keep))

p <- ggplot(df, aes(x, y, colour = series, fill = series))
if (isTRUE(show_area)) {
  p <- p + geom_area(aes(group = series), alpha = 0.15, linewidth = 0, position = "identity")
}
if (isTRUE(show_ribbon)) {
  p <- p + geom_ribbon(stat = "smooth", method = "loess", formula = y ~ x, span = 0.45,
                       alpha = 0.2, colour = NA)
}
p <- p + geom_line(linewidth = pv_house_lw("main"))
if (isTRUE(show_points)) {
  p <- p + geom_point(shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
                      colour = "black")
}
p <- p +
  geom_text(data = ends, aes(x = x_max + 1, y = ly, label = series, colour = series), hjust = 0,
            inherit.aes = FALSE) +
  geom_text(data = ends, aes(x = 1, y = y_lim[2] - line_h * (as.integer(series) - 0.4), label = stat,
                             colour = series), hjust = 0, inherit.aes = FALSE) +
  scale_colour_manual(values = pal) +
  scale_fill_manual(values = pal) +
  scale_x_continuous(breaks = seq(0, 50, 10)) +
  coord_cartesian(xlim = c(0, x_max), ylim = y_lim, expand = FALSE, clip = "off") +
  labs(x = "Day", y = "Relative abundance", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot",
        plot.margin = margin(1.6, 13, 0.9, 0.4, "mm"))

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
