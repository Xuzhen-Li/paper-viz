# Site frequency spectrum by population (house style): proportion of sites per allele-count bin,
# population names stacked in the empty top-right corner in curve order. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
use_folded <- TRUE
pops_show <- c("Wild N", "Landrace E", "Cultivar A")
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
# fixed house colour per population (same in every B2 figure)
pop_cols <- c("Wild N" = hp[["blue"]], "Wild S" = hp[["sky"]], "Landrace E" = hp[["green"]],
              "Landrace W" = hp[["gold"]], "Cultivar A" = hp[["red"]], "Cultivar B" = hp[["purple"]])

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$pop %in% pops_show & df$folded == as.integer(use_folded), ]
df$pop <- factor(df$pop, levels = pops_show)
df$prop <- ave(df$count, df$pop, FUN = function(x) x / sum(x))
cols <- pop_cols[pops_show]
x_lab <- if (isTRUE(use_folded)) "Minor allele count" else "Derived allele count"

# names in the order of the first bin (top to bottom)
first <- df[df$bin == min(df$bin), ]
labs_df <- data.frame(pop = as.character(first$pop[order(-first$prop)]))
top <- max(df$prop)
labs_df$y <- top * (1 - 0.085 * (seq_len(nrow(labs_df)) - 1))

p <- ggplot(df, aes(bin, prop, colour = pop)) +
  geom_line(linewidth = pv_house_lw("main")) +
  geom_point(size = 1.1, shape = 16) +
  annotate("text", x = Inf, y = labs_df$y, label = labs_df$pop, hjust = 1.08, vjust = 1,
           colour = text_col(cols)[labs_df$pop], size = pv_pt2size(7), family = house_family()) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(breaks = c(1, 5, 10, 15, 20)) +
  scale_y_continuous(expand = expansion(mult = c(0.04, 0.04))) +
  labs(x = x_lab, y = "Proportion of sites", caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 1.5, 1, 1, "mm")) + caption_theme

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
