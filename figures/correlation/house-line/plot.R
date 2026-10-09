# House-style line chart: mean ± 95% CI ribbons, line-end labels, harvest difference in the panel.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

phase_start <- 63
phase_end <- 77
phase_label <- "Véraison"
compare <- c("Wine", "Table")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
pal <- pv_palette("house")
cols <- c(Wild = pal[["green"]], Wine = pal[["red"]], Table = pal[["blue"]])
grey <- pv_palette("house_grey")

key <- interaction(df$group, df$days_after_flowering, drop = TRUE)
sm <- do.call(rbind, lapply(split(df, key), function(x) {
  n <- nrow(x); m <- mean(x$brix); se <- stats::sd(x$brix) / sqrt(n)
  data.frame(group = x$group[1], daf = x$days_after_flowering[1], m = m, se = se,
             lo = m - stats::qt(0.975, n - 1) * se, hi = m + stats::qt(0.975, n - 1) * se, n = n)
}))
ends <- sm[sm$daf == max(sm$daf), ]
ends$y <- ends$m + c(Table = 0.5, Wild = -0.6, Wine = 0)[ends$group]
a <- ends[ends$group == compare[1], ]; b <- ends[ends$group == compare[2], ]
dlt <- a$m - b$m
pd <- 2 * stats::pt(-abs(dlt / sqrt(a$se^2 + b$se^2)), df = a$n + b$n - 2)
n_vines <- max(sm$n)

p <- ggplot(sm, aes(daf, m)) +
  annotate("rect", xmin = phase_start, xmax = phase_end, ymin = -Inf, ymax = Inf, fill = grey[["bg"]]) +
  annotate("text", x = (phase_start + phase_end) / 2, y = 2.3, vjust = 0, label = phase_label,
           size = pv_pt2size(6), colour = grey[["mid"]]) +
  geom_ribbon(aes(ymin = lo, ymax = hi, fill = group), alpha = 0.2) +
  geom_line(aes(colour = group), linewidth = pv_house_lw("main")) +
  geom_point(aes(fill = group), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size,
             stroke = HOUSE_POINT$stroke, colour = "black") +
  geom_text(data = ends, aes(x = daf + 2.5, y = y, label = group, colour = group), hjust = 0,
            size = pv_pt2size(7), fontface = "bold") +
  annotate("text", x = 20, y = 26.9, hjust = 0, vjust = 1, size = pv_pt2size(7),
           colour = cols[[compare[1]]], label = paste(compare[1], "\u2212", compare[2], "at harvest")) +
  annotate("text", x = 20, y = 24.7, hjust = 0, vjust = 1, size = pv_pt2size(7),
           colour = cols[[compare[1]]], parse = TRUE,
           label = sprintf("'%+.1f \u00b0Brix, '*%s", dlt, pv_fmt_p(pd))) +
  annotate("text", x = 136, y = 2.6, hjust = 1, vjust = 0, size = pv_pt2size(6), colour = grey[["mid"]],
           label = sprintf("Mean \u00b1 95%% CI\nn = %d vines per group", n_vines), lineheight = 0.9) +
  scale_colour_manual(values = cols) +
  scale_fill_manual(values = cols) +
  scale_x_continuous(breaks = seq(20, 120, 20)) +
  scale_y_continuous(breaks = seq(5, 25, 5)) +
  coord_cartesian(xlim = c(16, 138), ylim = c(2, 27.5), expand = FALSE) +
  labs(x = "Days after flowering", y = "Soluble solids (\u00b0Brix)") +
  theme_house()

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
