# Four-panel figure in house style. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

show_fit <- TRUE
base_size <- 10
group_levels <- c("Control", "Low", "High")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
pal <- stats::setNames(pv_palette("categorical", nlevels(df$group)), group_levels)

scale_treat_fill <- function() {
  ggplot2::scale_fill_manual(values = pal, name = "Treatment")
}
scale_treat_colour <- function() {
  ggplot2::scale_colour_manual(values = pal, guide = "none")
}
treat_guide <- function() {
  ggplot2::guides(
    fill = ggplot2::guide_legend(
      title.position = "top",
      nrow = 1,
      override.aes = list(
        shape = 21, colour = "black", alpha = 1, linewidth = 0, size = 2.2
      )
    ),
    colour = "none"
  )
}

panel_theme <- theme_viz(base_size = base_size) +
  ggplot2::theme(
    plot.margin = ggplot2::margin(4.8, 1.6, 1.0, 1.2, "mm"),
    plot.tag = ggplot2::element_text(face = "bold", size = base_size + 2, hjust = 0, vjust = 0),
    plot.tag.position = "topleft",
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.margin = ggplot2::margin(0, 3, 0, 3, "mm"),
    legend.box.margin = ggplot2::margin(0, 0, 0, 0)
  )

A <- df[df$panel == "A", , drop = FALSE]
pA <- ggplot2::ggplot(A, ggplot2::aes(x, y))
if (isTRUE(show_fit)) {
  pA <- pA + ggplot2::geom_smooth(
    ggplot2::aes(colour = group, fill = group),
    method = "lm", formula = y ~ x, se = TRUE,
    linewidth = 0.45, alpha = 0.16
  )
}
pA <- pA +
  ggplot2::geom_point(
    ggplot2::aes(fill = group),
    shape = 21, colour = "black", stroke = 0.25, size = 2.3
  ) +
  scale_treat_fill() +
  scale_treat_colour() +
  ggplot2::guides(fill = "none", colour = "none") +
  ggplot2::labs(x = "Marker A", y = "Marker B", tag = "A") +
  panel_theme

B <- df[df$panel == "B", , drop = FALSE]
B$class <- factor(B$class, levels = c("Liver", "Spleen", "Lung", "Kidney"))
pB <- ggplot2::ggplot(B, ggplot2::aes(class, y, fill = group)) +
  ggplot2::geom_col(
    position = ggplot2::position_dodge(width = 0.72),
    width = 0.66
  ) +
  scale_treat_fill() +
  treat_guide() +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.08))) +
  ggplot2::labs(x = NULL, y = "Response", tag = "B") +
  panel_theme

C <- df[df$panel == "C", , drop = FALSE]
pC <- ggplot2::ggplot(C, ggplot2::aes(x, y, group = group)) +
  ggplot2::geom_line(ggplot2::aes(colour = group), linewidth = 0.7) +
  ggplot2::geom_point(
    ggplot2::aes(fill = group),
    shape = 21, colour = "black", stroke = 0.25, size = 2.1
  ) +
  scale_treat_fill() +
  scale_treat_colour() +
  ggplot2::guides(fill = "none", colour = "none") +
  ggplot2::scale_x_continuous(breaks = sort(unique(C$x))) +
  ggplot2::labs(x = "Day", y = "Signal", tag = "C") +
  panel_theme

D <- df[df$panel == "D", , drop = FALSE]
D$class <- factor(D$class, levels = rev(c("Actb", "Myc", "Tp53", "Vegfa", "Cdkn1a")))
D$item <- factor(D$item, levels = c("C1", "C2", "L1", "L2", "H1", "H2"))
lim <- max(abs(D$y), na.rm = TRUE)
pD <- ggplot2::ggplot(D, ggplot2::aes(item, class, fill = y)) +
  ggplot2::geom_tile(colour = "white", linewidth = 0.35) +
  ggplot2::scale_fill_gradientn(
    colours = pv_palette("diverging", 7),
    limits = c(-lim, lim),
    name = "Score",
    breaks = c(-1, 0, 1),
    guide = ggplot2::guide_colourbar(
      title.position = "top",
      barwidth = ggplot2::unit(32, "mm"),
      barheight = ggplot2::unit(2.8, "mm")
    )
  ) +
  ggplot2::labs(x = NULL, y = NULL, tag = "D") +
  panel_theme

# ggplot2 4 does not add a second ggplot with `+` until patchwork is attached.
p <- patchwork::wrap_plots(pA, pB, pC, pD, ncol = 2, guides = "collect") +
  patchwork::plot_annotation(
    theme = ggplot2::theme(
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.margin = ggplot2::margin(0, 4, 0, 4, "mm"),
      legend.box.spacing = ggplot2::unit(1, "mm")
    )
  )

pv_save(p, "figure", width_mm = 180, height_mm = 120)
message("wrote preview.png")
