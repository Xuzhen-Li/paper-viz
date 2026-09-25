# OPLS-DA scores and permutation diagnostic. Reads data*.csv only.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
show_scores <- TRUE
show_permutation <- TRUE
show_ellipse <- TRUE
# ------------------

scores <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
perm <- utils::read.csv("data_perm.csv", stringsAsFactors = FALSE)
scores$group <- factor(scores$group, levels = unique(scores$group))
cols <- pv_palette("categorical", nlevels(scores$group))
names(cols) <- levels(scores$group)

panels <- list()

if (isTRUE(show_scores)) {
  p_scores <- ggplot2::ggplot(scores, ggplot2::aes(pred, ortho, colour = group)) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, colour = "grey70") +
    ggplot2::geom_vline(xintercept = 0, linewidth = 0.25, colour = "grey70") +
    ggplot2::geom_point(size = 1.6) +
    ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::labs(x = "Predictive component", y = "Orthogonal component", tag = "a") +
    theme_viz()
  if (isTRUE(show_ellipse)) {
    p_scores <- p_scores + ggplot2::stat_ellipse(linewidth = 0.35, level = 0.8, show.legend = FALSE)
  }
  panels <- c(panels, list(p_scores))
}

if (isTRUE(show_permutation)) {
  obs <- perm$q2[perm$perm == 1]
  null <- perm[perm$perm != 1, , drop = FALSE]
  p_perm <- ggplot2::ggplot(null, ggplot2::aes(q2)) +
    ggplot2::geom_histogram(bins = 18, fill = pv_palette("sequential", 5)[4], colour = "white", linewidth = 0.15) +
    ggplot2::geom_vline(xintercept = obs, linetype = "dashed", linewidth = 0.35) +
    ggplot2::annotate(
      "text", x = obs, y = Inf, label = "observed",
      vjust = 1.5, hjust = 1.08, size = 2.1
    ) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.08, 0.12))) +
    ggplot2::labs(x = "Q2", y = "Permutations", tag = "b") +
    theme_viz()
  panels <- c(panels, list(p_perm))
}

if (length(panels) == 0) stop("enable show_scores or show_permutation")
p <- if (length(panels) == 1) panels[[1]] else cowplot::plot_grid(plotlist = panels, nrow = 1, rel_widths = c(1.15, 1))

pv_save(p, "figure", width_mm = if (length(panels) == 2) 160 else 89, height_mm = 72)
message("wrote preview.png")
