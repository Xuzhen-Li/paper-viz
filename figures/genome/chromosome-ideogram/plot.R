# Plant chromosome ideogram with gene-density track (house style): density on the warm house ramp,
# centromeres black, NORs blue; colour bar and genome-wide mean density inside the empty lower right.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_density <- TRUE
show_band_labels <- TRUE

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
chr_levels <- sprintf("Chr%d", 8:1)
df$chr <- factor(df$chr, levels = chr_levels)
df$y <- as.numeric(df$chr) * 1.45

ideo <- df[df$feature == "chromosome", , drop = FALSE]
cen <- df[df$feature == "centromere", , drop = FALSE]
nor <- df[df$feature == "nor", , drop = FALSE]
dens <- df[df$feature == "density", , drop = FALSE]
h <- 0.3
nor_col <- hp[["blue"]]

p <- ggplot() +
  geom_rect(data = ideo, aes(xmin = start / 1e6, xmax = end / 1e6, ymin = y - h, ymax = y + h),
            fill = grey[["bg"]], colour = NA)
if (isTRUE(show_density)) {
  p <- p + geom_rect(data = dens, aes(xmin = start / 1e6, xmax = end / 1e6, ymin = y - h, ymax = y + h, fill = value),
                     colour = NA)
}
p <- p +
  geom_rect(data = ideo, aes(xmin = start / 1e6, xmax = end / 1e6, ymin = y - h, ymax = y + h),
            fill = NA, colour = grey[["text"]], linewidth = pv_house_lw("frame")) +
  geom_rect(data = cen, aes(xmin = start / 1e6, xmax = end / 1e6, ymin = y - h, ymax = y + h),
            fill = grey[["text"]], colour = NA) +
  geom_rect(data = nor, aes(xmin = start / 1e6, xmax = end / 1e6, ymin = y + h * 0.15, ymax = y + h),
            fill = nor_col, colour = NA)

if (isTRUE(show_band_labels)) {
  lab <- rbind(
    data.frame(x = (cen$start + cen$end) / 2 / 1e6, y = cen$y - h - 0.08, label = "CEN", vj = 1, col = "#1A1A1A"),
    data.frame(x = (nor$start + nor$end) / 2 / 1e6, y = nor$y + h + 0.08, label = "NOR", vj = 0,
               col = text_col(nor_col))
  )
  p <- p + geom_text(data = lab, aes(x, y, label = label, vjust = vj, colour = col), size = pv_pt2size(7),
                     family = house_family()) + scale_colour_identity()
}

xmax <- max(ideo$end) / 1e6
if (isTRUE(show_density)) {
  p <- p + annotate("text", x = xmax, y = 1.45 * 1 - h, hjust = 1, vjust = 0,
                    label = sprintf("Mean %.1f genes/Mb", mean(dens$value, na.rm = TRUE)),
                    colour = "#1A1A1A", size = pv_pt2size(7), family = house_family()) +
    scale_fill_gradientn(colours = pv_palette("house_warm"), name = "Genes / Mb") +
    guides(fill = guide_colourbar(direction = "horizontal", title.position = "top", ticks = FALSE,
                                  barwidth = unit(24, "mm"), barheight = unit(2, "mm")))
}

p <- p +
  scale_y_continuous(breaks = seq_along(chr_levels) * 1.45, labels = chr_levels,
                     expand = expansion(add = 0.45)) +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.02))) +
  labs(x = "Position (Mb)", y = NULL, caption = footnote) +
  theme_house() +
  theme(legend.position = "inside", legend.position.inside = c(1, 0.42),
        legend.justification.inside = c(1, 0.5), legend.background = element_blank(),
        legend.title = element_text(size = 7), legend.text = element_text(size = 7),
        axis.ticks.y = element_blank(), plot.margin = margin(1, 2, 1, 1, "mm")) +
  caption_theme

pv_save_house(p, "figure", cells = "4x2")
message("wrote preview.png")
