# Parallel coordinates. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
highlight_group <- "Batch-A"  # one group name, or "none" to colour every group
# ------------------

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
axes <- unique(df$axis)
df$axis <- factor(df$axis, levels = axes)
df$group <- factor(df$group, levels = unique(df$group))
scaled <- lapply(split(df, df$axis), function(d) {
  rng <- range(d$value)
  d$y <- if (diff(rng) == 0) 0.5 else (d$value - rng[1]) / diff(rng)
  d
})
df <- do.call(rbind, scaled)

base <- ggplot2::ggplot(df, ggplot2::aes(axis, y, group = item)) +
  ggplot2::labs(x = NULL, y = "Scaled value") +
  theme_viz() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))

if (highlight_group == "none") {
  cols <- pv_palette("categorical", nlevels(df$group))
  names(cols) <- levels(df$group)
  p <- base +
    ggplot2::geom_line(ggplot2::aes(colour = group), alpha = 0.55, linewidth = 0.35) +
    ggplot2::scale_colour_manual(values = cols, name = NULL)
} else {
  df$emph <- factor(
    ifelse(df$group == highlight_group, as.character(df$group), "Other"),
    levels = c(highlight_group, "Other")
  )
  other <- df[df$emph == "Other", , drop = FALSE]
  hi <- df[df$emph != "Other", , drop = FALSE]
  emph_cols <- stats::setNames(
    c(pv_palette("categorical", 1), "#E0E0E0"),
    c(highlight_group, "Other")
  )
  p <- base +
    ggplot2::geom_line(
      data = other, ggplot2::aes(colour = emph), alpha = 1, linewidth = 0.3
    ) +
    ggplot2::geom_line(
      data = hi, ggplot2::aes(colour = emph), linewidth = 0.45, alpha = 0.9
    ) +
    ggplot2::scale_colour_manual(
      values = emph_cols, breaks = c(highlight_group, "Other"), name = NULL
    ) +
    ggplot2::theme(legend.position = "bottom")
}

pv_save(p, "figure", width_mm = 140, height_mm = 78)
message("wrote preview.png")
