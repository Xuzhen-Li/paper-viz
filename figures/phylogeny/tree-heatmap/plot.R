# Tree aligned to a trait heatmap, or to one trait drawn as bars.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
anno_mode <- "heatmap" # heatmap | bar
bar_trait <- "T01"
n_clade <- 4

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
edges <- df[df$trait == "", , drop = FALSE]
traits <- df[df$trait != "", , drop = FALSE]

tip_names <- sort(setdiff(edges$tip, edges$parent))
root <- setdiff(edges$parent, edges$tip)
internals <- c(root, sort(setdiff(unique(edges$parent), root)))
ids <- setNames(seq_along(c(tip_names, internals)), c(tip_names, internals))
tr <- list(
  edge = cbind(unname(ids[edges$parent]), unname(ids[edges$tip])),
  edge.length = edges$length,
  tip.label = tip_names,
  Nnode = length(internals)
)
class(tr) <- "phylo"
tr <- ape::ladderize(tr)

d <- ape::cophenetic.phylo(tr)
cl <- stats::cutree(stats::hclust(stats::as.dist(d), method = "average"), k = n_clade)
groups <- split(names(cl), sprintf("C%d", cl))
tr <- ggtree::groupOTU(tr, groups, group_name = "clade")
clade_cols <- setNames(pv_palette("categorical", n_clade), paste0("C", seq_len(n_clade)))

p <- ggtree::ggtree(tr, ggplot2::aes(colour = clade), linewidth = 0.3) +
  ggtree::geom_tiplab(size = 1.8, colour = "black", offset = 0.01, family = viz_sans_family()) +
  ggplot2::scale_colour_manual(values = clade_cols, name = "Clade", na.value = "#6B6B6B") +
  ggplot2::labs(x = "Divergence") +
  theme_viz() +
  ggplot2::theme(
    axis.line.y = ggplot2::element_blank(),
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    legend.position = "left",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

xmax <- max(p$data$x, na.rm = TRUE)
yd <- p$data[p$data$isTip, c("label", "y")]
if (anno_mode == "bar") {
  sub <- merge(traits[traits$trait == bar_trait, , drop = FALSE], yd, by.x = "tip", by.y = "label")
  x0 <- xmax + 0.55
  p <- p + ggplot2::geom_rect(
    data = sub,
    ggplot2::aes(xmin = x0, xmax = x0 + value * 0.12, ymin = y - 0.35, ymax = y + 0.35),
    fill = "#0072B2", inherit.aes = FALSE
  ) +
    ggplot2::annotate(
      "text", x = x0, y = max(yd$y) + 1.2, label = bar_trait,
      size = 2, hjust = 0, family = viz_sans_family()
    )
} else {
  sub <- merge(traits, yd, by.x = "tip", by.y = "label")
  sub$trait <- factor(sub$trait, levels = sprintf("T%02d", 1:12))
  sub$tx <- xmax + 0.7 + (as.numeric(sub$trait) - 1) * 0.11
  labs <- unique(sub[, c("trait", "tx")])
  p <- p + ggplot2::geom_tile(
    data = sub,
    ggplot2::aes(x = tx, y = y, fill = value),
    width = 0.1, height = 0.85, inherit.aes = FALSE
  ) +
    ggplot2::geom_text(
      data = labs,
      ggplot2::aes(tx, max(yd$y) + 1.15, label = trait),
      size = 1.7, angle = 45, hjust = 0, inherit.aes = FALSE, family = viz_sans_family()
    ) +
    ggplot2::scale_fill_gradientn(colours = pv_palette("diverging", 7), name = "Value")
}
p <- p + ggplot2::expand_limits(x = xmax + 2.3, y = max(yd$y) + 2.2) +
  ggplot2::coord_cartesian(clip = "off") +
  ggplot2::theme(plot.margin = ggplot2::margin(14, 8, 2, 2))

pv_save(p, "figure", width_mm = 183, height_mm = 140)
message("wrote preview.png")
