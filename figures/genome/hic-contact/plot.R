# Hi-C contact map (house style): log colour on the warm house ramp, chromosome boundaries, share of
# intra-chromosomal (cis) contacts as the in-panel stat. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
log_color <- TRUE
show_chr_split <- TRUE

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
chr_of <- tapply(df$chr, df$bin_i, function(z) z[1])
chr_names <- unique(chr_of[order(as.integer(names(chr_of)))])
bin_n <- tapply(df$bin_i, df$chr, function(z) length(unique(z)))[chr_names]
bounds <- cumsum(bin_n)
mids <- (c(0, utils::head(bounds, -1)) + bounds) / 2
nb <- max(bounds)

df$fill <- if (isTRUE(log_color)) log10(df$count + 1) else df$count
leg <- if (isTRUE(log_color)) "log10(count + 1)" else "Count"
cis <- sum(df$count[chr_of[as.character(df$bin_i)] == chr_of[as.character(df$bin_j)]]) / sum(df$count)

p <- ggplot(df, aes(bin_j, bin_i, fill = fill)) +
  geom_raster() +
  scale_fill_gradientn(colours = pv_palette("house_warm"), name = leg) +
  scale_x_continuous(breaks = mids, labels = chr_names, expand = c(0, 0), position = "top") +
  scale_y_reverse(breaks = mids, labels = chr_names, expand = c(0, 0)) +
  coord_fixed(xlim = c(0.5, nb + 0.5), ylim = c(0.5, nb + 0.5), expand = FALSE, clip = "off") +
  annotate("text", x = 0.5, y = nb + 0.5 + nb * 0.035, label = sprintf("cis contacts %.0f%%", 100 * cis),
           hjust = 0, vjust = 1, colour = "#1A1A1A", size = pv_pt2size(7), family = house_family()) +
  labs(x = NULL, y = NULL, caption = footnote) +
  theme_house() +
  theme(legend.position = "bottom", legend.justification = "right",
        legend.title = element_text(size = 7, vjust = 0.85), legend.text = element_text(size = 7),
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1, "mm"),
        plot.margin = margin(1, 2, 1, 1, "mm")) +
  guides(fill = guide_colourbar(barwidth = unit(28, "mm"), barheight = unit(2.2, "mm"), ticks = FALSE)) +
  caption_theme

if (isTRUE(show_chr_split)) {
  edges <- utils::head(bounds, -1) + 0.5
  p <- p + geom_hline(yintercept = edges, linewidth = pv_house_lw("ref"), colour = grey[["dark"]]) +
    geom_vline(xintercept = edges, linewidth = pv_house_lw("ref"), colour = grey[["dark"]])
}

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
