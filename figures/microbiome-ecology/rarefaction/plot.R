# Rarefaction curves by group (house style), with a mean +/- SD ribbon. Group names written at the
# right end of each mean curve. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_individuals <- TRUE
show_ribbon <- TRUE
group_order <- c("Forest", "Cropland", "Grassland", "Wetland")
footnote <- "Simulated data;\nnot biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_order)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
cols <- stats::setNames(unname(hp[seq_along(group_order)]), group_order)
name_cols <- stats::setNames(ifelse(cols %in% hp[c("orange", "sky", "gold")], "#1A1A1A", cols), names(cols))

summ <- stats::aggregate(richness ~ group + depth, df, function(z) c(mean = mean(z), sd = stats::sd(z)))
summ <- do.call(data.frame, summ)
names(summ)[3:4] <- c("mean", "sd")
summ$ymin <- pmax(0, summ$mean - summ$sd)
summ$ymax <- summ$mean + summ$sd
ends <- summ[summ$depth == max(summ$depth), , drop = FALSE]

p <- ggplot()
if (isTRUE(show_ribbon)) {
  p <- p + geom_ribbon(data = summ, aes(depth, ymin = ymin, ymax = ymax, fill = group),
                       alpha = 0.18, colour = NA)
}
if (isTRUE(show_individuals)) {
  p <- p + geom_line(data = df, aes(depth, richness, group = sample, colour = group),
                     linewidth = pv_house_lw("minor"), alpha = 0.45)
}
p <- p +
  geom_line(data = summ, aes(depth, mean, colour = group), linewidth = pv_house_lw("main")) +
  geom_text(data = ends, aes(depth, mean, label = group), hjust = -0.08, size = pv_pt2size(7),
            colour = name_cols[as.character(ends$group)], family = house_family()) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_fill_manual(values = cols, guide = "none") +
  scale_x_continuous(breaks = function(l) pretty(l, n = 2),
                     labels = function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)) +
  coord_cartesian(clip = "off") +
  labs(x = "Reads", y = "Expected richness", caption = footnote) +
  theme_house() +
  theme(plot.margin = margin(1, 13, 1, 1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
