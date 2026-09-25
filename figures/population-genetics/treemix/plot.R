# TreeMix-style drift tree with migration arrows coloured by weight.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_migration <- TRUE
show_residual <- FALSE
arrow_curvature <- 0.25

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
edges <- df[nzchar(df$pop), , drop = FALSE]
migs <- df[nzchar(df$mig_from), , drop = FALSE]

tip_names <- sort(setdiff(edges$pop, edges$parent))
root <- setdiff(edges$parent, edges$pop)
internals <- c(root, sort(setdiff(unique(edges$parent), root)))
ids <- setNames(seq_along(c(tip_names, internals)), c(tip_names, internals))
tr <- list(
  edge = cbind(unname(ids[edges$parent]), unname(ids[edges$pop])),
  edge.length = edges$drift,
  tip.label = tip_names,
  Nnode = length(internals)
)
class(tr) <- "phylo"

p <- ggtree::ggtree(tr, linewidth = 0.35, colour = "#1e3a5f") +
  ggtree::geom_tiplab(size = 2.1, offset = 0.15, family = viz_sans_family()) +
  ggplot2::labs(x = "Drift") +
  theme_viz() +
  ggplot2::theme(
    axis.line.y = ggplot2::element_blank(),
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.position = "right"
  )

if (isTRUE(show_migration) && nrow(migs)) {
  dd <- p$data
  # arrow leaves the parent of the source tip and arrives at the parent of the target
  # midpoint of the terminal branch, left of the tip label
  mid_of <- function(tip) {
    child <- dd[dd$label == tip, , drop = FALSE]
    parent <- dd[dd$node == child$parent[1], , drop = FALSE]
    data.frame(x = parent$x, y = child$y, stringsAsFactors = FALSE)
  }
  seg <- lapply(seq_len(nrow(migs)), function(i) {
    a <- mid_of(migs$mig_from[i])
    b <- mid_of(migs$mig_to[i])
    data.frame(
      x = a$x, y = a$y, xend = b$x, yend = b$y,
      weight = migs$weight[i],
      stringsAsFactors = FALSE
    )
  })
  seg <- do.call(rbind, seg)
  p <- p + ggplot2::geom_curve(
    data = seg,
    ggplot2::aes(x = x, y = y, xend = xend, yend = yend, colour = weight),
    curvature = arrow_curvature,
    arrow = grid::arrow(length = grid::unit(1.4, "mm"), type = "closed"),
    linewidth = 0.45,
    inherit.aes = FALSE
  ) +
    ggplot2::scale_colour_gradientn(
      colours = c("#FEE0B6", "#FDB863", "#E08214", "#B35806"),
      name = "Weight"
    )
}

if (isTRUE(show_residual)) {
  res <- utils::read.csv("data_residual.csv", stringsAsFactors = FALSE)
  pops <- sort(unique(res$pop_a))
  res$pop_a <- factor(res$pop_a, levels = pops)
  res$pop_b <- factor(res$pop_b, levels = rev(pops))
  pr <- ggplot2::ggplot(res, ggplot2::aes(pop_a, pop_b, fill = residual)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.15) +
    ggplot2::scale_fill_gradientn(colours = pv_palette("diverging", 7), name = "Residual") +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_viz() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
  p <- cowplot::plot_grid(p, pr, nrow = 1, rel_widths = c(1.15, 0.9))
}

pv_save(p, "figure", width_mm = 160, height_mm = 110)
message("wrote preview.png")
