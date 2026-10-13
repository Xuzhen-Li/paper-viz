# ADMIXTURE stacked bars (house style): one row per K, individuals grouped by population and sorted by
# their main ancestry at sort_k; ancestry components in house colours, row titles K = n on the left,
# population names under the bars (no legend: components are unnamed model clusters).
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
k_values <- 2:6
sort_k <- 4
pop_gap <- 3
pop_order <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")

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
# populations ordered by geography (mean sampling latitude, north -> south) on the geo palette
pop_geo <- stats::setNames(pv_palette("geo"),
                           c("Wild N", "Cultivar A", "Landrace W", "Landrace E", "Cultivar B", "Wild S"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
sub <- df[df$k == sort_k, ]
means <- aggregate(q ~ pop + ancestry, sub, mean)
dom <- do.call(rbind, lapply(split(means, means$pop), function(m) m[which.max(m$q), ]))
key <- merge(sub, dom[, c("pop", "ancestry")], by = c("pop", "ancestry"))
key <- key[order(match(key$pop, pop_order), -key$q), ]
pos <- data.frame(sample = key$sample, pop = key$pop, stringsAsFactors = FALSE)
pos$pop <- factor(pos$pop, levels = pop_order)
pos$within <- ave(seq_len(nrow(pos)), pos$pop, FUN = seq_along)
n_max <- max(pos$within)
pos$x <- pos$within + (as.integer(pos$pop) - 1) * (n_max + pop_gap)
mids <- aggregate(x ~ pop, pos, mean)

plot_df <- merge(df[df$k %in% k_values, ], pos[, c("sample", "x")], by = "sample")
plot_df$k_lab <- factor(paste0("K = ", plot_df$k), levels = paste0("K = ", k_values))
anc_levels <- paste0("A", seq_len(max(k_values)))
plot_df$ancestry <- factor(plot_df$ancestry, levels = anc_levels)
pal <- stats::setNames(pv_palette("house", length(anc_levels)), anc_levels)

p <- ggplot(plot_df, aes(x, q, fill = ancestry)) +
  geom_col(width = 1, colour = NA, linewidth = 0) +
  facet_grid(k_lab ~ ., switch = "y") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_x_continuous(
    breaks = mids$x, labels = as.character(mids$pop),
    expand = expansion(add = 0.8)
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.06, 0.03)),
    breaks = c(0, 1)
  ) +
  labs(x = NULL, y = "Ancestry proportion", caption = footnote) +
  theme_house() +
  theme(
    strip.background = element_blank(), strip.placement = "outside",
    strip.text.y.left = element_text(size = 7, angle = 0, hjust = 1),
    panel.spacing.y = unit(1.5, "mm"),
    axis.ticks.x = element_blank(),
    plot.margin = margin(1, 1.5, 1, 1, "mm")
  ) +
  caption_theme

pv_save_house(p, "figure", cells = "4x2")
message("wrote preview.png")
