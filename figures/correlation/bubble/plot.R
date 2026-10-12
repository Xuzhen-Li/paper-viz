# Bubble chart (house style): point area = N, group colour, group names as a coloured key and
# a size key inside the panel. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

map_size <- TRUE
colour_by <- "group"     # group | size (size: house_warm sequential fill)
x_categorical <- FALSE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
group_order <- c("Liver", "Lung", "Kidney", "Brain")
df$group <- factor(df$group, levels = group_order)
if (isTRUE(x_categorical)) {
  df$x_plot <- cut(df$x, breaks = 4, labels = c("Q1", "Q2", "Q3", "Q4"))
} else {
  df$x_plot <- df$x
}
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# all four are >= 3:1 on white, so the key text keeps the group colour
pal <- c(Liver = hp[["blue"]], Lung = hp[["red"]], Kidney = hp[["green"]], Brain = hp[["purple"]])
footnote <- "Simulated data for illustration; not biological results"
df$sz <- if (isTRUE(map_size)) df$size else 25
max_d_mm <- 6   # STYLE §5: largest bubble <= 6 mm

p <- ggplot(df, aes(x_plot, y))
if (colour_by == "size") {
  p <- p + geom_point(aes(size = sz, fill = size), shape = 21, colour = grey[["dark"]],
                      stroke = HOUSE_POINT$stroke, alpha = 0.8) +
    scale_fill_gradientn(colours = pv_palette("house_warm"), name = "N", breaks = c(10, 30, 50),
                         guide = "legend")   # merged with the size key
} else {
  p <- p + geom_point(aes(size = sz, fill = group), shape = 21, colour = grey[["dark"]],
                      stroke = HOUSE_POINT$stroke, alpha = 0.8) +
    scale_fill_manual(values = pal, guide = "none")
  key <- data.frame(group = factor(group_order, levels = group_order), i = seq_along(group_order))
  key$lab <- sprintf("%s (n = %d)", group_order, as.integer(table(df$group)[group_order]))
  p <- p + geom_text(data = key, aes(x = -Inf, y = Inf, label = lab, colour = group),
                     hjust = -0.06, vjust = 1.4 * key$i, inherit.aes = FALSE) +
    scale_colour_manual(values = pal, guide = "none")
}
y_top <- max(df$y) * 1.30   # headroom for the keys
p <- p +
  scale_size_area(max_size = max_d_mm / 0.75 / 25.4 * 72 / .pt, name = "N",
                  breaks = c(10, 30, 50)) +
  scale_y_continuous(limits = c(-0.2, y_top), breaks = 0:4, expand = c(0, 0)) +
  labs(x = if (isTRUE(x_categorical)) "Effect-size quartile" else "Effect size",
       y = "-log10(P)", caption = footnote) +
  theme_house(legend = "inside") +
  theme(legend.direction = "horizontal", legend.title.position = "left",
        legend.key.spacing.x = unit(0.5, "mm"), legend.margin = margin(0, 0, 0, 0),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")
if (!isTRUE(x_categorical)) {
  p <- p + scale_x_continuous(limits = range(df$x) + c(-0.35, 0.35), expand = c(0, 0))
}

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
