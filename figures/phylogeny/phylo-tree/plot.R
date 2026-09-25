# Annotated phylogeny. Branch colour is population. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
layout <- "rectangular" # rectangular | circular | fan | dendrogram
show_bootstrap <- TRUE
bootstrap_min <- 70
show_tip_bar <- FALSE
show_tip_label <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)

edges_to_phylo <- function(df) {
  tip_names <- sort(setdiff(df$tip, df$parent))
  root <- setdiff(df$parent, df$tip)
  internals <- c(root, sort(setdiff(unique(df$parent), root)))
  ids <- setNames(seq_along(c(tip_names, internals)), c(tip_names, internals))
  edge <- cbind(unname(ids[df$parent]), unname(ids[df$tip]))
  bs_map <- setNames(df$bootstrap, df$tip)
  node_label <- bs_map[internals]
  node_label[is.na(node_label)] <- ""
  tr <- list(
    edge = edge,
    edge.length = df$length,
    tip.label = tip_names,
    node.label = as.character(node_label),
    Nnode = length(internals)
  )
  class(tr) <- "phylo"
  gmap <- setNames(df$group[match(tip_names, df$tip)], tip_names)
  gmap <- gmap[!is.na(gmap)]
  groups <- split(names(gmap), gmap)
  tr <- ggtree::groupOTU(tr, groups, group_name = "group")
  tr
}

tr <- edges_to_phylo(df)
lay <- if (layout == "dendrogram") "rectangular" else layout
brlen <- if (layout == "dendrogram") "none" else "branch.length"
pop_cols <- setNames(pv_palette("categorical", 4), c("North", "South", "East", "West"))

p <- ggtree::ggtree(tr, ggplot2::aes(colour = group), layout = lay, branch.length = brlen, linewidth = 0.3) +
  ggplot2::scale_colour_manual(values = pop_cols, name = "Population", na.value = "#6B6B6B") +
  ggplot2::labs(x = if (layout == "dendrogram") NULL else "Divergence") +
  theme_viz() +
  ggplot2::theme(
    axis.line.y = ggplot2::element_blank(),
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    legend.position = "right",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

if (isTRUE(show_tip_label) && layout %in% c("rectangular", "dendrogram")) {
  p <- p + ggtree::geom_tiplab(size = 1.7, colour = "black", offset = 0.002, family = viz_sans_family())
}
if (isTRUE(show_tip_label) && layout %in% c("circular", "fan")) {
  p <- p + ggtree::geom_tiplab2(size = 1.6, colour = "black", offset = 0.02, family = viz_sans_family())
}
if (isTRUE(show_bootstrap)) {
  p <- p + ggtree::geom_nodelab(
    ggplot2::aes(label = ifelse(as.numeric(label) >= bootstrap_min, label, "")),
    size = 1.5, hjust = 1.15, colour = "#333333", family = viz_sans_family()
  )
}

h <- 170
if (isTRUE(show_tip_bar) && layout %in% c("rectangular", "dendrogram")) {
  tip_len <- df[!is.na(df$group), c("tip", "length", "group")]
  yd <- p$data[p$data$isTip, c("label", "y")]
  tip_len <- merge(tip_len, yd, by.x = "tip", by.y = "label")
  p2 <- ggplot2::ggplot(tip_len, ggplot2::aes(length, y, fill = group)) +
    ggplot2::geom_col(width = 0.7, orientation = "y") +
    ggplot2::scale_fill_manual(values = pop_cols, guide = "none") +
    ggplot2::scale_y_continuous(limits = range(p$data$y) + c(-0.5, 0.5), expand = c(0, 0)) +
    ggplot2::labs(x = "Tip length", y = NULL) +
    theme_viz() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      axis.line.y = ggplot2::element_blank(),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
  p <- cowplot::plot_grid(p, p2, nrow = 1, align = "h", axis = "tb", rel_widths = c(1.4, 0.45))
  h <- 180
}

pv_save(p, "figure", width_mm = 183, height_mm = if (layout %in% c("circular", "fan")) 160 else h)
message("wrote preview.png")
