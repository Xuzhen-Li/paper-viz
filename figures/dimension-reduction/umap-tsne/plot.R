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
  ggplot2::theme(legend.key.size = ggplot2::unit(3, "mm"))

if (nlevels(df$method) > 1) {
  p <- p + ggplot2::facet_wrap(~method, scales = "free")
}

if (isTRUE(show_labels)) {
  centres <- stats::aggregate(cbind(dim1, dim2) ~ cluster + method, df, stats::median)
  p <- p + ggplot2::geom_text(
    data = centres,
    ggplot2::aes(dim1, dim2, label = cluster),
    colour = "black",
    size = 2.1,
    fontface = "bold",
    inherit.aes = FALSE
  )
}

pv_save(p, "figure", width_mm = if (nlevels(df$method) > 1) 140 else 89, height_mm = 72)
message("wrote preview.png")
