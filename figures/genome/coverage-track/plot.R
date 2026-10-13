# Stacked locus tracks (house style): depth, ATAC, RNA and copy-number segments, track names inside the
# panels, CN written on each non-diploid segment. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# 可调参数 -----------------------------------------------------------------
show_depth <- TRUE
show_atac <- TRUE
show_rna <- TRUE
show_cnv <- TRUE

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
df$mb <- df$pos / 1e6
xr <- range(df$mb)
track_cols <- c(Depth = hp[["blue"]], ATAC = hp[["purple"]], RNA = hp[["green"]])

track_theme <- function(bottom = FALSE) {
  th <- theme_house() + theme(plot.margin = margin(0.6, 1.5, 0.6, 1, "mm"))
  if (!bottom) th <- th + theme(axis.title.x = element_blank(), axis.text.x = element_blank())
  th
}
x_scale <- list(scale_x_continuous(expand = c(0, 0)), coord_cartesian(xlim = xr))

signal_panel <- function(trk, ylab, stat, bottom) {
  sub <- df[df$track == trk, , drop = FALSE]
  ggplot(sub, aes(mb, value)) +
    geom_area(fill = track_cols[[trk]], alpha = 0.35, colour = NA) +
    geom_line(colour = track_cols[[trk]], linewidth = pv_house_lw("minor")) +
    annotate("text", x = xr[1] + 0.01 * diff(xr), y = Inf, hjust = 0, vjust = 1.3,
             label = sprintf("%s  %s", trk, stat(sub$value)), colour = text_col(track_cols)[[trk]],
             size = pv_pt2size(7), family = house_family()) +
    x_scale + scale_y_continuous(expand = expansion(mult = c(0, 0.35))) +
    labs(x = "Position on Chr5 (Mb)", y = ylab) + track_theme(bottom)
}

panels <- list(); heights <- numeric()
if (isTRUE(show_depth)) {
  panels[[length(panels) + 1L]] <- signal_panel("Depth", "Depth (x)", function(v) sprintf("(mean %.0fx)", mean(v)),
                                                !isTRUE(show_atac) && !isTRUE(show_rna) && !isTRUE(show_cnv))
  heights <- c(heights, 1)
}
if (isTRUE(show_atac)) {
  panels[[length(panels) + 1L]] <- signal_panel("ATAC", "Signal", function(v) sprintf("(max %.0f)", max(v)),
                                                !isTRUE(show_rna) && !isTRUE(show_cnv))
  heights <- c(heights, 1)
}
if (isTRUE(show_rna)) {
  panels[[length(panels) + 1L]] <- signal_panel("RNA", "Signal", function(v) sprintf("(max %.0f)", max(v)),
                                                !isTRUE(show_cnv))
  heights <- c(heights, 1)
}
if (isTRUE(show_cnv)) {
  sub <- df[df$track == "CNV", , drop = FALSE]
  sub <- sub[order(sub$mb), , drop = FALSE]
  runs <- rle(sub$value)
  end_ix <- cumsum(runs$lengths); start_ix <- end_ix - runs$lengths + 1L
  half <- diff(sub$mb)[1] / 2
  seg <- data.frame(xmin = sub$mb[start_ix] - half, xmax = sub$mb[end_ix] + half, cn = runs$values)
  cn_all <- c("0" = hp[["red"]], "1" = hp[["orange"]], "2" = grey[["light"]], "3" = hp[["sky"]], "4" = hp[["blue"]])
  seg$fill <- cn_all[as.character(seg$cn)]
  gain_loss <- seg[seg$cn != 2, ]
  gain_loss$lab <- ifelse(gain_loss$cn < 2, sprintf("loss CN %d", gain_loss$cn), sprintf("gain CN %d", gain_loss$cn))
  panels[[length(panels) + 1L]] <- ggplot(seg) +
    geom_rect(aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = cn, fill = fill)) +
    geom_hline(yintercept = 2, linetype = "22", linewidth = pv_house_lw("ref"), colour = grey[["dark"]]) +
    geom_text(data = gain_loss, aes(x = (xmin + xmax) / 2, y = cn + 0.15, label = lab), vjust = 0,
              colour = "#1A1A1A", size = pv_pt2size(7), family = house_family()) +
    annotate("text", x = xr[1] + 0.01 * diff(xr), y = Inf, hjust = 0, vjust = 1.3, label = "Copy number",
             colour = "#1A1A1A", size = pv_pt2size(7), family = house_family()) +
    scale_fill_identity() +
    x_scale + scale_y_continuous(breaks = 0:4, limits = c(0, 4.9), expand = c(0, 0)) +
    labs(x = "Position on Chr5 (Mb)", y = "CN") + track_theme(TRUE)
  heights <- c(heights, 1.2)
}

p <- wrap_plots(panels, ncol = 1, heights = heights) +
  plot_annotation(caption = footnote, theme = theme_house() + caption_theme +
                    theme(plot.margin = margin(1, 1.5, 1, 1, "mm")))

pv_save_house(p, "figure", cells = "4x2")
message("wrote preview.png")
