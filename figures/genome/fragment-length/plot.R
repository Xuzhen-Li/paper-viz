# Fragment-length histograms with density (house style), one stacked panel per library with its name
# and median length inside (or all libraries overlaid, names at the density peaks). Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
binwidth <- 5
xmax <- 500
facet_by_library <- TRUE   # FALSE: libraries overlaid in one panel (2x1)

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
df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
libs <- c("Ancient", "Nucleosome", "Modern")
df$library <- factor(df$library, levels = libs)
lib_cols <- c(Ancient = hp[["red"]], Nucleosome = hp[["gold"]], Modern = hp[["blue"]])
lab_cols <- text_col(lib_cols)

med <- stats::aggregate(length_bp ~ library, df, stats::median)
# density peak of each library (for the name position when the libraries share one panel)
pk <- do.call(rbind, lapply(split(df$length_bp, df$library), function(v) {
  d <- stats::density(v, from = 0, to = xmax)
  data.frame(x = d$x[which.max(d$y)], y = max(d$y))
}))
pk$library <- factor(rownames(pk), levels = libs)

p <- ggplot(df, aes(length_bp, fill = library, colour = library)) +
  geom_histogram(aes(y = after_stat(density)), binwidth = binwidth, boundary = 0,
                 alpha = 0.35, colour = NA) +
  geom_density(linewidth = pv_house_lw("main"), fill = NA) +
  scale_fill_manual(values = lib_cols, guide = "none") +
  scale_colour_manual(values = lib_cols, guide = "none") +
  scale_x_continuous(limits = c(0, xmax), breaks = seq(0, xmax, 100), expand = c(0, 0)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(x = "Fragment length (bp)", y = "Density", caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 2.5, 1, 1, "mm")) + caption_theme

if (isTRUE(facet_by_library)) {
  med$lab <- sprintf("%s\nmedian %d bp", med$library, round(med$length_bp))
  p <- p +
    geom_vline(data = med, aes(xintercept = length_bp), linetype = "22",
               linewidth = pv_house_lw("ref"), colour = grey[["dark"]]) +
    lapply(levels(med$library), function(l) {
      geom_text(data = med[med$library == l, ], aes(label = lab), x = Inf, y = Inf, hjust = 1.05,
                vjust = 1.3, lineheight = 0.95, colour = lab_cols[[l]], size = pv_pt2size(7),
                family = house_family(), inherit.aes = FALSE)
    }) +
    facet_wrap(~library, ncol = 1, scales = "free_y") +
    theme(strip.text = element_blank(), panel.spacing.y = unit(2, "mm"))
  cells <- "2x2"
} else {
  pk$lab <- sprintf("%s (median %d bp)", pk$library, round(med$length_bp[match(pk$library, med$library)]))
  p <- p + annotate("text", x = pk$x + 12, y = pk$y, label = pk$lab, hjust = 0, vjust = 0.2,
                    colour = lab_cols[as.character(pk$library)], size = pv_pt2size(7),
                    family = house_family())
  cells <- "2x1"
}

pv_save_house(p, "figure", cells = cells, bump = 0)
message("wrote preview.png")
