# Grouped bars (house style): series side by side, value on each bar, series names as a coloured
# key inside the panel (no legend), mean ratio of the last to the first series written in the panel.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

bar_width <- 0.72
dodge_width <- 0.8
show_legend <- TRUE    # coloured series key inside the panel
show_values <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = unique(df$group))
df$series <- factor(df$series, levels = unique(df$series))
s_lv <- levels(df$series)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue, red, green, purple: all >= 3:1 on white, so key text keeps the bar colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]])[seq_along(s_lv)], s_lv)
footnote <- "Simulated data for illustration; not biological results"
y_top <- max(df$value) * 1.32

first <- df[df$series == s_lv[1], ]; last <- df[df$series == s_lv[length(s_lv)], ]
ratio <- mean(last$value[match(first$group, last$group)] / first$value)

pd <- position_dodge(width = dodge_width)
p <- ggplot(df, aes(group, value, fill = series)) +
  geom_col(width = bar_width, position = pd, colour = NA)
if (isTRUE(show_values)) {
  p <- p + geom_text(aes(label = sprintf("%.1f", value), group = series), position = pd, vjust = -0.4)
}
if (isTRUE(show_legend)) {
  key <- data.frame(series = factor(s_lv, levels = s_lv), i = seq_along(s_lv))
  p <- p + geom_text(data = key, aes(x = 0.56, y = y_top * (0.97 - 0.09 * (i - 1)), label = series,
                                     colour = series),
                     hjust = 0, vjust = 1, inherit.aes = FALSE)
}
p <- p +
  annotate("text", x = nlevels(df$group) + 0.44, y = y_top * 0.97, hjust = 1, vjust = 1,
           label = sprintf("Mean %s / %s = %.2f", s_lv[length(s_lv)], s_lv[1], ratio)) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  scale_y_continuous(limits = c(0, y_top), expand = c(0, 0)) +
  scale_x_discrete(expand = expansion(add = 0.5)) +
  labs(x = NULL, y = "Value", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
