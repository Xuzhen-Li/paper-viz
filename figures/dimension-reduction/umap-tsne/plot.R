# UMAP / t-SNE (house style). Clusters in house colours; cluster names written next to each cloud
# in the cluster colour (#1A1A1A when that colour is < 3:1 on white). Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

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
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
cols <- stats::setNames(unname(hp[seq_len(nlevels(df$cluster))]), levels(df$cluster))
name_cols <- stats::setNames(ifelse(cols %in% hp[c("orange", "sky", "gold")], "#1A1A1A", cols), names(cols))
footnote <- "Simulated data for illustration; not biological results"

p <- ggplot2::ggplot(df, ggplot2::aes(dim1, dim2, colour = cluster)) +
  ggplot2::geom_point(size = 0.8, shape = 16) +
  ggplot2::scale_colour_manual(values = cols, name = NULL) +
  ggplot2::labs(x = "Dimension 1", y = "Dimension 2", caption = footnote) +
  theme_house() +
  ggplot2::theme(
    legend.position = if (isTRUE(show_labels)) "none" else "right",
    legend.key.size = ggplot2::unit(3, "mm"),
    strip.background = ggplot2::element_blank(),
    plot.margin = ggplot2::margin(1, 2.5, 1, 1, "mm"),
    plot.caption = ggplot2::element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                         margin = ggplot2::margin(t = 0.8, unit = "mm")),
    plot.caption.position = "plot"
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
    colour = name_cols[as.character(centres$cluster)],
    size = pv_pt2size(7),
    family = house_family(),
    inherit.aes = FALSE,
    nudge_x = centres$nudge_x,
    nudge_y = centres$nudge_y,
    min.segment.length = 0,
    segment.size = 0.2,
    segment.colour = grey[["dark"]],
    box.padding = 0.25,
    point.padding = 0.15,
    force = 0.5,
    force_pull = 0,
    max.overlaps = Inf,
    seed = 11,
    show.legend = FALSE
  )
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
