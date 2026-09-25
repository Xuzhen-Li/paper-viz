# Correlation network. Edge width is |weight|; colour is community.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
weight_min <- 0.30
show_labels <- FALSE
colour_by <- "community" # community | none

edges <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
nodes <- utils::read.csv("data_nodes.csv", stringsAsFactors = FALSE)
edges <- edges[edges$weight >= weight_min, , drop = FALSE]
# drop isolated nodes after the threshold
keep <- unique(c(edges$from, edges$to))
nodes <- nodes[nodes$node %in% keep, , drop = FALSE]

g <- igraph::graph_from_data_frame(edges[, c("from", "to", "weight")], directed = FALSE, vertices = nodes)
igraph::V(g)$degree <- igraph::degree(g)
if (colour_by == "none") {
  cols <- setNames(rep("#2A629A", 4), c("C1", "C2", "C3", "C4"))
} else {
  cols <- setNames(pv_palette("categorical", 4), c("C1", "C2", "C3", "C4"))
}

set.seed(1)
p <- ggraph::ggraph(g, layout = "fr") +
  ggraph::geom_edge_link(ggplot2::aes(width = weight), colour = "#9A9A9A", alpha = 0.75) +
  ggraph::geom_node_point(ggplot2::aes(colour = community, size = degree)) +
  ggraph::scale_edge_width(range = c(0.15, 0.9), name = "Weight") +
  ggplot2::scale_colour_manual(values = cols, name = "Community") +
  ggplot2::scale_size(range = c(1.2, 3.2), name = "Degree") +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.line = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.position = "right"
  )

if (isTRUE(show_labels)) {
  p <- p + ggraph::geom_node_text(
    ggplot2::aes(label = name),
    size = 1.6, repel = TRUE, family = viz_sans_family()
  )
}
if (colour_by == "none") {
  p <- p + ggplot2::guides(colour = "none")
}

pv_save(p, "figure", width_mm = 140, height_mm = 120)
message("wrote preview.png")
