# Fragment-length histograms with density, one panel per library.
source("../../../styles/r/theme_viz.R")

binwidth <- 5
xmax <- 500
facet_by_library <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$library <- factor(df$library, levels = c("Ancient", "Nucleosome", "Modern"))
lib_cols <- c(Ancient = "#0072B2", Nucleosome = "#E69F00", Modern = "#009E73")

p <- ggplot2::ggplot(df, ggplot2::aes(length_bp, fill = library, colour = library)) +
  ggplot2::geom_histogram(
    ggplot2::aes(y = ggplot2::after_stat(density)),
    binwidth = binwidth, boundary = 0, alpha = 0.35, colour = NA
  ) +
  ggplot2::geom_density(linewidth = 0.4, fill = NA) +
  ggplot2::scale_fill_manual(values = lib_cols, name = NULL) +
  ggplot2::scale_colour_manual(values = lib_cols, name = NULL) +
  ggplot2::scale_x_continuous(limits = c(0, xmax), expand = c(0, 0)) +
  ggplot2::labs(x = "Fragment length (bp)", y = "Density") +
  theme_viz()

if (isTRUE(facet_by_library)) {
  p <- p +
    ggplot2::facet_wrap(~library, ncol = 1, scales = "free_y") +
    ggplot2::guides(fill = "none", colour = "none") +
    ggplot2::theme(
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(size = 6.5, hjust = 0)
    )
} else {
  p <- p + ggplot2::theme(legend.key.size = ggplot2::unit(3, "mm"))
}

pv_save(p, "figure", width_mm = 140, height_mm = 120)
message("wrote preview.png")
