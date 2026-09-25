# SBS96 spectrum. Six substitution classes, sixteen trinucleotide contexts, coloured by class.
source("../../../styles/r/theme_viz.R")

as_proportion <- FALSE
sub_levels <- c("C>A", "C>G", "C>T", "T>A", "T>G", "T>C")
# COSMIC SBS96 class colours.
sbs_cols <- c(
  "C>A" = "#03BCEE",
  "C>G" = "#3D3D3D",
  "C>T" = "#E32926",
  "T>A" = "#999999",
  "T>G" = "#A1CE63",
  "T>C" = "#EBC6C4"
)

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$substitution <- factor(df$substitution, levels = sub_levels)
flank <- c("A", "C", "G", "T")
ctx_of <- function(mid) {
  paste0(rep(flank, each = 4), mid, rep(flank, times = 4))
}
ctx_levels <- c(ctx_of("C"), ctx_of("T"))
df$context <- factor(df$context, levels = ctx_levels)
df <- df[order(df$substitution, df$context), , drop = FALSE]
df$x <- seq_len(nrow(df))
df$y <- if (isTRUE(as_proportion)) df$count / sum(df$count) else df$count
y_lab <- if (isTRUE(as_proportion)) "Proportion of mutations" else "Mutation count"
df$b5 <- substr(df$context, 1, 1)
df$midb <- substr(df$context, 2, 2)
df$b3 <- substr(df$context, 3, 3)

ann <- data.frame(
  substitution = factor(sub_levels, levels = sub_levels),
  xmin = (seq_along(sub_levels) - 1) * 16 + 0.4,
  xmax = seq_along(sub_levels) * 16 + 0.6
)
ann$x <- (ann$xmin + ann$xmax) / 2
top <- max(df$y) * 1.14
ann$y <- top

p <- ggplot2::ggplot(df, ggplot2::aes(x, y, fill = substitution)) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.25) +
  ggplot2::geom_col(width = 0.86, colour = NA) +
  ggplot2::geom_text(
    data = ann,
    ggplot2::aes(x = x, y = y, label = substitution),
    inherit.aes = FALSE,
    size = 2.05,
    fontface = "bold",
    vjust = 0
  ) +
  ggplot2::geom_segment(
    data = ann,
    ggplot2::aes(x = xmin, xend = xmax, y = top * 0.98, yend = top * 0.98, colour = substitution),
    inherit.aes = FALSE,
    linewidth = 1.1
  ) +
  ggplot2::scale_fill_manual(values = sbs_cols, guide = "none") +
  ggplot2::scale_colour_manual(values = sbs_cols, guide = "none") +
  ggplot2::geom_text(
    ggplot2::aes(x, y = -0.05 * top, label = b5),
    size = 1.15, colour = "black"
  ) +
  ggplot2::geom_text(
    ggplot2::aes(x, y = -0.105 * top, label = midb),
    size = 1.15, colour = "black"
  ) +
  ggplot2::geom_text(
    ggplot2::aes(x, y = -0.16 * top, label = b3),
    size = 1.15, colour = "black"
  ) +
  ggplot2::scale_x_continuous(expand = c(0.01, 0.01)) +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.06))) +
  ggplot2::coord_cartesian(ylim = c(0, max(df$y) * 1.22), clip = "off") +
  ggplot2::labs(x = NULL, y = y_lab) +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank(),
    axis.title.x = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.margin = ggplot2::margin(1, 2, 14, 2, "mm")
  )

pv_save(p, "figure", width_mm = 183, height_mm = 98)
message("wrote preview.png")
