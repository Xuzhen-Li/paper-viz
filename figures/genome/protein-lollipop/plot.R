# Protein lollipop (house style): stems coloured by mutation class, class names in a key row, domains
# named on a grey band under the stems, hotspot as the in-panel stat. Reads data.csv and data_domains.csv.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_domains <- TRUE
class_levels <- c("Missense", "Nonsense", "Frameshift", "Inframe")

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
class_cols <- c(Missense = hp[["blue"]], Nonsense = hp[["red"]], Frameshift = hp[["purple"]],
                Inframe = hp[["orange"]])[class_levels]

mut <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
dom <- utils::read.csv("data_domains.csv", stringsAsFactors = FALSE)
mut$class <- factor(mut$class, levels = class_levels)
prot_end <- max(c(dom$end, mut$pos))
ymax <- max(mut$n)
hot <- mut[which.max(mut$n), ]

# key row: point + class name with its count, top left
cnt <- table(mut$class)
key <- data.frame(class = factor(class_levels, levels = class_levels),
                  x = prot_end * c(0.02, 0.16, 0.3, 0.46), y = ymax * 1.18)
key$lab <- sprintf("%s (%d)", class_levels, as.integer(cnt[class_levels]))

p <- ggplot() +
  geom_segment(data = mut, aes(x = pos, xend = pos, y = 0, yend = n), linewidth = pv_house_lw("ref"),
               colour = grey[["dark"]]) +
  geom_point(data = mut, aes(pos, n, fill = class), shape = 21, size = 1.8, stroke = 0.3, colour = "black") +
  geom_point(data = key, aes(x, y, fill = class), shape = 21, size = 1.8, stroke = 0.3, colour = "black") +
  geom_text(data = key, aes(x = x + prot_end * 0.008, y = y, label = lab), hjust = 0, size = pv_pt2size(7),
            colour = "#1A1A1A", family = house_family()) +
  annotate("text", x = hot$pos + prot_end * 0.012, y = hot$n, hjust = 0,
           label = sprintf("Hotspot p.%d, %d samples", hot$pos, hot$n), size = pv_pt2size(7),
           colour = "#1A1A1A", family = house_family()) +
  scale_fill_manual(values = class_cols, guide = "none") +
  scale_x_continuous(limits = c(0, prot_end), expand = c(0, 0), breaks = seq(0, prot_end, by = 100)) +
  scale_y_continuous(breaks = seq(0, ymax + 2, by = 4), expand = expansion(mult = c(0.02, 0.04))) +
  labs(x = "Amino acid position", y = "Mutated samples", caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 2.5, 1, 1, "mm")) + caption_theme

if (isTRUE(show_domains)) {
  p <- p +
    geom_rect(data = dom, aes(xmin = start, xmax = end, ymin = -0.3 * ymax, ymax = -0.06 * ymax),
              fill = grey[["light"]], colour = grey[["dark"]], linewidth = pv_house_lw("ref")) +
    geom_text(data = dom, aes(x = (start + end) / 2, y = -0.18 * ymax, label = domain), size = pv_pt2size(7),
              colour = "#1A1A1A", family = house_family()) +
    coord_cartesian(ylim = c(-0.32 * ymax, ymax * 1.24), clip = "off")
} else {
  p <- p + coord_cartesian(ylim = c(0, ymax * 1.24))
}

pv_save_house(p, "figure", cells = "4x1")
message("wrote preview.png")
