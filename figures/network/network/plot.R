# Correlation network (house style). Edge width is |weight|; node fill is community.
# Reads data.csv and data_nodes.csv. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

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
  cols <- setNames(rep(pv_palette("house")[["blue"]], 4), c("C1", "C2", "C3", "C4"))
} else {
  cols <- setNames(unname(pv_palette("house")[1:4]), c("C1", "C2", "C3", "C4"))
}
grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration; not biological results"

set.seed(1)
p <- ggraph::ggraph(g, layout = "fr") +
  ggraph::geom_edge_link(aes(width = weight), colour = grey[["ci"]]) +
  ggraph::geom_node_point(aes(fill = community, size = degree), shape = 21,
                          colour = HOUSE_POINT$colour, stroke = HOUSE_POINT$stroke) +
  ggraph::scale_edge_width(range = c(0.15, 0.9), guide = "none") +
  scale_fill_manual(values = cols, name = "Community") +
  scale_size(range = c(1.5, 3.4), guide = "none") +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = NULL, caption = footnote) +
  guides(fill = guide_legend(override.aes = list(size = HOUSE_POINT$size))) +
  theme_house() +
  theme(axis.line = element_blank(), panel.border = element_blank(),
        axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank(),
        panel.grid = element_blank(),
        legend.position = "top", legend.justification = "left",
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

if (isTRUE(show_labels)) {
  p <- p + ggraph::geom_node_text(aes(label = name), size = pv_pt2size(7), repel = TRUE,
                                  colour = "#1A1A1A", family = house_family())
}
if (colour_by == "none") {
  p <- p + guides(fill = "none")
}

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
