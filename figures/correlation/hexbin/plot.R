# Hexbin density of a bivariate scatter. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

# 可调参数
bins <- 28
show_counts <- FALSE
legend_title <- "Count"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
seq_cols <- pv_palette("sequential", 5)

p <- ggplot2::ggplot(df, ggplot2::aes(x, y)) +
  ggplot2::geom_hex(bins = bins, colour = NA) +
  ggplot2::scale_fill_gradientn(
    colours = seq_cols,
    name = legend_title,
    guide = ggplot2::guide_colorbar(barwidth = 0.5, barheight = 4)
  ) +
  ggplot2::coord_fixed(ratio = 1, expand = TRUE) +
  ggplot2::labs(x = "Feature X", y = "Feature Y") +
  theme_viz(base_size = 7) +
  ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = c(0.02, 0.98),
    legend.justification.inside = c(0, 1)
  )

if (isTRUE(show_counts)) {
  p <- p + ggplot2::stat_bin_hex(
    ggplot2::aes(label = ggplot2::after_stat(count)),
    bins = bins,
    geom = "text",
    size = 1.6,
    colour = "grey20"
  )
}

pv_save(p, "figure", width_mm = 85, height_mm = 85)
message("wrote preview.png")
