# Multiple sequence alignment with a conservation bar. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
show_conservation <- TRUE
highlight_diff <- TRUE
# ------------------

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$seq <- factor(df$seq, levels = rev(unique(df$seq)))
class_of <- function(b) {
  ifelse(b %in% c("A", "V", "L", "I", "M", "F", "P", "W"), "hydrophobic",
    ifelse(b %in% c("S", "T", "N", "Q", "Y", "C"), "polar",
      ifelse(b %in% c("K", "R", "H"), "positive",
        ifelse(b %in% c("D", "E"), "negative", "other"))))
}
df$class <- class_of(df$base)
pal <- pv_palette("categorical", 5)
class_cols <- c(
  hydrophobic = pal[1], polar = pal[3], positive = pal[2],
  negative = pal[4], other = pal[5]
)

cons_base <- tapply(df$base, df$pos, function(x) names(sort(table(x), decreasing = TRUE))[1])
df$consensus <- cons_base[as.character(df$pos)]
df$differs <- df$base != df$consensus
cons <- stats::aggregate(differs ~ pos, df, function(x) 1 - mean(x))
names(cons)[2] <- "conservation"

tile_col <- if (isTRUE(highlight_diff)) ifelse(df$differs, "black", NA) else NA
df$edge <- tile_col

p_aln <- ggplot2::ggplot(df, ggplot2::aes(pos, seq, fill = class)) +
  ggplot2::geom_tile(ggplot2::aes(colour = edge), linewidth = 0.25) +
  ggplot2::geom_text(ggplot2::aes(label = base), size = 1.7, colour = "black") +
  ggplot2::scale_fill_manual(values = class_cols, name = NULL) +
  ggplot2::scale_colour_identity(guide = "none") +
  ggplot2::scale_x_continuous(breaks = seq(5, 40, by = 5), expand = c(0, 0)) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank())

if (!isTRUE(show_conservation)) {
  p <- p_aln + ggplot2::labs(x = "Position") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(), axis.ticks.x = ggplot2::element_line(linewidth = 0.35))
  pv_save(p, "figure", width_mm = 183, height_mm = 62)
} else {
  p_bar <- ggplot2::ggplot(cons, ggplot2::aes(pos, conservation)) +
    ggplot2::geom_col(width = 1, fill = pv_palette("sequential", 5)[4]) +
    ggplot2::scale_x_continuous(breaks = seq(5, 40, by = 5), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.5, 1)) +
    ggplot2::labs(x = "Position", y = "Conservation") +
    theme_viz()
  p <- cowplot::plot_grid(p_aln, p_bar, ncol = 1, rel_heights = c(3.2, 1), align = "v")
  pv_save(p, "figure", width_mm = 183, height_mm = 78)
}
message("wrote preview.png")
