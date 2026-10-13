# Enrichment dot plot (house style). Size is count, colour is -log10(p) on house_warm; optional
# ontology facets named on the strips. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

size_maps_count <- TRUE
colour_maps_p <- TRUE
facet_by_ontology <- TRUE
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$ontology <- factor(df$ontology, levels = c("BP", "MF", "CC"))
df$nlp <- -log10(df$p)
df$term <- factor(df$term, levels = df$term[order(df$ontology, df$ratio)])
hp <- pv_palette("house"); grey <- pv_palette("house_grey")

pt <- list(shape = HOUSE_POINT$shape, stroke = HOUSE_POINT$stroke, colour = HOUSE_POINT$colour)
p <- ggplot(df, aes(ratio, term))
if (isTRUE(size_maps_count) && isTRUE(colour_maps_p)) {
  p <- p + geom_point(aes(size = count, fill = nlp), shape = pt$shape, stroke = pt$stroke, colour = pt$colour)
} else if (isTRUE(size_maps_count)) {
  p <- p + geom_point(aes(size = count), fill = hp[["blue"]], shape = pt$shape, stroke = pt$stroke, colour = pt$colour)
} else {
  p <- p + geom_point(aes(fill = nlp), size = HOUSE_POINT$size, shape = pt$shape, stroke = pt$stroke, colour = pt$colour)
}
p <- p +
  scale_size_area(max_size = 4.5, name = "Count") +
  scale_fill_gradientn(colours = pv_palette("house_warm"), name = "-log10(p)",
                       breaks = function(l) pretty(l, n = 3)) +
  scale_x_continuous(expand = expansion(mult = 0.08)) +
  labs(x = "Gene ratio", y = NULL, caption = footnote) +
  theme_house() +
  theme(legend.position = "bottom", legend.box = "horizontal", legend.justification = "left",
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot") +
  guides(fill = guide_colourbar(barwidth = unit(22, "mm"), barheight = unit(2, "mm"), title.position = "top", order = 1),
         size = guide_legend(order = 2, title.position = "top", override.aes = list(fill = grey[["ci"]])))
if (isTRUE(facet_by_ontology)) {
  p <- p + facet_grid(ontology ~ ., scales = "free_y", space = "free_y") +
    theme(strip.background = element_blank(), strip.text.y = element_text(angle = 0, hjust = 0),
          panel.spacing = unit(1, "mm"))
}

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
