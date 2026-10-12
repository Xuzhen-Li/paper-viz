# Raincloud (house style): half density + narrow box + jittered shape-21 points, Wilcoxon P over
# brackets, n per group in the group colour. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
show_signif <- TRUE
use_facet <- FALSE
group_levels <- c("Ctrl", "Low", "Mid", "High")
comparisons <- list(c("Ctrl", "Low"), c("Mid", "High"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green, purple: all >= 3:1 on white, so n labels keep the group colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]],
                          hp[["brown"]], hp[["magenta"]])[seq_along(group_levels)], group_levels)
footnote <- "Simulated data for illustration; not biological results"
raw_point <- utils::modifyList(HOUSE_POINT, list(size = 1.4))
df$x <- as.numeric(df$group)
set.seed(42)
df$x_pt <- df$x - 0.2 + stats::runif(nrow(df), -0.07, 0.07)

half_poly <- function(values, x0, width = 0.36, id = "a") {
  d <- stats::density(values, n = 128, cut = 1.5)
  data.frame(x = c(x0 + d$y / max(d$y) * width, rep(x0, 128)), y = c(d$x, rev(d$x)), id = id)
}
poly_df <- do.call(rbind, lapply(seq_along(group_levels), function(i) {
  poly <- half_poly(df$value[df$group == group_levels[i]], i + 0.07, id = group_levels[i])
  poly$group <- factor(group_levels[i], levels = group_levels)
  poly
}))
st <- do.call(rbind, lapply(seq_along(group_levels), function(i) {
  y <- df$value[df$group == group_levels[i]]
  q <- stats::quantile(y, c(0.25, 0.5, 0.75)); iqr <- q[3] - q[1]
  data.frame(group = factor(group_levels[i], levels = group_levels), x = i, q1 = q[1], q2 = q[2],
             q3 = q[3], lo = max(min(y), q[1] - 1.5 * iqr), hi = min(max(y), q[3] + 1.5 * iqr),
             n = length(y))
}))
panel_of <- function(g) factor(ifelse(as.character(g) %in% group_levels[1:2], "Lower doses", "Higher doses"),
                               levels = c("Lower doses", "Higher doses"))
df$panel <- panel_of(df$group); poly_df$panel <- panel_of(poly_df$group); st$panel <- panel_of(st$group)
y_rng <- range(poly_df$y)
n_y <- y_rng[1] - 0.05 * diff(y_rng)
bw <- 0.05

p <- ggplot() +
  geom_polygon(data = poly_df, aes(x, y, group = id, fill = group), colour = NA, alpha = 0.6) +
  geom_point(data = df, aes(x_pt, value, fill = group), shape = raw_point$shape, size = raw_point$size,
             stroke = raw_point$stroke, colour = "black", alpha = 0.7) +
  geom_segment(data = st, aes(x = x, xend = x, y = lo, yend = hi), linewidth = pv_house_lw("ref")) +
  geom_rect(data = st, aes(xmin = x - bw, xmax = x + bw, ymin = q1, ymax = q3, fill = group),
            alpha = 0.6, colour = "black", linewidth = pv_house_lw("ref")) +
  geom_segment(data = st, aes(x = x - bw, xend = x + bw, y = q2, yend = q2), linewidth = pv_house_lw(0.8)) +
  geom_text(data = st, aes(x = x, y = n_y, label = paste0("n = ", n), colour = group), vjust = 0.5) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(breaks = seq_along(group_levels), labels = group_levels,
                     expand = expansion(add = c(0.45, 0.5))) +
  labs(x = NULL, y = "Response score", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

y_top <- y_rng[2]
if (isTRUE(show_signif)) {
  step <- diff(y_rng) * 0.1
  br <- do.call(rbind, lapply(seq_along(comparisons), function(i) {
    pair <- comparisons[[i]]
    sub <- df[df$group %in% pair, ]
    top <- max(poly_df$y[poly_df$group %in% pair])
    data.frame(x = match(pair[1], group_levels), xend = match(pair[2], group_levels), y = top + step * 0.6,
               panel = panel_of(pair[1]), label = pv_fmt_p(stats::wilcox.test(value ~ group, data = droplevels(sub))$p.value))
  }))
  y_top <- max(br$y) + step * 1.6
  p <- p +
    geom_segment(data = br, aes(x = x, xend = xend, y = y, yend = y), linewidth = pv_house_lw("ref")) +
    geom_segment(data = br, aes(x = x, xend = x, y = y, yend = y - step * 0.3), linewidth = pv_house_lw("ref")) +
    geom_segment(data = br, aes(x = xend, xend = xend, y = y, yend = y - step * 0.3),
                 linewidth = pv_house_lw("ref")) +
    geom_text(data = br, aes(x = (x + xend) / 2, y = y + step * 0.25, label = label), parse = TRUE,
              vjust = 0)
}
p <- p + scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(ylim = c(n_y - 0.06 * diff(y_rng), y_top))

if (isTRUE(use_facet)) {
  p <- p + facet_wrap(~panel, scales = "free_x")
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
