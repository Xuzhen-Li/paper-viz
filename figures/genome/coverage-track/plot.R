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
track_pal <- pv_palette("categorical", 6)

if (isTRUE(show_depth)) {
  sub <- df[df$track == "Depth", , drop = FALSE]
  panels[[length(panels) + 1L]] <- ggplot2::ggplot(sub, ggplot2::aes(mb, value)) +
    ggplot2::geom_area(
      fill = grDevices::adjustcolor(track_pal[1], alpha.f = 0.45),
      colour = track_pal[1], linewidth = 0.25
    ) +
    ggplot2::labs(x = NULL, y = "Depth") +
    track_theme(FALSE)
  heights <- c(heights, 1)
}
if (isTRUE(show_atac)) {
  sub <- df[df$track == "ATAC", , drop = FALSE]
  panels[[length(panels) + 1L]] <- ggplot2::ggplot(sub, ggplot2::aes(mb, value)) +
    ggplot2::geom_area(
      fill = grDevices::adjustcolor(track_pal[6], alpha.f = 0.45),
      colour = track_pal[6], linewidth = 0.25
    ) +
    ggplot2::labs(x = NULL, y = "ATAC") +
    track_theme(FALSE)
  heights <- c(heights, 0.9)
}
if (isTRUE(show_rna)) {
  sub <- df[df$track == "RNA", , drop = FALSE]
  panels[[length(panels) + 1L]] <- ggplot2::ggplot(sub, ggplot2::aes(mb, value)) +
    ggplot2::geom_area(
      fill = grDevices::adjustcolor(track_pal[3], alpha.f = 0.45),
      colour = track_pal[3], linewidth = 0.25
    ) +
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
    cn = factor(runs$values)
  )
  cn_pal <- pv_palette("categorical", 8)
  cn_all <- c("0" = cn_pal[3], "1" = cn_pal[1], "2" = "#E0E0E0", "3" = cn_pal[6], "4" = cn_pal[4])
  cn_cols <- cn_all[levels(seg$cn)]
  panels[[length(panels) + 1L]] <- ggplot2::ggplot(seg, ggplot2::aes(fill = cn)) +
    ggplot2::geom_rect(ggplot2::aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = as.numeric(as.character(cn)))) +
    ggplot2::geom_hline(yintercept = 2, linetype = "dashed", linewidth = 0.25) +
    ggplot2::scale_fill_manual(values = cn_cols, name = "CN", drop = TRUE) +
    ggplot2::scale_y_continuous(breaks = 0:4, limits = c(0, 4.4)) +
    ggplot2::labs(x = "Position on Chr5 (Mb)", y = "Copy number") +
    track_theme(TRUE) +
    ggplot2::theme(
      legend.key.size = ggplot2::unit(2.6, "mm"),
      legend.position = "bottom"
    )
  heights <- c(heights, 1.25)
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
