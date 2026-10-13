# Multi-group ECDF (house style): step lines, dashed median guide, group names with medians as a
# coloured key inside the panel. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

line_width <- pv_house_lw("main")   # 1.5 pt
show_legend <- TRUE                  # coloured key (group name + median) inside the panel
group_levels <- c("Group A", "Group B", "Group C")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green: all >= 3:1 on white, so the key keeps the group colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]])[seq_along(group_levels)],
                        group_levels)
footnote <- "Simulated data for illustration;\nnot biological results"
med <- data.frame(group = factor(group_levels, levels = group_levels), i = seq_along(group_levels),
                  m = vapply(group_levels, function(g) stats::median(df$value[df$group == g]), numeric(1)))
med$lab <- sprintf("%s  %.2f", med$group, med$m)

p <- ggplot(df, aes(value, colour = group)) +
  geom_hline(yintercept = 0.5, linetype = "22", linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  stat_ecdf(linewidth = line_width, pad = FALSE) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.5, 1), expand = expansion(add = 0.02)) +
  labs(x = "Value", y = "Cumulative fraction", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

x0 <- min(df$value)
if (isTRUE(show_legend)) {
  p <- p +
    annotate("text", x = x0, y = Inf, label = "Median", hjust = 0, vjust = 1.4) +
    geom_text(data = med, aes(x = x0, y = Inf, label = lab, colour = group), hjust = 0,
              vjust = 1.4 + 1.25 * med$i, inherit.aes = FALSE)
}

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
