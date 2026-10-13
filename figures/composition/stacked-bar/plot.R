# Stacked composition (house style). Percent or raw counts; taxon order is a parameter.
# Samples sorted by the first taxon within each group; "Other" stays light grey on top.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

as_percent <- TRUE
part_levels <- c(
  "Firmicutes", "Bacteroidota", "Proteobacteria",
  "Actinobacteriota", "Verrucomicrobiota", "Other"
)
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = c("Healthy", "IBD", "Treated"))
df$part <- factor(df$part, levels = part_levels)
first <- df$part == part_levels[1]
dom <- tapply(df$value[first], df$sample[first], sum)
ord <- unlist(lapply(levels(df$group), function(g) {
  ss <- unique(df$sample[df$group == g])
  ss[order(dom[ss], decreasing = TRUE)]
}))
df$sample <- factor(df$sample, levels = ord)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
named <- setdiff(part_levels, "Other")
pal <- stats::setNames(c(unname(hp[seq_along(named)]), grey[["light"]]), c(named, "Other"))

p <- ggplot(df, aes(sample, value, fill = part)) +
  geom_col(width = 0.86, position = if (isTRUE(as_percent)) "fill" else "stack",
           colour = "white", linewidth = 0.1) +
  scale_fill_manual(values = pal, name = NULL) +
  scale_y_continuous(expand = c(0, 0),
                     labels = if (isTRUE(as_percent)) scales::label_percent() else scales::label_comma()) +
  facet_grid(~ group, scales = "free_x", space = "free_x") +
  labs(x = NULL, y = if (isTRUE(as_percent)) "Relative abundance" else "Read count", caption = footnote) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE, keywidth = unit(2.5, "mm"), keyheight = unit(2.5, "mm"))) +
  theme_house() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
        legend.position = "top", legend.justification = "left",
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1, "mm"),
        legend.text = element_text(size = 7), legend.key.spacing.y = unit(0.4, "mm"),
        panel.spacing.x = unit(1.5, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
