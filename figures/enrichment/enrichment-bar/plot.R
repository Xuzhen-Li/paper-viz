# Enrichment bars (house style). Horizontal layout and ontology facets are switches; the hit count
# is written at the end of each bar and the facet strips name the ontology.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

horizontal <- TRUE
facet_ontology <- TRUE
bar_stat <- "nlp"
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$nlp <- -log10(df$p)
df$ontology <- factor(df$ontology, levels = c("BP", "MF", "CC"))
df$term <- factor(df$term, levels = df$term[order(df$ontology, df$nlp)])
stat <- if (bar_stat == "fold") df$fold else df$nlp
df$stat <- stat
xlab <- if (bar_stat == "fold") "Fold enrichment" else "-log10(p)"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
pal <- c(BP = hp[["blue"]], MF = hp[["purple"]], CC = hp[["green"]])
df$n_lab <- paste0("n = ", df$count)

if (isTRUE(horizontal)) {
  p <- ggplot(df, aes(stat, term, fill = ontology)) +
    geom_col(width = 0.72) +
    geom_text(aes(label = n_lab), hjust = -0.12, size = pv_pt2size(7), colour = "#1A1A1A",
              family = house_family()) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.22))) +
    labs(x = xlab, y = NULL)
} else {
  p <- ggplot(df, aes(term, stat, fill = ontology)) +
    geom_col(width = 0.72) +
    geom_text(aes(label = count), vjust = -0.4, size = pv_pt2size(7), colour = "#1A1A1A",
              family = house_family()) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(x = NULL, y = xlab) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
p <- p +
  scale_fill_manual(values = pal, guide = "none") +
  labs(caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")
if (!isTRUE(horizontal)) p <- p + theme(axis.text.x = element_text(angle = 45, hjust = 1))
if (isTRUE(facet_ontology)) {
  p <- p + (if (isTRUE(horizontal)) facet_grid(ontology ~ ., scales = "free_y", space = "free_y")
            else facet_grid(. ~ ontology, scales = "free_x", space = "free_x")) +
    theme(strip.background = element_blank(), strip.text.y = element_text(angle = 0, hjust = 0),
          panel.spacing = unit(1, "mm"))
}

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
