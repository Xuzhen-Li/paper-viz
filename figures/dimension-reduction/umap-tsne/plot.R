# UMAP / t-SNE. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
method_keep <- "both"   # "UMAP", "t-SNE", or "both"
show_labels <- TRUE
# ------------------

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
if (method_keep != "both") {
  df <- df[df$method == method_keep, , drop = FALSE]
}
df$cluster <- factor(df$cluster, levels = unique(df$cluster))
df$method <- factor(df$method, levels = intersect(c("UMAP", "t-SNE"), unique(df$method)))
cols <- pv_palette("categorical", nlevels(df$cluster))
names(cols) <- levels(df$cluster)

p <- ggplot2::ggplot(df, ggplot2::aes(dim1, dim2, colour = cluster)) +
  ggplot2::geom_point(size = 1.15, alpha = 0.9) +
  ggplot2::scale_colour_manual(values = cols, name = "Cluster") +
  ggplot2::labs(x = "Dimension 1", y = "Dimension 2") +
  theme_viz() +
  ggplot2::theme(
    legend.position = if (isTRUE(show_labels)) "none" else "inside",
    legend.key.size = ggplot2::unit(3, "mm")
  )

if (nlevels(df$method) > 1) {
  p <- p + ggplot2::facet_wrap(~method, scales = "free")
}

if (isTRUE(show_labels)) {
  centres <- stats::aggregate(cbind(dim1, dim2) ~ cluster + method, df, stats::median)
  centres$nudge_x <- 0
  centres$nudge_y <- 0
  # Place each label just outside its own cloud. Coordinates are method-specific.
  u_c1 <- centres$method == "UMAP" & centres$cluster == "C1"
  u_c2 <- centres$method == "UMAP" & centres$cluster == "C2"
  u_c3 <- centres$method == "UMAP" & centres$cluster == "C3"
  u_c4 <- centres$method == "UMAP" & centres$cluster == "C4"
  u_c5 <- centres$method == "UMAP" & centres$cluster == "C5"
  centres$nudge_x[u_c1] <- -1.1
  centres$nudge_y[u_c1] <- -2.0
  centres$nudge_y[u_c2] <- -2.8
  centres$nudge_x[u_c3] <- -2.2
  centres$nudge_y[u_c3] <- 0.9
  # Right of the cloud. An upward nudge lands back on the points once the
  # label is kept inside the panel.
  centres$nudge_x[u_c4] <- 1.8
  centres$nudge_y[u_c4] <- 0.15
  centres$nudge_x[u_c5] <- 1.7
  centres$nudge_y[u_c5] <- 0.55
  t_c1 <- centres$method == "t-SNE" & centres$cluster == "C1"
  t_c2 <- centres$method == "t-SNE" & centres$cluster == "C2"
  t_c3 <- centres$method == "t-SNE" & centres$cluster == "C3"
  t_c4 <- centres$method == "t-SNE" & centres$cluster == "C4"
  t_c5 <- centres$method == "t-SNE" & centres$cluster == "C5"
  centres$nudge_x[t_c1] <- -12
  centres$nudge_y[t_c2] <- 13
  centres$nudge_x[t_c3] <- -12
  centres$nudge_y[t_c3] <- 1.2
  centres$nudge_y[t_c4] <- -12
  centres$nudge_y[t_c5] <- -10
  p <- p +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.20, 0.28))) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = 0.20)) +
    ggrepel::geom_text_repel(
    data = centres,
    ggplot2::aes(dim1, dim2, label = cluster),
    colour = "black",
    size = 2.1,
    fontface = "bold",
    inherit.aes = FALSE,
    nudge_x = centres$nudge_x,
    nudge_y = centres$nudge_y,
    min.segment.length = 0,
    segment.size = 0.2,
    segment.colour = "grey35",
    box.padding = 0.25,
    point.padding = 0.15,
    force = 0.5,
    force_pull = 0,
    max.overlaps = Inf,
    seed = 11,
    show.legend = FALSE
  )
}

pv_save(p, "figure", width_mm = if (nlevels(df$method) > 1) 140 else 89, height_mm = 72)
message("wrote preview.png")
