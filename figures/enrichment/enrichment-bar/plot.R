# Enrichment bars. Horizontal layout and ontology facets are switches.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

horizontal <- TRUE
facet_ontology <- TRUE
bar_stat <- "nlp"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$nlp <- -log10(df$p)
df$ontology <- factor(df$ontology, levels = c("BP", "MF", "CC"))
df$term <- factor(df$term, levels = df$term[order(df$ontology, df$nlp)])
stat <- if (bar_stat == "fold") df$fold else df$nlp
df$stat <- stat
xlab <- if (bar_stat == "fold") "Fold enrichment" else expression(-log[10](italic(p)))
ont_pal <- pv_palette("categorical", 6)
pal <- c(BP = ont_pal[1], MF = ont_pal[6], CC = ont_pal[3])

p <- ggplot2::ggplot(df, ggplot2::aes(stat, term, fill = ontology)) +
  ggplot2::geom_col(width = 0.72) +
  ggplot2::scale_fill_manual(values = pal, name = NULL) +
  ggplot2::labs(x = xlab, y = NULL) +
  theme_viz() +
  ggplot2::theme(legend.position = "none")
if (!isTRUE(horizontal)) {
  p <- ggplot2::ggplot(df, ggplot2::aes(term, stat, fill = ontology)) +
    ggplot2::geom_col(width = 0.72) +
    ggplot2::scale_fill_manual(values = pal, name = NULL) +
    ggplot2::labs(x = NULL, y = xlab) +
    theme_viz() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 5))
}
if (isTRUE(facet_ontology)) {
  p <- p +     ggplot2::facet_grid(ontology ~ ., scales = "free_y", space = "free_y") +
    ggplot2::theme(
      strip.text.y = ggplot2::element_text(size = 7),
      legend.position = "none"
    )
}

pv_save(p, "figure", width_mm = 160, height_mm = 110)
message("wrote preview.png")
