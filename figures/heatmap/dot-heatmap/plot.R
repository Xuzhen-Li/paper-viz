# Dot heatmap (house style): fill = score on the house blue-red scale centred at 0, area = fraction;
# or scatter pies of three components. Colour bar and size key sit just right of the panel,
# the number of cells above and below 0 is written under the keys. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

mode <- "dot"
map_size <- TRUE

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration; not biological results"
cap_theme <- theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                               margin = margin(t = 0.8, unit = "mm")),
                   plot.caption.position = "plot")

if (mode == "pie") {
  pie <- utils::read.csv("data_pie.csv", stringsAsFactors = FALSE)
  comp <- c("Lymphoid", "Myeloid", "Stromal")
  # blue, red, green: all >= 3:1 on white, so the component names keep the slice colour
  comp_cols <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]]), comp)
  cl <- unique(pie$col); rl <- unique(pie$row)
  pie$x <- as.numeric(factor(pie$col, levels = cl))
  pie$y <- as.numeric(factor(pie$row, levels = rev(rl)))
  key <- data.frame(comp = factor(comp, levels = comp), i = seq_along(comp))
  p <- ggplot() +
    scatterpie::geom_scatterpie(aes(x = x, y = y, r = 0.2 + 0.25 * size), data = pie, cols = comp,
                                color = NA) +
    geom_text(data = key, aes(x = length(cl) + 0.75, y = length(rl) + 0.5 - (i - 1) * 0.9, label = comp,
                              colour = comp), hjust = 0, vjust = 1, inherit.aes = FALSE) +
    annotate("text", x = length(cl) + 0.75, y = length(rl) - 2.4, hjust = 0, vjust = 1, lineheight = 0.95,
             label = "Radius shows\ndetected\nfraction") +
    scale_fill_manual(values = comp_cols, guide = "none") +
    scale_colour_manual(values = comp_cols, guide = "none") +
    scale_x_continuous(breaks = seq_along(cl), labels = cl, limits = c(0.4, length(cl) + 4.6), expand = c(0, 0)) +
    scale_y_continuous(breaks = seq_along(rl), labels = rev(rl), limits = c(0.4, length(rl) + 0.6),
                       expand = c(0, 0)) +
    coord_fixed() +
    labs(x = NULL, y = NULL, caption = footnote) +
    theme_house() + cap_theme +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))
  pv_save_house(p, "figure", cells = "2x2")
  message("wrote preview.png")
  quit(save = "no", status = 0)
}

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$row <- factor(df$row, levels = rev(unique(df$row)))
df$col <- factor(df$col, levels = unique(df$col))
lim <- ceiling(max(abs(df$value)) * 2) / 2
stat_lab <- sprintf("Cells\n%d > 0\n%d < 0", sum(df$value > 0), sum(df$value < 0))
p <- ggplot(df, aes(col, row, fill = value))
if (isTRUE(map_size)) {
  p <- p + geom_point(aes(size = size), shape = 21, colour = grey[["dark"]], stroke = 0.3) +
    scale_size_area(max_size = 3.6, name = "Fraction", limits = c(0, 1), breaks = c(0.25, 0.5, 1))
} else {
  p <- p + geom_point(size = 3, shape = 21, colour = grey[["dark"]], stroke = 0.3)
}
p <- p +
  annotate("text", x = nlevels(df$col) + 1.05, y = 0.6, hjust = 0, vjust = 0, lineheight = 0.95,
           label = stat_lab) +
  coord_cartesian(clip = "off") +
  scale_fill_gradientn(colours = pv_palette("house_div"), limits = c(-lim, lim), name = "Score",
                       guide = guide_colourbar(order = 1,
                                               theme = theme(legend.key.width = unit(2, "mm"),
                                                             legend.key.height = unit(18, "mm")))) +
  guides(size = guide_legend(order = 2)) +
  labs(x = NULL, y = NULL, caption = footnote) +
  theme_house() + cap_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
        legend.position = "right", legend.box.spacing = unit(1, "mm"),
        legend.title = element_text(margin = margin(b = 1, unit = "mm")),
        legend.spacing.y = unit(3, "mm"))

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
