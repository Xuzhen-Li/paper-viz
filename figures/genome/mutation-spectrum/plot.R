# SBS96 spectrum (house style): six substitution classes of sixteen trinucleotide contexts each,
# class names on coloured bars above the panel, class shares as the in-panel stat. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
as_proportion <- FALSE
sub_levels <- c("C>A", "C>G", "C>T", "T>A", "T>G", "T>C")

set.seed(1)   # fixed RNG state, so the figure never depends on the session
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
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
# six classes in the usual SBS order of hues (blue, black, red, grey, green, pink -> house magenta)
sbs_cols <- stats::setNames(c(hp[["sky"]], grey[["text"]], hp[["red"]], grey[["ci"]], hp[["green"]], hp[["magenta"]]),
                            sub_levels)

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$substitution <- factor(df$substitution, levels = sub_levels)
flank <- c("A", "C", "G", "T")
ctx_of <- function(mid) paste0(rep(flank, each = 4), mid, rep(flank, times = 4))
df$context <- factor(df$context, levels = c(ctx_of("C"), ctx_of("T")))
df <- df[order(df$substitution, df$context), , drop = FALSE]
df$x <- seq_len(nrow(df))
df$y <- if (isTRUE(as_proportion)) df$count / sum(df$count) else df$count
y_lab <- if (isTRUE(as_proportion)) "Proportion of mutations" else "Mutation count"

share <- tapply(df$count, df$substitution, sum) / sum(df$count)
ann <- data.frame(substitution = factor(sub_levels, levels = sub_levels),
                  xmin = (seq_along(sub_levels) - 1) * 16 + 0.6, xmax = seq_along(sub_levels) * 16 + 0.4)
ann$x <- (ann$xmin + ann$xmax) / 2
ann$share <- sprintf("%.0f%%", 100 * share[sub_levels])
ymax <- max(df$y)
top <- ymax * 1.16

p <- ggplot(df, aes(x, y, fill = substitution)) +
  geom_col(width = 0.8, colour = NA) +
  # class bar + name above it (outside the panel), share inside the panel under the bar
  geom_rect(data = ann, aes(xmin = xmin, xmax = xmax, ymin = top, ymax = top + ymax * 0.05, fill = substitution),
            inherit.aes = FALSE) +
  geom_text(data = ann, aes(x = x, y = top + ymax * 0.07, label = substitution), vjust = 0,
            inherit.aes = FALSE, size = pv_pt2size(7), colour = "#1A1A1A", family = house_family()) +
  geom_text(data = ann, aes(x = x, y = top - ymax * 0.03, label = share), vjust = 1,
            inherit.aes = FALSE, size = pv_pt2size(7), colour = grey[["dark"]], family = house_family()) +
  scale_fill_manual(values = sbs_cols, guide = "none") +
  scale_x_continuous(expand = c(0.005, 0.005)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(ylim = c(0, top), clip = "off") +
  labs(x = "Trinucleotide context (16 per class)", y = y_lab, caption = footnote) +
  theme_house() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        plot.margin = margin(6, 1.5, 1, 1, "mm")) +
  caption_theme

pv_save_house(p, "figure", cells = "4x1")
message("wrote preview.png")
