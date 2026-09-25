# Enrichment dot plot. Size is count, colour is p, optional ontology facets.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

size_maps_count <- TRUE
colour_maps_p <- TRUE
facet_by_ontology <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$ontology <- factor(df$ontology, levels = c("BP", "MF", "CC"))
df$nlp <- -log10(df$p)
df$term <- factor(df$term, levels = df$term[order(df$ontology, df$ratio)])

p <- ggplot2::ggplot(df, ggplot2::aes(ratio, term))
if (isTRUE(size_maps_count) && isTRUE(colour_maps_p)) {
  p <- p + ggplot2::geom_point(ggplot2::aes(size = count, colour = nlp), alpha = 0.95)
} else if (isTRUE(size_maps_count)) {
  p <- p + ggplot2::geom_point(ggplot2::aes(size = count), colour = pv_palette("categorical", 1))
} else {
  p <- p + ggplot2::geom_point(ggplot2::aes(colour = nlp), size = 2.6)
}
p <- p +
  ggplot2::scale_size_area(max_size = 6, name = "Count") +
  ggplot2::scale_colour_gradientn(
    colours = pv_palette("sequential", 5), name = expression(-log[10](italic(p)))
  ) +
  ggplot2::labs(x = "Gene ratio", y = NULL) +
  theme_viz() +
  ggplot2::theme(axis.text.y = ggplot2::element_text(size = 5))
if (isTRUE(facet_by_ontology)) {
  p <- p + ggplot2::facet_grid(ontology ~ ., scales = "free_y", space = "free_y")
}

pv_save(p, "figure", width_mm = 170, height_mm = 130)
message("wrote preview.png")
