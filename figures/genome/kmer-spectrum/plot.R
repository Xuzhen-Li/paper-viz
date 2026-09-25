# GenomeScope-style linear spectra. Error spike is clipped by the viewport.
source("../../../styles/r/theme_viz.R")

log_y <- FALSE
label_peaks <- TRUE
show_model <- TRUE
show_trunc_note <- TRUE
peak_headroom <- 1.25
x_coverage_mult <- 3

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
libraries_keep <- c("High-het", "Low-het")
df <- df[df$library %in% libraries_keep, , drop = FALSE]
df <- df[df$multiplicity <= df$lambda * x_coverage_mult, , drop = FALSE]
df$library <- factor(df$library, levels = libraries_keep)
lib_cols <- setNames(pv_palette("categorical", 2), libraries_keep)

one_panel <- function(d) {
  lib <- as.character(d$library[1])
  lam <- d$lambda[1]
  peak_h <- max(d$count[d$multiplicity > 6])
  ymax <- peak_h * peak_headroom
  y_at <- function(m) d$count[which.min(abs(d$multiplicity - m))]
  labs <- data.frame(
    multiplicity = c(lam / 2, lam),
    count = c(y_at(lam / 2), y_at(lam)),
    peak = c("1n", "2n")
  )
  p <- ggplot2::ggplot(d, ggplot2::aes(multiplicity, count)) +
    ggplot2::geom_line(linewidth = 0.45, colour = unname(lib_cols[lib]))
  if (isTRUE(show_model)) {
    p <- p + ggplot2::geom_line(
      ggplot2::aes(y = model),
      linetype = "dashed", linewidth = 0.3, colour = "#6B6B6B"
    )
  }
  if (isTRUE(label_peaks)) {
    p <- p + ggplot2::geom_text(
      data = labs,
      ggplot2::aes(multiplicity, count, label = peak),
      size = 1.8, family = viz_sans_family(), colour = "#1e3a5f",
      vjust = 0, nudge_y = ymax * 0.015
    )
  }
  if (isTRUE(show_trunc_note)) {
    p <- p + ggplot2::annotate(
      "text",
      x = min(d$multiplicity) + 0.5,
      y = ymax * 0.93,
      label = "error peak truncated",
      hjust = 0, vjust = 1,
      size = 1.7, family = viz_sans_family(), colour = "#6B6B6B"
    )
  }
  p <- p +
    ggplot2::coord_cartesian(ylim = c(0, ymax)) +
    ggplot2::labs(x = "k-mer multiplicity", y = "Distinct k-mers", title = lib) +
    theme_viz() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 6.5, hjust = 0),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
  if (isTRUE(log_y)) p <- p + ggplot2::scale_y_log10()
  p
}

panels <- lapply(split(df, df$library), one_panel)
p <- cowplot::plot_grid(plotlist = panels, ncol = 1, align = "v") +
  ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))

pv_save(p, "figure", width_mm = 140, height_mm = 110)
message("wrote preview.png")
