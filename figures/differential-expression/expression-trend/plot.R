# Expression trends by cluster. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
facet_clusters <- TRUE
show_smooth <- TRUE
# ------------------

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$cluster <- factor(df$cluster, levels = unique(df$cluster))
cols <- pv_palette("categorical", nlevels(df$cluster))
names(cols) <- levels(df$cluster)

mean_df <- stats::aggregate(value ~ cluster + time, df, mean)

p <- ggplot2::ggplot(df, ggplot2::aes(time, value, group = gene)) +
  ggplot2::geom_line(colour = "grey75", linewidth = 0.3) +
  ggplot2::labs(x = "Time (h)", y = "Expression (z)") +
  theme_viz()

if (isTRUE(show_smooth)) {
  p <- p + ggplot2::geom_line(
    data = mean_df,
    ggplot2::aes(time, value, colour = cluster, group = cluster),
    linewidth = 0.7,
    inherit.aes = FALSE
  ) +
    ggplot2::scale_colour_manual(values = cols, guide = "none")
}

if (isTRUE(facet_clusters)) {
  p <- p + ggplot2::facet_wrap(~cluster, ncol = 3) +
    ggplot2::theme(strip.background = ggplot2::element_blank())
}

pv_save(p, "figure", width_mm = 140, height_mm = 100)
message("wrote preview.png")
