# Pangenome pie (core/shell/cloud) and pan/core accumulation with Heaps alpha.
source("../../../styles/r/theme_viz.R")

show_pie <- TRUE
show_accumulation <- TRUE
show_heaps <- TRUE
compartment_order <- c("Core", "Shell", "Cloud")

comp <- utils::read.csv("data_compartment.csv", stringsAsFactors = FALSE)
growth <- utils::read.csv("data_growth.csv", stringsAsFactors = FALSE)
comp$compartment <- factor(comp$compartment, levels = compartment_order)
comp <- comp[order(comp$compartment), , drop = FALSE]
comp_cols <- c(Core = "#0072B2", Shell = "#E69F00", Cloud = "#6B6B6B")

comp$frac <- comp$n_families / sum(comp$n_families)
comp$legend <- sprintf("%s (%s)", comp$compartment, format(comp$n_families, big.mark = ","))
end <- cumsum(comp$frac)
start <- c(0, head(end, -1))
slice_poly <- function(a0, a1, lab) {
  ang <- seq(a0, a1, length.out = 60) * 2 * pi
  data.frame(
    x = c(0, cos(ang)),
    y = c(0, sin(ang)),
    legend = lab
  )
}
poly <- do.call(rbind, Map(slice_poly, start, end, as.character(comp$legend)))

p_pie <- ggplot2::ggplot(poly, ggplot2::aes(x, y, fill = legend)) +
  ggplot2::geom_polygon(colour = "white", linewidth = 0.2) +
  ggplot2::coord_equal() +
  ggplot2::scale_fill_manual(values = setNames(comp_cols[compartment_order], comp$legend), name = NULL) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    panel.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.key.size = ggplot2::unit(3, "mm")
  )

fit <- stats::lm(log(pan) ~ log(n_genomes), data = growth)
alpha <- unname(stats::coef(fit)[2])
k <- exp(unname(stats::coef(fit)[1]))
growth$heaps <- k * growth$n_genomes^alpha

long <- rbind(
  data.frame(n_genomes = growth$n_genomes, families = growth$pan, curve = "Pan"),
  data.frame(n_genomes = growth$n_genomes, families = growth$core, curve = "Core")
)
curve_cols <- c(Pan = "#0072B2", Core = "#E69F00")

p_acc <- ggplot2::ggplot(long, ggplot2::aes(n_genomes, families, colour = curve)) +
  ggplot2::geom_line(linewidth = 0.5) +
  ggplot2::geom_point(size = 0.7) +
  ggplot2::scale_colour_manual(values = curve_cols, name = NULL) +
  ggplot2::labs(x = "Genomes added", y = "Gene families") +
  theme_viz() +
  ggplot2::theme(legend.key.size = ggplot2::unit(3, "mm"))

if (isTRUE(show_heaps)) {
  p_acc <- p_acc +
    ggplot2::geom_line(
      data = growth,
      ggplot2::aes(n_genomes, heaps),
      inherit.aes = FALSE,
      linetype = "dashed", linewidth = 0.35, colour = "#1e3a5f"
    ) +
    ggplot2::annotate(
      "text",
      x = 28, y = min(long$families) + 0.22 * diff(range(long$families)),
      label = sprintf("Heaps \u03b1 = %.2f", alpha),
      size = 2.1, family = viz_sans_family(), hjust = 0
    )
}

if (isTRUE(show_pie) && isTRUE(show_accumulation)) {
  p <- cowplot::plot_grid(p_pie, p_acc, ncol = 2, rel_widths = c(1, 1.45)) +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))
} else if (isTRUE(show_pie)) {
  p <- p_pie
} else {
  p <- p_acc
}

pv_save(p, "figure", width_mm = 183, height_mm = 78)
message("wrote preview.png")
