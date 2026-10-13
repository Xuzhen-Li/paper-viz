# Multiple sequence alignment (house style) with a conservation bar: residues tinted by class (class names
# in a key row above), residues that differ from the consensus outlined, mean conservation as the stat.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# 可调参数 -----------------------------------------------------------------
show_conservation <- TRUE
highlight_diff <- TRUE

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
df$seq <- factor(df$seq, levels = rev(unique(df$seq)))
class_of <- function(b) {
  ifelse(b %in% c("A", "V", "L", "I", "M", "F", "P", "W"), "hydrophobic",
    ifelse(b %in% c("S", "T", "N", "Q", "Y", "C"), "polar",
      ifelse(b %in% c("K", "R", "H"), "positive",
        ifelse(b %in% c("D", "E"), "negative", "other"))))
}
cls <- c("hydrophobic", "polar", "positive", "negative", "other")
df$class <- factor(class_of(df$base), levels = cls)
class_cols <- c(hydrophobic = hp[["blue"]], polar = hp[["green"]], positive = hp[["purple"]],
                negative = hp[["red"]], other = hp[["gold"]])
tint <- 0.45   # tile alpha, so black residue letters stay readable on every class colour

cons_base <- tapply(df$base, df$pos, function(x) names(sort(table(x), decreasing = TRUE))[1])
df$differs <- df$base != cons_base[as.character(df$pos)]
cons <- stats::aggregate(differs ~ pos, df, function(x) 1 - mean(x))
names(cons)[2] <- "conservation"
npos <- max(df$pos); nseq <- nlevels(df$seq)

# key row above the alignment: tinted swatch + class name
key <- data.frame(class = factor(cls, levels = cls), x = c(0.5, 7.5, 12.5, 18.5, 24.5))
p_aln <- ggplot(df, aes(pos, seq)) +
  geom_tile(aes(fill = class), alpha = tint, width = 1, height = 1) +
  geom_text(aes(label = base), size = pv_pt2size(7), colour = "#1A1A1A", family = house_family()) +
  geom_tile(data = key, aes(x = x + 0.5, y = nseq + 1.1, fill = class), width = 0.9, height = 0.7,
            alpha = tint, inherit.aes = FALSE) +
  geom_text(data = key, aes(x = x + 1.25, y = nseq + 1.1, label = class), hjust = 0, size = pv_pt2size(7),
            colour = "#1A1A1A", family = house_family(), inherit.aes = FALSE) +
  scale_fill_manual(values = class_cols, guide = "none") +
  scale_x_continuous(breaks = seq(5, npos, by = 5), expand = c(0, 0)) +
  scale_y_discrete(expand = expansion(add = c(0.5, 0))) +
  coord_cartesian(ylim = c(0.5, nseq + 1.6), clip = "off") +
  labs(x = NULL, y = NULL) +
  theme_house() + theme(axis.ticks.y = element_blank(), panel.border = element_blank())
if (isTRUE(highlight_diff)) {
  p_aln <- p_aln + geom_tile(data = df[df$differs, ], fill = NA, colour = grey[["text"]],
                             linewidth = pv_house_lw("ref"), width = 0.94, height = 0.94)
  key_d <- data.frame(x = 31.5, y = nseq + 1.1)
  p_aln <- p_aln + geom_tile(data = key_d, aes(x, y), width = 0.9, height = 0.7, fill = NA,
                             colour = grey[["text"]], linewidth = pv_house_lw("ref"), inherit.aes = FALSE) +
    annotate("text", x = 32.25, y = nseq + 1.1, label = "differs from consensus", hjust = 0,
             size = pv_pt2size(7), colour = "#1A1A1A", family = house_family())
}

note <- plot_annotation(caption = footnote, theme = theme_house() + caption_theme +
                          theme(plot.margin = margin(1, 1.5, 1, 1, "mm")))
if (!isTRUE(show_conservation)) {
  p <- p_aln + labs(x = "Position") + note
} else {
  p_aln <- p_aln + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
  p_bar <- ggplot(cons, aes(pos, conservation)) +
    geom_col(width = 0.9, fill = grey[["dark"]]) +
    annotate("text", x = npos + 0.4, y = 1.12, hjust = 1, vjust = 0,
             label = sprintf("mean conservation %.2f", mean(cons$conservation)),
             size = pv_pt2size(7), colour = "#1A1A1A", family = house_family()) +
    scale_x_continuous(breaks = seq(5, npos, by = 5), expand = c(0, 0), limits = c(0.5, npos + 0.5)) +
    scale_y_continuous(limits = c(0, 1.45), breaks = c(0, 1), expand = c(0, 0)) +
    labs(x = "Position", y = "Conservation") +
    theme_house()
  p <- (p_aln / p_bar) + plot_layout(heights = c(3, 1)) + note
}

pv_save_house(p, "figure", cells = "4x2")
message("wrote preview.png")
