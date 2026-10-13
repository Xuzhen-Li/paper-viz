# TE composition (house style): stacked TE share per genome (class names beside the last bar) and
# Kimura divergence landscapes, one panel per genome with its total TE share. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# 可调参数 -----------------------------------------------------------------
show_stacked <- TRUE
show_landscape <- TRUE
class_order <- c("Gypsy", "Copia", "TIR", "LINE", "Helitron")

set.seed(1)   # fixed RNG state, so the figure never depends on the session
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# orange marks/labels use the darker chrom12 step of the same hue (#E17927, 3.01:1 on white)
hp[["orange"]] <- pv_palette("chrom12")[[8]]
# label text: the group colour if it reaches 3:1 contrast on white, else #1A1A1A (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  stats::setNames(ifelse(ratio >= 3, hex, "#1A1A1A"), names(hex))
}
caption_theme <- theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                                   lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
                       plot.caption.position = "plot")
# push end-of-line label positions apart to at least `gap` (data units), keeping their order
spread <- function(y, gap) {
  o <- order(y); z <- y[o]
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  shift <- mean(z) - mean(y[o]); z <- z - shift
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  y[o] <- z; y
}
df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
genome_order <- unique(df$genome)
df$genome <- factor(df$genome, levels = genome_order)
df$te_class <- factor(df$te_class, levels = class_order)
cols <- stats::setNames(c(hp[["blue"]], hp[["orange"]], hp[["green"]], hp[["purple"]], hp[["gold"]])[seq_along(class_order)],
                        class_order)
lab_cols <- text_col(cols)
df$percent <- df$fraction * 100

bar <- stats::aggregate(percent ~ genome + te_class, df, sum)
tot <- stats::aggregate(percent ~ genome, df, sum)

# class names beside the last bar, at the middle of its segments (pushed apart to >= 4.5 points)
last <- bar[bar$genome == genome_order[length(genome_order)], ]
last <- last[order(last$te_class, decreasing = TRUE), ]          # stacking order: first class on top
last$top <- cumsum(last$percent); last$mid <- last$top - last$percent / 2
last$y_lab <- spread(last$mid, 4.5)
nx <- length(genome_order)

p_bar <- ggplot(bar, aes(genome, percent, fill = te_class)) +
  geom_col(width = 0.72, colour = NA) +
  geom_segment(data = last, aes(x = nx + 0.4, xend = nx + 0.6, y = mid, yend = y_lab), inherit.aes = FALSE,
               linewidth = pv_house_lw("ref"), colour = grey[["dark"]]) +
  geom_text(data = last, aes(x = nx + 0.68, y = y_lab, label = te_class, colour = te_class), hjust = 0,
            size = pv_pt2size(7), family = house_family(), inherit.aes = FALSE) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = lab_cols, guide = "none") +
  scale_x_discrete(labels = function(v) sub(" ", "\n", v), expand = expansion(add = c(0.6, 2.2))) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  coord_cartesian(clip = "off") +
  labs(x = "Genome size", y = "Genome (%)") +
  theme_house() + theme(axis.text.x = element_text(angle = 0, hjust = 0.5, lineheight = 0.9, size = 7))

tot$lab <- sprintf("%s\nTE %.0f%%", tot$genome, tot$percent)
p_land <- ggplot(df, aes(divergence, percent, fill = te_class)) +
  geom_area(position = "stack", colour = NA) +
  geom_text(data = tot, aes(label = lab), x = Inf, y = Inf, hjust = 1.08, vjust = 1.25, lineheight = 0.95,
            size = pv_pt2size(7), colour = "#1A1A1A", family = house_family(), inherit.aes = FALSE) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.45))) +
  facet_wrap(~genome, ncol = 3) +
  labs(x = "Kimura divergence (%)", y = "Genome (%)") +
  theme_house() + theme(strip.text = element_blank(), panel.spacing = unit(2, "mm"))

note <- plot_annotation(caption = footnote, theme = theme_house() + caption_theme +
                          theme(plot.margin = margin(1, 1.5, 1, 1, "mm")))
if (isTRUE(show_stacked) && isTRUE(show_landscape)) {
  p <- (p_bar | p_land) + plot_layout(widths = c(1, 2.2)) + note
  cells <- "4x2"
} else if (isTRUE(show_stacked)) {
  p <- p_bar + note
  cells <- "2x2"
} else {
  p <- p_land + note
  cells <- "4x2"
}

pv_save_house(p, "figure", cells = cells, bump = 0)
message("wrote preview.png")
