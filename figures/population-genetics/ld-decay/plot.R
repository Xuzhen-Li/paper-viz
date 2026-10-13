# LD decay by population (house style): r^2 against distance in kb, loess curve per population,
# population names at the right end of each curve. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_loess <- TRUE
pops_show <- c("Wild N", "Landrace E", "Cultivar A", "Cultivar B")
log_x <- TRUE
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# label text: the group colour if it reaches 3:1 contrast on white (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  # below 3:1, use the darker step of the same hue where one exists in the house palettes
  # (orange -> chrom12 orange #E17927, 3.01:1); otherwise #1A1A1A
  darker <- c("#E17D52" = "#E17927", "#F77E12" = "#E17927")
  up <- toupper(hex)
  stats::setNames(ifelse(ratio >= 3, hex, ifelse(up %in% names(darker), darker[up], "#1A1A1A")),
                  names(hex))
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
df <- df[df$pop %in% pops_show, ]
df$pop <- factor(df$pop, levels = pops_show)
cols <- pop_cols[pops_show]

# names stacked in the empty top-right corner, in the same top-to-bottom order as the curves
# at the shortest distance (where they are furthest apart)
starts <- stats::aggregate(r2 ~ pop, df[df$dist_kb == min(df$dist_kb), ], mean)
ends <- data.frame(pop = starts$pop[order(-starts$r2)])
ends$y_lab <- 0.82 - 0.065 * (seq_len(nrow(ends)) - 1)

p <- ggplot(df, aes(dist_kb, r2, colour = pop)) +
  geom_point(size = 0.9, shape = 16, alpha = 0.8)
if (isTRUE(show_loess)) {
  p <- p + geom_smooth(method = "loess", formula = y ~ x, se = FALSE, span = 0.65,
                       linewidth = pv_house_lw("main"))
}
p <- p + if (isTRUE(log_x)) {
  scale_x_log10(breaks = c(1, 10, 100), labels = c("1", "10", "100"))
} else scale_x_continuous()
p <- p +
  annotate("text", x = Inf, y = ends$y_lab, label = as.character(ends$pop), hjust = 1.08,
           colour = text_col(cols)[as.character(ends$pop)], size = pv_pt2size(7), family = house_family()) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_y_continuous(limits = c(0, 0.85), expand = expansion(mult = c(0, 0.04))) +
    labs(x = "Distance (kb)", y = "LD (r\u00b2)", caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 1.5, 1, 1, "mm")) + caption_theme

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
