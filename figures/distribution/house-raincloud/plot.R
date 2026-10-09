# House-style raincloud: half violin + narrow box + jittered points, Wilcoxon P between neighbours.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

group_order <- c("Wild", "Wine", "Table")
violin_width <- 0.42
box_half_width <- 0.055
box_alpha <- 0.6     # box fill alpha 0.5–0.7
tail_cut <- 1.5      # density tails run tail_cut bandwidths past the data (tapered, not trimmed flat)
# jitter overlay (style-contract.md, points): HOUSE_POINT with size 1.6 (1.2–1.6), alpha 0.7
raw_point <- utils::modifyList(HOUSE_POINT, list(size = 1.6))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
pal <- pv_palette("house")
cols <- c(Wild = pal[["green"]], Wine = pal[["red"]], Table = pal[["blue"]])
df$x <- match(df$group, group_order)

hv <- do.call(rbind, lapply(group_order, function(g) {
  y <- df$heterozygosity_pct[df$group == g]
  dd <- stats::density(y, n = 256, cut = tail_cut)
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
# y range follows the full density tails, so no half violin is cut flat by the limits
# n labels get their own band under the lowest tail, centred on the group ticks
y_lo <- floor(min(hv$y)) - 3.5
n_y <- y_lo + 1.4
pw <- function(a, b) stats::wilcox.test(df$heterozygosity_pct[df$group == a],
                                        df$heterozygosity_pct[df$group == b])$p.value
top_of <- function(g) max(hv$y[hv$group %in% g], df$heterozygosity_pct[df$group %in% g])
br_y2 <- top_of(c("Wine", "Table")) + 1.6
br_y1 <- max(top_of(c("Wild", "Wine")) + 1.6, br_y2 + 3.4)
br <- data.frame(x0 = c(1, 2), x1 = c(2, 3), y = c(br_y1, br_y2),
                 lab = c(pv_fmt_p(pw("Wild", "Wine")), pv_fmt_p(pw("Wine", "Table"))))

p <- ggplot() +
  geom_polygon(data = hv, aes(x, y, group = group, fill = group), alpha = 0.6, colour = NA) +
  geom_point(data = df, aes(xj, heterozygosity_pct, fill = group), shape = raw_point$shape,
             size = raw_point$size, stroke = raw_point$stroke, colour = "black", alpha = 0.7) +
  geom_segment(data = st, aes(x = x, xend = x, y = lo, yend = hi), linewidth = pv_house_lw("ref")) +
  geom_rect(data = st, aes(xmin = x - box_half_width, xmax = x + box_half_width, ymin = q1, ymax = q3,
                           fill = group), alpha = box_alpha, colour = "black",
            linewidth = pv_house_lw("ref")) +
  geom_segment(data = st, aes(x = x - box_half_width, xend = x + box_half_width, y = q2, yend = q2),
               linewidth = pv_house_lw(0.8), colour = "black") +
  geom_segment(data = br, aes(x = x0, xend = x1, y = y, yend = y), linewidth = pv_house_lw("ref")) +
  geom_segment(data = br, aes(x = x0, xend = x0, y = y, yend = y - 0.8), linewidth = pv_house_lw("ref")) +
  geom_segment(data = br, aes(x = x1, xend = x1, y = y, yend = y - 0.8), linewidth = pv_house_lw("ref")) +
  geom_text(data = br, aes(x = (x0 + x1) / 2, y = y + 0.5, label = lab), parse = TRUE, vjust = 0,
            size = pv_pt2size(7)) +
  geom_text(data = st, aes(x = x, y = n_y, label = paste0("n = ", n), colour = group),
            size = pv_pt2size(6)) +
  scale_colour_manual(values = cols) +
  scale_fill_manual(values = cols) +
  scale_x_continuous(breaks = seq_along(group_order), labels = group_order, limits = c(0.55, 3.62),
                     expand = c(0, 0)) +
  scale_y_continuous(limits = c(y_lo, br_y1 + 3.6), breaks = seq(15, 45, 10), expand = c(0, 0)) +
  labs(x = NULL, y = "Heterozygosity (%)") +
  theme_house()

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
