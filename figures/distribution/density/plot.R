# Grouped densities (house style): filled curves, group names at the peaks in the group colour,
# Kruskal-Wallis P in the panel. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
show_mode_labels <- TRUE
group_levels <- c("Line A", "Line B", "Line C", "Line D")
fill_alpha <- 0.25

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green, purple: all >= 3:1 on white, so peak labels keep the group colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]])[seq_along(group_levels)],
                        group_levels)
footnote <- "Simulated data for illustration; not biological results"

modes <- do.call(rbind, lapply(group_levels, function(g) {
  d <- stats::density(df$value[df$group == g], n = 512)
  i <- which.max(d$y)
  data.frame(group = factor(g, levels = group_levels), x = d$x[i], y = d$y[i])
}))
kw <- stats::kruskal.test(value ~ group, data = df)$p.value
y_top <- max(modes$y) * 1.22

p <- ggplot(df, aes(value, colour = group, fill = group)) +
  geom_density(alpha = fill_alpha, linewidth = pv_house_lw(1.4)) +
  annotate("text", x = -Inf, y = Inf, hjust = -0.06, vjust = 1.4, parse = TRUE,
           label = paste0("'Kruskal-Wallis '*", pv_fmt_p(kw))) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_fill_manual(values = cols, guide = "none") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, y_top), expand = c(0, 0)) +
  labs(x = "Measurement", y = "Density", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

if (isTRUE(show_mode_labels)) {
  p <- p + ggrepel::geom_text_repel(data = modes, aes(x, y, label = group, colour = group),
                                    inherit.aes = FALSE, nudge_y = 0.04 * y_top, direction = "x",
                                    min.segment.length = Inf, box.padding = 0.15, seed = 45,
                                    ylim = c(NA, y_top * 0.9))
} else {
  key <- data.frame(group = factor(group_levels, levels = group_levels), i = seq_along(group_levels))
  p <- p + geom_text(data = key, aes(x = Inf, y = Inf, label = group, colour = group), hjust = 1.08,
                     vjust = 1.4 * key$i, inherit.aes = FALSE)
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
