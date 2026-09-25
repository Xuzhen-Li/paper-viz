# GSEA running-score curves with an optional ranked-list bar.
# Run from this directory.
source("../../../styles/r/theme_viz.R")
library(patchwork)

sets_keep <- c("Interferon response", "Oxidative phosphorylation")
show_ranked_bar <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$set %in% sets_keep, , drop = FALSE]
df$set <- factor(df$set, levels = sets_keep)
pal <- pv_palette("categorical", length(sets_keep))
names(pal) <- sets_keep

curve <- ggplot2::ggplot(df, ggplot2::aes(rank, es, colour = set)) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, colour = "grey50") +
  ggplot2::geom_line(linewidth = 0.55) +
  ggplot2::scale_colour_manual(values = pal, name = NULL) +
  ggplot2::labs(x = NULL, y = "Enrichment score") +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank()
  )

hits <- df[df$hit == 1, , drop = FALSE]
hits$y <- as.numeric(hits$set)
rug <- ggplot2::ggplot(hits, ggplot2::aes(colour = set)) +
  ggplot2::geom_segment(
    ggplot2::aes(x = rank, xend = rank, y = y - 0.32, yend = y + 0.32),
    linewidth = 0.25
  ) +
  ggplot2::scale_colour_manual(values = pal, guide = "none") +
  ggplot2::scale_y_continuous(
    breaks = seq_along(sets_keep), labels = sets_keep,
    limits = c(0.4, length(sets_keep) + 0.6)
  ) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank(),
    axis.line.x = ggplot2::element_blank()
  )

met <- df[df$set == sets_keep[[1]], , drop = FALSE]
bar <- ggplot2::ggplot(met, ggplot2::aes(rank, metric, fill = metric)) +
  ggplot2::geom_col(width = 1, colour = NA) +
  ggplot2::scale_fill_gradientn(colours = pv_palette("diverging", 7), guide = "none") +
  ggplot2::labs(x = "Rank in ordered gene list", y = "Rank metric") +
  theme_viz()

if (isTRUE(show_ranked_bar) && length(sets_keep) > 1) {
  p <- curve / rug / bar + patchwork::plot_layout(heights = c(1.3, 0.38, 0.55))
} else if (isTRUE(show_ranked_bar)) {
  p <- curve / bar + patchwork::plot_layout(heights = c(1.4, 0.5))
} else {
  p <- curve
}

pv_save(p, "figure", width_mm = 150, height_mm = 120)
message("wrote preview.png")
