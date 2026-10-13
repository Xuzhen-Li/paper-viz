# Overlapping ridgelines (house style) for more than four groups: one fill colour, white outline,
# median line in each ridge, median value printed at the right. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数
ridge_scale <- 1.35
show_quantile <- TRUE
quantiles <- 0.5
sort_by_median <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
if (sort_by_median) {
  med <- tapply(df$value, df$group, stats::median)
  df$group <- factor(df$group, levels = names(sort(med)))
} else {
  df$group <- factor(df$group, levels = unique(df$group))
}
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
footnote <- "Simulated data for\nillustration; not\nbiological results"
meds <- data.frame(group = levels(df$group),
                   m = vapply(levels(df$group), function(g) stats::median(df$value[df$group == g]), numeric(1)))
meds$y <- seq_len(nrow(meds))
x_hi <- max(df$value) + 1.3
bw <- mean(vapply(split(df$value, df$group), stats::bw.nrd0, numeric(1)))   # one joint bandwidth

p <- ggplot(df, aes(value, group)) +
  ggridges::geom_density_ridges(scale = ridge_scale, bandwidth = bw, rel_min_height = 0.01, quantile_lines = show_quantile,
                                quantiles = quantiles, fill = hp[["blue"]], alpha = 0.55, colour = "white",
                                linewidth = pv_house_lw("ref"), vline_colour = "black",
                                vline_width = pv_house_lw(0.8)) +
  geom_text(data = meds, aes(x = x_hi, y = y + 0.25, label = sprintf("%.2f", m)), hjust = 1, vjust = 0) +
  annotate("text", x = x_hi, y = nrow(meds) + 0.85, hjust = 1, vjust = 0, label = "Median") +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_discrete(expand = expansion(add = c(0.2, 1.25))) +
  coord_cartesian(xlim = c(min(df$value) - 0.2, x_hi + 0.1)) +
  labs(x = "Score", y = NULL, caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x2")
message("wrote preview.png")
