# GenomeScope-style linear k-mer spectra (house style), one panel per library side by side; the error
# spike is clipped by the viewport. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# 可调参数 -----------------------------------------------------------------
log_y <- FALSE
label_peaks <- TRUE
show_model <- TRUE
show_trunc_note <- TRUE
peak_headroom <- 1.8
x_coverage_mult <- 3

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
libraries_keep <- c("High-het", "Low-het")
df <- df[df$library %in% libraries_keep, , drop = FALSE]
df <- df[df$multiplicity <= df$lambda * x_coverage_mult, , drop = FALSE]
df$library <- factor(df$library, levels = libraries_keep)
lib_cols <- stats::setNames(c(hp[["blue"]], hp[["orange"]]), libraries_keep)
lab_cols <- text_col(lib_cols)

one_panel <- function(d, first) {
  lib <- as.character(d$library[1])
  lam <- d$lambda[1]
  peak_h <- max(d$count[d$multiplicity > 6])
  ymax <- peak_h * peak_headroom
  y_at <- function(m) d$count[which.min(abs(d$multiplicity - m))]
  pk <- data.frame(multiplicity = c(lam / 2, lam), count = c(y_at(lam / 2), y_at(lam)), peak = c("1n", "2n"))
  p <- ggplot(d, aes(multiplicity, count)) +
    geom_line(linewidth = pv_house_lw("main"), colour = unname(lib_cols[lib]))
  if (isTRUE(show_model)) {
    p <- p + geom_line(aes(y = model), linetype = "22", linewidth = pv_house_lw("ref"), colour = grey[["dark"]])
  }
  if (isTRUE(label_peaks)) {
    # peak name on a short vertical leader above the curve
    pk$y_lab <- pk$count + ymax * 0.17
    p <- p + geom_segment(data = pk, aes(xend = multiplicity, y = count + ymax * 0.03, yend = y_lab - ymax * 0.02),
                          linewidth = pv_house_lw("ref"), colour = grey[["dark"]]) +
      geom_text(data = pk, aes(y = y_lab, label = peak), size = pv_pt2size(7), family = house_family(),
                colour = "#1A1A1A", vjust = 0)
  }
  # library name + homozygous peak coverage (in-panel stat), top right
  p <- p + annotate("text", x = Inf, y = Inf, hjust = 1.05, vjust = 1.3, lineheight = 0.95,
                    label = sprintf("%s\n2n peak %dx", lib, round(lam)), colour = lab_cols[[lib]],
                    size = pv_pt2size(7), family = house_family())
  if (isTRUE(show_trunc_note)) {
    p <- p + annotate("text", x = Inf, y = Inf, label = "\n\nerror peak\ntruncated",
                      hjust = 1.04, vjust = 1.3, lineheight = 0.95, size = pv_pt2size(7), family = house_family(),
                      colour = grey[["mid"]])
  }
  p <- p + coord_cartesian(ylim = c(if (isTRUE(log_y)) NA else 0, ymax)) +
    scale_y_continuous(labels = function(v) sprintf("%g", v / 1e3), expand = c(0, 0)) +
    labs(x = "k-mer multiplicity", y = if (first) "Distinct k-mers (k)" else NULL) +
    theme_house()
  if (isTRUE(log_y)) p <- p + scale_y_log10(labels = function(v) sprintf("%g", v / 1e3))
  p
}

lst <- split(df, df$library)
panels <- Map(one_panel, lst, seq_along(lst) == 1)
p <- wrap_plots(panels, nrow = 1) +
  plot_annotation(caption = footnote, theme = theme_house() + caption_theme +
                    theme(plot.margin = margin(1, 1.5, 1, 1, "mm")))

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
