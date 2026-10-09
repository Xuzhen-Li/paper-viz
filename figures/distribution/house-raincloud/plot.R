# House-style raincloud: half violin + narrow box + jittered points, Wilcoxon P between neighbours.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

group_order <- c("Wild", "Wine", "Table")
violin_width <- 0.42
box_half_width <- 0.055

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
pal <- pv_palette("house")
cols <- c(Wild = pal[["green"]], Wine = pal[["red"]], Table = pal[["blue"]])
df$x <- match(df$group, group_order)

hv <- do.call(rbind, lapply(group_order, function(g) {
  dd <- stats::density(df$heterozygosity_pct[df$group == g], n = 256)
  data.frame(group = g, y = c(dd$x, rev(dd$x)),
             x = c(dd$y / max(dd$y) * violin_width, rep(0, 256)) + match(g, group_order) + 0.08)
}))
set.seed(7)
df$xj <- df$x - 0.22 + stats::runif(nrow(df), -0.09, 0.09)
st <- do.call(rbind, lapply(group_order, function(g) {
  y <- df$heterozygosity_pct[df$group == g]
  q <- stats::quantile(y, c(0.25, 0.5, 0.75)); iqr <- q[3] - q[1]
  data.frame(group = g, x = match(g, group_order), q1 = q[1], q2 = q[2], q3 = q[3],
             lo = max(min(y), q[1] - 1.5 * iqr), hi = min(max(y), q[3] + 1.5 * iqr), n = length(y))
}))
pw <- function(a, b) stats::wilcox.test(df$heterozygosity_pct[df$group == a],
                                        df$heterozygosity_pct[df$group == b])$p.value
br <- data.frame(x0 = c(1, 2), x1 = c(2, 3), y = c(44.5, 41.2),
                 lab = c(pv_fmt_p(pw("Wild", "Wine")), pv_fmt_p(pw("Wine", "Table"))))

p <- ggplot() +
  geom_polygon(data = hv, aes(x, y, group = group, fill = group), alpha = 0.6, colour = NA) +
  geom_point(data = df, aes(xj, heterozygosity_pct, fill = group), shape = 21, size = 1.45,
             stroke = 0.25, colour = "black", alpha = 0.75) +
  geom_segment(data = st, aes(x = x, xend = x, y = lo, yend = hi), linewidth = pv_house_lw("ref")) +
  geom_rect(data = st, aes(xmin = x - box_half_width, xmax = x + box_half_width, ymin = q1, ymax = q3,
                           fill = group), colour = "black", linewidth = pv_house_lw("ref")) +
  geom_segment(data = st, aes(x = x - box_half_width, xend = x + box_half_width, y = q2, yend = q2),
               linewidth = pv_house_lw(0.9), colour = "white") +
  geom_segment(data = br, aes(x = x0, xend = x1, y = y, yend = y), linewidth = pv_house_lw("ref")) +
  geom_segment(data = br, aes(x = x0, xend = x0, y = y, yend = y - 0.8), linewidth = pv_house_lw("ref")) +
  geom_segment(data = br, aes(x = x1, xend = x1, y = y, yend = y - 0.8), linewidth = pv_house_lw("ref")) +
  geom_text(data = br, aes(x = (x0 + x1) / 2, y = y + 0.5, label = lab), parse = TRUE, vjust = 0,
            size = pv_pt2size(7)) +
  geom_text(data = st, aes(x = x - 0.2, y = 12.6, label = paste0("n = ", n), colour = group),
            size = pv_pt2size(6)) +
  scale_colour_manual(values = cols) +
  scale_fill_manual(values = cols) +
  scale_x_continuous(breaks = seq_along(group_order), labels = group_order, limits = c(0.55, 3.62),
                     expand = c(0, 0)) +
  scale_y_continuous(limits = c(11, 48.5), breaks = seq(15, 45, 10), expand = c(0, 0)) +
  labs(x = NULL, y = "Heterozygosity (%)") +
  theme_house() +
  theme(axis.text.x = element_text(colour = cols[group_order]))

pv_save_house(p, "figure", width = "single", height_mm = 74)
message("wrote preview.png")
