# Expression trends by cluster (house style). Single genes in light grey, cluster means in house
# colours. Faceted: one panel per cluster; overlaid: cluster names written at the line ends.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# --- adjustable ---
facet_clusters <- TRUE
show_smooth <- TRUE
# ------------------
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$cluster <- factor(df$cluster, levels = unique(df$cluster))
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
cols <- stats::setNames(unname(hp[seq_len(nlevels(df$cluster))]), levels(df$cluster))
# names written on white: the cluster colour when it is >= 3:1 on white, else #1A1A1A
name_cols <- stats::setNames(ifelse(cols %in% hp[c("orange", "sky", "gold")], "#1A1A1A", cols), names(cols))

mean_df <- stats::aggregate(value ~ cluster + time, df, mean)

p <- ggplot(df, aes(time, value, group = gene)) +
  geom_line(colour = grey[["light"]], linewidth = pv_house_lw("minor")) +
  scale_x_continuous(breaks = function(l) pretty(l, n = 4)) +
  labs(x = "Time (h)", y = "Expression (z)", caption = footnote) +
  theme_house() +
  theme(plot.margin = margin(1, 1, 1, 1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

if (isTRUE(show_smooth)) {
  p <- p + geom_line(data = mean_df, aes(time, value, colour = cluster, group = cluster),
                     linewidth = pv_house_lw("main"), inherit.aes = FALSE) +
    scale_colour_manual(values = cols, guide = "none")
}

if (isTRUE(facet_clusters)) {
  p <- p + facet_wrap(~cluster, ncol = 3) +
    theme(strip.background = element_blank(), panel.spacing = unit(1.5, "mm"))
} else if (isTRUE(show_smooth)) {
  ends <- mean_df[mean_df$time == max(mean_df$time), , drop = FALSE]
  p <- p + geom_text(data = ends, aes(time, value, label = cluster), inherit.aes = FALSE,
                     hjust = -0.1, size = pv_pt2size(7), colour = name_cols[as.character(ends$cluster)],
                     family = house_family()) +
    coord_cartesian(clip = "off") +
    theme(plot.margin = margin(1, 14, 1, 1, "mm"))
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
