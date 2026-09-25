# Stacked locus tracks: depth, ATAC, RNA, and copy-number segments.
source("../../../styles/r/theme_viz.R")

show_depth <- TRUE
show_atac <- TRUE
show_rna <- TRUE
show_cnv <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$mb <- df$pos / 1e6

track_theme <- function(bottom = FALSE) {
  th <- theme_viz() + ggplot2::theme(
    plot.margin = ggplot2::margin(1, 6, 0, 2),
    axis.title.y = ggplot2::element_text(size = 6)
  )
  if (!bottom) {
    th <- th + ggplot2::theme(
      axis.title.x = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank()
    )
  }
  th
}

panels <- list()
heights <- numeric()

if (isTRUE(show_depth)) {
  sub <- df[df$track == "Depth", , drop = FALSE]
  panels[[length(panels) + 1L]] <- ggplot2::ggplot(sub, ggplot2::aes(mb, value)) +
    ggplot2::geom_area(fill = "#C6DBEF", colour = "#2171B5", linewidth = 0.25) +
    ggplot2::labs(x = NULL, y = "Depth") +
    track_theme(FALSE)
  heights <- c(heights, 1)
}
if (isTRUE(show_atac)) {
  sub <- df[df$track == "ATAC", , drop = FALSE]
  panels[[length(panels) + 1L]] <- ggplot2::ggplot(sub, ggplot2::aes(mb, value)) +
    ggplot2::geom_area(fill = "#FEE0B6", colour = "#E08214", linewidth = 0.25) +
    ggplot2::labs(x = NULL, y = "ATAC") +
    track_theme(FALSE)
  heights <- c(heights, 0.9)
}
if (isTRUE(show_rna)) {
  sub <- df[df$track == "RNA", , drop = FALSE]
  panels[[length(panels) + 1L]] <- ggplot2::ggplot(sub, ggplot2::aes(mb, value)) +
    ggplot2::geom_area(fill = "#C7E9C0", colour = "#238B45", linewidth = 0.25) +
    ggplot2::labs(x = NULL, y = "RNA") +
    track_theme(!isTRUE(show_cnv))
  heights <- c(heights, 0.9)
}
if (isTRUE(show_cnv)) {
  sub <- df[df$track == "CNV", , drop = FALSE]
  sub <- sub[order(sub$mb), , drop = FALSE]
  runs <- rle(sub$value)
  end_ix <- cumsum(runs$lengths)
  start_ix <- end_ix - runs$lengths + 1L
  half <- diff(sub$mb)[1] / 2
  seg <- data.frame(
    xmin = sub$mb[start_ix] - half,
    xmax = sub$mb[end_ix] + half,
    cn = factor(runs$values, levels = c(0, 1, 2, 3, 4))
  )
  cn_cols <- c("0" = "#2166AC", "1" = "#67A9CF", "2" = "#D9D9D9", "3" = "#E08214", "4" = "#B35806")
  panels[[length(panels) + 1L]] <- ggplot2::ggplot(seg, ggplot2::aes(fill = cn)) +
    ggplot2::geom_rect(ggplot2::aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = as.numeric(as.character(cn)))) +
    ggplot2::geom_hline(yintercept = 2, linetype = "dashed", linewidth = 0.25) +
    ggplot2::scale_fill_manual(values = cn_cols, name = "CN", drop = FALSE) +
    ggplot2::scale_y_continuous(breaks = 0:4, limits = c(0, 4.4)) +
    ggplot2::labs(x = "Position on Chr5 (Mb)", y = "Copy number") +
    track_theme(TRUE) +
    ggplot2::theme(legend.key.size = ggplot2::unit(2.6, "mm"))
  heights <- c(heights, 0.85)
}

if (length(panels) == 1L) {
  p <- panels[[1]]
} else {
  p <- cowplot::plot_grid(
    plotlist = panels, ncol = 1, align = "v", rel_heights = heights
  )
}

pv_save(p, "figure", width_mm = 183, height_mm = 120)
message("wrote preview.png")
