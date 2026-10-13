# Grouped boxplot (house style): semi-transparent boxes, jittered shape-21 points instead of outliers,
# Wilcoxon P over brackets and n per group written in the group colour. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

comparisons <- list(c("A", "B"), c("B", "C"))
show_points <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = unique(df$group))
g_lv <- levels(df$group)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green, purple: all >= 3:1 on white, so the n labels keep the group colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]], hp[["magenta"]],
                          hp[["brown"]])[seq_along(g_lv)], g_lv)
footnote <- "Simulated data for illustration; not biological results"

rng <- range(df$value)
step <- diff(rng) * 0.13
br <- do.call(rbind, lapply(seq_along(comparisons), function(i) {
  pair <- comparisons[[i]]
  pw <- stats::wilcox.test(value ~ group, data = droplevels(df[df$group %in% pair, ]))$p.value
  data.frame(x1 = match(pair[1], g_lv), x2 = match(pair[2], g_lv), y = rng[2] + step * (i - 0.3),
             label = pv_fmt_p(pw))
}))
tick <- step * 0.18
cnt <- data.frame(group = factor(g_lv, levels = g_lv), x = seq_along(g_lv),
                  lab = sprintf("n = %d", as.integer(table(df$group)[g_lv])))
y_lim <- c(rng[1] - step * 1.15, max(br$y) + step * 0.75)

set.seed(7)
p <- ggplot(df, aes(group, value)) +
  geom_boxplot(aes(fill = group), width = 0.55, alpha = 0.6, outlier.shape = NA,
               linewidth = pv_house_lw("frame"), colour = "black")
if (isTRUE(show_points)) {
  p <- p + geom_point(aes(fill = group), position = position_jitter(width = 0.12, height = 0),
                      shape = HOUSE_POINT$shape, size = 1.4, stroke = HOUSE_POINT$stroke,
                      colour = "black", alpha = 0.7)
}
p <- p +
  geom_segment(data = br, aes(x = x1, xend = x2, y = y, yend = y), inherit.aes = FALSE,
               linewidth = pv_house_lw("frame")) +
  geom_segment(data = br, aes(x = x1, xend = x1, y = y - tick, yend = y), inherit.aes = FALSE,
               linewidth = pv_house_lw("frame")) +
  geom_segment(data = br, aes(x = x2, xend = x2, y = y - tick, yend = y), inherit.aes = FALSE,
               linewidth = pv_house_lw("frame")) +
  geom_text(data = br, aes(x = (x1 + x2) / 2, y = y + step * 0.08, label = label), inherit.aes = FALSE,
            parse = TRUE, vjust = 0) +
  geom_text(data = cnt, aes(x = x, y = rng[1] - step * 0.75, label = lab, colour = group),
            inherit.aes = FALSE) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  coord_cartesian(ylim = y_lim, expand = FALSE) +
  labs(x = NULL, y = "Value", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
