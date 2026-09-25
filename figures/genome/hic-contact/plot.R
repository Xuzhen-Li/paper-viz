# Hi-C contact map, log colour, chromosome boundaries.
source("../../../styles/r/theme_viz.R")

log_color <- TRUE
show_chr_split <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
chr_of <- tapply(df$chr, df$bin_i, function(z) z[1])
chr_names <- unique(chr_of[order(as.integer(names(chr_of)))])
bin_n <- tapply(df$bin_i, df$chr, function(z) length(unique(z)))
bin_n <- bin_n[chr_names]
bounds <- cumsum(bin_n)
mids <- (c(0, head(bounds, -1)) + bounds) / 2

df$fill <- if (isTRUE(log_color)) log10(df$count + 1) else df$count
leg <- if (isTRUE(log_color)) "log10(count + 1)" else "Count"

p <- ggplot2::ggplot(df, ggplot2::aes(bin_j, bin_i, fill = fill)) +
  ggplot2::geom_raster(interpolate = TRUE) +
  ggplot2::scale_fill_gradientn(colours = pv_palette("sequential"), name = leg) +
  ggplot2::scale_x_continuous(breaks = mids, labels = chr_names, expand = c(0, 0)) +
  ggplot2::scale_y_continuous(breaks = mids, labels = chr_names, expand = c(0, 0)) +
  ggplot2::coord_fixed() +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    legend.key.height = ggplot2::unit(5, "mm"),
    legend.key.width = ggplot2::unit(2.6, "mm"),
    axis.line = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank()
  )

if (isTRUE(show_chr_split)) {
  edges <- head(bounds, -1) + 0.5
  p <- p +
    ggplot2::geom_hline(yintercept = edges, linewidth = 0.25, colour = "#1e3a5f") +
    ggplot2::geom_vline(xintercept = edges, linewidth = 0.25, colour = "#1e3a5f")
}

pv_save(p, "figure", width_mm = 130, height_mm = 120)
message("wrote preview.png")
