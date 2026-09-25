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
  df$emph <- ifelse(df$group == highlight_group, as.character(df$group), "other")
  other <- df[df$emph == "other", , drop = FALSE]
  hi <- df[df$emph != "other", , drop = FALSE]
  p <- base +
    ggplot2::geom_line(data = other, colour = "grey78", alpha = 0.7, linewidth = 0.3) +
    ggplot2::geom_line(data = hi, colour = pv_palette("categorical", 1), linewidth = 0.45, alpha = 0.9)
}

pv_save(p, "figure", width_mm = 140, height_mm = 78)
message("wrote preview.png")
