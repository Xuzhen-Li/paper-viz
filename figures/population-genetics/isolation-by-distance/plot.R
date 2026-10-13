# Isolation by distance (house style): linearised FST against geographic distance, one regression line
# per region; region names stacked top-left, steepest
# line first. Regions use the geo palette (north ->
# south). Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_regression <- TRUE
by_region <- TRUE
regions_show <- c("North", "Central", "South")
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
df <- df[df$region %in% regions_show, ]
df$region <- factor(df$region, levels = regions_show)
geo <- pv_palette("geo")
# spread the regions over the geo stops (no interpolated colours)
cols <- stats::setNames(geo[round(seq(2, length(geo), length.out = length(regions_show)))], regions_show)

p <- ggplot(df, aes(dist_km, fst_linear)) +
  geom_point(aes(fill = region), shape = HOUSE_POINT$shape, size = 0.9, stroke = HOUSE_POINT$stroke,
             colour = HOUSE_POINT$colour, alpha = 0.9)
if (isTRUE(show_regression) && isTRUE(by_region)) {
  p <- p + geom_smooth(aes(colour = region), method = "lm", formula = y ~ x, se = FALSE,
                       linewidth = pv_house_lw("main"))
} else {
  if (isTRUE(show_regression)) {
    p <- p + geom_smooth(method = "lm", formula = y ~ x, se = TRUE, linewidth = pv_house_lw("main"),
                         colour = grey[["dark"]], fill = grey[["ci"]])
  }
}
# names stacked in the empty top-left corner, steepest region first
slope <- vapply(split(df, df$region, drop = TRUE), function(d) stats::coef(stats::lm(fst_linear ~ dist_km, d))[[2]], 0)
lab <- names(sort(slope, decreasing = TRUE))
y_lab <- max(df$fst_linear) * (1.1 - 0.09 * (seq_along(lab) - 1))
p <- p +
  annotate("text", x = -Inf, y = y_lab, label = lab, hjust = -0.1, vjust = 1,
           colour = text_col(cols)[lab], size = pv_pt2size(7), family = house_family()) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_manual(values = cols, guide = "none") +
  labs(x = "Geographic distance (km)", y = "FST / (1 - FST)",
       caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 1.5, 1, 1, "mm")) + caption_theme

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
