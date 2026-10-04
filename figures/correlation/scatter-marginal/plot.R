# Scatter with marginal density, histogram, or boxplot. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
marginal <- "density" # density | histogram | boxplot
show_regression <- TRUE
# ------------------

marginal <- match.arg(marginal, c("density", "histogram", "boxplot"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = c("MCF7", "A549", "HepG2"))
pal <- stats::setNames(pv_palette("categorical", nlevels(df$group)), levels(df$group))
pal_fill <- ggplot2::alpha(pal, 0.42)

pad <- 0.28
xr <- range(df$x)
yr <- range(df$y)
xlim <- xr + c(-1, 1) * pad * diff(xr)
ylim <- yr + c(-1, 1) * pad * diff(yr)
bw_x <- diff(xlim) / 18
bw_y <- diff(ylim) / 18

margin_theme <- theme_viz(base_size = 7) +
  ggplot2::theme(
    legend.position = "none",
    axis.title = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank(),
    plot.margin = ggplot2::margin(0, 0, 0, 0)
  )

build_marginal <- function(along = c("x", "y")) {
  along <- match.arg(along)
  if (marginal == "boxplot") {
    if (along == "x") {
      p <- ggplot2::ggplot(df, ggplot2::aes(x = x, y = group, colour = group, fill = group)) +
        ggplot2::geom_boxplot(width = 0.62, linewidth = 0.3, outlier.size = 0.4)
    } else {
      p <- ggplot2::ggplot(df, ggplot2::aes(x = group, y = y, colour = group, fill = group)) +
        ggplot2::geom_boxplot(width = 0.62, linewidth = 0.3, outlier.size = 0.4)
    }
  } else if (along == "x") {
    p <- ggplot2::ggplot(df, ggplot2::aes(x = x, fill = group))
    if (marginal == "density") {
      p <- ggplot2::ggplot(df, ggplot2::aes(x = x, fill = group, colour = group)) +
        ggplot2::geom_density(linewidth = 0.25, adjust = 0.85)
    } else {
      p <- p + ggplot2::geom_histogram(
        binwidth = bw_x, boundary = xlim[1], position = "identity",
        colour = NA, linewidth = 0
      )
    }
  } else if (marginal == "density") {
    p <- ggplot2::ggplot(df, ggplot2::aes(y = y, fill = group, colour = group)) +
      ggplot2::geom_density(orientation = "y", linewidth = 0.25, adjust = 0.85)
  } else {
    p <- ggplot2::ggplot(df, ggplot2::aes(y = y, fill = group)) +
      ggplot2::geom_histogram(
        orientation = "y", binwidth = bw_y, boundary = ylim[1],
        position = "identity", colour = NA, linewidth = 0
      )
  }
  p <- p + ggplot2::scale_fill_manual(values = pal_fill, guide = "none")
  if (marginal != "histogram") {
    p <- p + ggplot2::scale_colour_manual(values = pal, guide = "none")
  }
  if (along == "x") {
    p <- p + ggplot2::scale_x_continuous(limits = xlim, expand = c(0, 0))
    if (marginal != "boxplot") {
      p <- p + ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.08)))
    }
  } else {
    p <- p + ggplot2::scale_y_continuous(limits = ylim, expand = c(0, 0))
    if (marginal != "boxplot") {
      p <- p + ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.08)))
    }
  }
  p + margin_theme
}

p_main <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = group))
if (isTRUE(show_regression)) {
  p_main <- p_main +
    ggplot2::geom_smooth(
      ggplot2::aes(fill = group),
      method = "lm", formula = y ~ x, se = TRUE, linewidth = 0.4, alpha = 0.2
    ) +
    ggplot2::scale_fill_manual(values = pal, guide = "none")
}
p_main <- p_main +
  ggplot2::geom_point(size = 1.35, alpha = 0.9) +
  ggplot2::scale_colour_manual(values = pal, name = NULL) +
  ggplot2::scale_x_continuous(limits = xlim, expand = c(0, 0)) +
  ggplot2::scale_y_continuous(limits = ylim, expand = c(0, 0)) +
  ggplot2::guides(colour = ggplot2::guide_legend(override.aes = list(fill = NA, linewidth = 0))) +
  ggplot2::labs(x = "Gene A (log2 CPM)", y = "Gene B (log2 CPM)") +
  theme_viz(base_size = 7) +
  ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = c(0.02, 0.98),
    legend.justification.inside = c(0, 1),
    legend.key.height = ggplot2::unit(2.6, "mm"),
    legend.key.width = ggplot2::unit(3.4, "mm"),
    legend.margin = ggplot2::margin(0, 0, 0, 0),
    plot.margin = ggplot2::margin(0, 0, 0.3, 0.3, "mm")
  )

p_top <- build_marginal("x")
p_right <- build_marginal("y")

p <- patchwork::wrap_plots(
  A = p_top,
  B = p_main,
  C = p_right,
  design = "AAAAA#\nBBBBBC",
  widths = c(1, 1, 1, 1, 1, 1.15),
  heights = c(1, 4.2),
  guides = "keep"
)

pv_save(p, "figure", width_mm = 85, height_mm = 85)
message("wrote preview.png")
