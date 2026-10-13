# Split violin (house style): two conditions as mirrored half densities with a median mark,
# condition names written over the first group in their colour, Wilcoxon P per group.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

group_levels <- c("Liver", "Lung", "Kidney", "Spleen")
condition_levels <- c("Control", "Treated")
half_width <- 0.36

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
df$condition <- factor(df$condition, levels = condition_levels)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue (left) and red (right): both >= 3:1 on white, so the labels keep the condition colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]]), condition_levels)
footnote <- "Simulated data for illustration; not biological results"

half_poly <- function(values, x0, side, width, id) {
  pad <- 0.25 * stats::sd(values)
  d <- stats::density(values, n = 128, from = min(values) - pad, to = max(values) + pad)
  dens <- d$y / max(d$y) * width
  poly <- data.frame(x = c(x0, x0 + side * dens, x0), y = c(d$x[1], d$x, d$x[length(d$x)]), id = id,
                     stringsAsFactors = FALSE)
  med <- stats::median(values)
  hw <- stats::approx(d$x, dens, xout = med, rule = 2)$y
  list(poly = poly, med = data.frame(x = x0, xend = x0 + side * hw * 0.92, y = med))
}

polys <- list()
meds <- list()
for (i in seq_along(group_levels)) {
  for (j in seq_along(condition_levels)) {
    sub <- df$value[df$group == group_levels[[i]] & df$condition == condition_levels[[j]]]
    pid <- paste(group_levels[[i]], condition_levels[[j]], sep = "|")
    built <- half_poly(sub, i, if (j == 1L) -1 else 1, half_width, pid)
    built$poly$condition <- condition_levels[[j]]
    polys[[pid]] <- built$poly
    meds[[pid]] <- built$med
  }
}
poly_df <- do.call(rbind, polys)
poly_df$condition <- factor(poly_df$condition, levels = condition_levels)
med_df <- do.call(rbind, meds)
y_rng <- range(poly_df$y)
pv <- do.call(rbind, lapply(seq_along(group_levels), function(i) {
  sub <- droplevels(df[df$group == group_levels[i], ])
  data.frame(x = i, y = max(poly_df$y[startsWith(poly_df$id, paste0(group_levels[i], "|"))]),
             lab = pv_fmt_p(stats::wilcox.test(value ~ condition, data = sub, exact = FALSE)$p.value))
}))
y_top <- y_rng[2] + 0.2 * diff(y_rng)
cond_lab <- data.frame(condition = factor(condition_levels, levels = condition_levels),
                       x = 1 + c(-0.06, 0.06), hj = c(1, 0))

p <- ggplot() +
  geom_polygon(data = poly_df, aes(x = x, y = y, group = id, fill = condition), colour = NA, alpha = 0.7) +
  geom_segment(data = med_df, aes(x = x, xend = xend, y = y, yend = y), linewidth = pv_house_lw(0.8),
               colour = "black", lineend = "butt") +
  geom_text(data = pv, aes(x = x, y = pmin(y + 0.04 * diff(y_rng), y_top - 0.13 * diff(y_rng)), label = lab),
            parse = TRUE, vjust = 0) +
  geom_text(data = cond_lab, aes(x = x, y = y_top - 0.02 * diff(y_rng), label = condition, colour = condition,
                                 hjust = hj), vjust = 1, fontface = "bold") +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(breaks = seq_along(group_levels), labels = group_levels,
                     expand = expansion(add = 0.5)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(ylim = c(y_rng[1] - 0.03 * diff(y_rng), y_top)) +
  labs(x = NULL, y = "Expression (log2)", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
