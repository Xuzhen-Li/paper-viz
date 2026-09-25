# Plant chromosome ideogram with gene-density track. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

show_density <- TRUE
show_band_labels <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
chr_levels <- sprintf("Chr%d", 8:1)
df$chr <- factor(df$chr, levels = chr_levels)
df$y <- as.numeric(df$chr) * 1.45

ideo <- df[df$feature == "chromosome", , drop = FALSE]
cen <- df[df$feature == "centromere", , drop = FALSE]
nor <- df[df$feature == "nor", , drop = FALSE]
dens <- df[df$feature == "density", , drop = FALSE]
h <- 0.28

p <- ggplot2::ggplot() +
  ggplot2::geom_rect(
    data = ideo,
    ggplot2::aes(xmin = start / 1e6, xmax = end / 1e6, ymin = y - h, ymax = y + h),
    fill = "#F2F2F2", colour = NA
  )

if (isTRUE(show_density)) {
  p <- p + ggplot2::geom_rect(
    data = dens,
    ggplot2::aes(
      xmin = start / 1e6, xmax = end / 1e6,
      ymin = y - h, ymax = y + h, fill = value
    ),
    colour = NA
  )
}

p <- p +
  ggplot2::geom_rect(
    data = ideo,
    ggplot2::aes(xmin = start / 1e6, xmax = end / 1e6, ymin = y - h, ymax = y + h),
    fill = NA, colour = "#1e3a5f", linewidth = 0.25
  ) +
  ggplot2::geom_rect(
    data = cen,
    ggplot2::aes(xmin = start / 1e6, xmax = end / 1e6, ymin = y - h, ymax = y + h),
    fill = "#1e3a5f", colour = NA
  ) +
  ggplot2::geom_rect(
    data = nor,
    ggplot2::aes(
      xmin = start / 1e6, xmax = end / 1e6,
      ymin = y + h * 0.15, ymax = y + h
    ),
    fill = "#E69F00", colour = NA
  )

if (isTRUE(show_band_labels)) {
  lab <- rbind(
    data.frame(
      x = (cen$start + cen$end) / 2 / 1e6,
      y = cen$y - h - 0.20,
      label = "CEN"
    ),
    data.frame(
      x = (nor$start + nor$end) / 2 / 1e6,
      y = nor$y + h + 0.20,
      label = "NOR"
    )
  )
  p <- p + ggplot2::geom_text(
    data = lab,
    ggplot2::aes(x, y, label = label),
    size = 1.6, colour = "#333333", family = viz_sans_family()
  )
}

p <- p +
  ggplot2::scale_y_continuous(
    breaks = seq_along(chr_levels) * 1.45,
    labels = chr_levels,
    expand = ggplot2::expansion(add = 0.35)
  ) +
  ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.02, 0.04))) +
  ggplot2::scale_fill_gradientn(
    colours = pv_palette("sequential"),
    name = "Genes / Mb"
  ) +
  ggplot2::labs(x = "Position (Mb)", y = NULL) +
  theme_viz() +
  ggplot2::theme(
    legend.key.height = ggplot2::unit(4, "mm"),
    legend.key.width = ggplot2::unit(2.5, "mm")
  )

if (!isTRUE(show_density)) p <- p + ggplot2::guides(fill = "none")

pv_save(p, "figure", width_mm = 160, height_mm = 95)
message("wrote preview.png")
