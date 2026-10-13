# Pairwise FST heatmap (house style): house_warm sequential scale, values in the tiles, populations
# in the file's geographic order. Reads data.csv only (upper triangle; mirrored here).
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_values <- TRUE
pop_order <- c("WN1", "WN2", "WS1", "WS2", "LE1", "LE2", "LW1", "LW2", "CA1", "CA2", "CB1", "CB2")
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
# mirror the upper triangle stored in the file
swap <- df[df$pop_a != df$pop_b, ]
swap <- data.frame(pop_a = swap$pop_b, pop_b = swap$pop_a, fst = swap$fst, stringsAsFactors = FALSE)
df <- rbind(df, swap)
df$pop_a <- factor(df$pop_a, levels = pop_order)
df$pop_b <- factor(df$pop_b, levels = rev(pop_order))
df$label <- sprintf("%.2f", df$fst)
warm <- pv_palette("house_warm")
lims <- c(0, max(df$fst))
# tile text: white or #1A1A1A, whichever has the higher contrast on that tile's own fill
# (fill computed the same way scale_fill_gradientn does), so every value reads at >= 4.5:1;
rel_lum <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  colSums(c(0.2126, 0.7152, 0.0722) * v)
}
tile_fill <- scales::gradient_n_pal(warm)(scales::rescale(df$fst, from = lims))
l_fill <- rel_lum(tile_fill)
on_white <- 1.05 / (l_fill + 0.05)
on_dark <- (l_fill + 0.05) / (rel_lum("#1A1A1A") + 0.05)
on_black <- (l_fill + 0.05) / 0.05
# #1A1A1A where it reaches 4.5:1; on mid-tone tiles where neither it nor white does,
# house_grey text (#000000)
df$txt <- ifelse(on_dark >= 4.5, "#1A1A1A", ifelse(on_white >= on_black, "white", "#000000"))
df$txt_contrast <- ifelse(df$txt == "#1A1A1A", on_dark, pmax(on_white, on_black))

p <- ggplot(df, aes(pop_a, pop_b, fill = fst)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  scale_fill_gradientn(colours = warm, limits = lims, name = "FST",
                       breaks = function(l) pretty(l, n = 3)) +
  scale_colour_identity() +
  guides(fill = guide_colourbar(title.position = "top",
                                theme = theme(legend.key.width = unit(30, "mm"),
                                              legend.key.height = unit(2.2, "mm"),
                                              legend.title = element_text(size = 7, margin = margin(b = 0.8, unit = "mm"))))) +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  coord_cartesian() +
  labs(x = NULL, y = NULL, caption = footnote) +
  theme_house() +
  theme(axis.ticks = element_blank(),
        legend.position = "bottom", legend.justification = "right",
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1.5, "mm"),
        legend.title = element_text(size = 7),
        legend.text = element_text(size = 7),

        plot.margin = margin(1, 1, 1, 1, "mm")) +
  caption_theme
if (isTRUE(show_values)) {
  p <- p + geom_text(aes(label = label, colour = txt), size = pv_pt2size(7), family = house_family(),
                     show.legend = FALSE)
}

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
