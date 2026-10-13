# ROH and IBD segment lengths by population (house style): violin + box per population, one row
# per segment kind. Population names on the x axis, so no legend. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
kinds_show <- c("ROH", "IBD")
pop_order <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")
log_y <- TRUE
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
df <- df[df$kind %in% kinds_show, ]
df$pop <- factor(df$pop, levels = pop_order)
df$kind <- factor(df$kind, levels = kinds_show)
cols <- pop_cols[pop_order]
y_breaks <- c(0.5, 1, 2, 5, 10, 20)

p <- ggplot(df, aes(pop, length_mb, fill = pop)) +
  geom_violin(scale = "width", width = 0.8, linewidth = pv_house_lw("minor"), colour = grey[["dark"]]) +
  geom_boxplot(width = 0.12, outlier.shape = NA, linewidth = pv_house_lw("minor"),
               fill = "white", colour = grey[["dark"]]) +
  facet_grid(kind ~ .) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_x_discrete(labels = function(x) sub(" ", "\n", x)) +
  labs(x = NULL, y = "Length (Mb)", caption = footnote) +
  theme_house() +
  theme(axis.text.x = element_text(lineheight = 0.9), strip.background = element_blank(), strip.text.y = element_text(size = 7, angle = 0, hjust = 0),
        plot.margin = margin(1, 1.5, 1, 1, "mm")) +
  caption_theme
p <- p + if (isTRUE(log_y)) scale_y_log10(breaks = y_breaks, labels = format(y_breaks, drop0trailing = TRUE, trim = TRUE)) else scale_y_continuous()

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
