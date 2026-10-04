# Stacked composition. Percent or raw counts; taxon order is a parameter.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

as_percent <- TRUE
part_levels <- c(
  "Firmicutes", "Bacteroidota", "Proteobacteria",
  "Actinobacteriota", "Verrucomicrobiota", "Other"
)

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = c("Healthy", "IBD", "Treated"))
df$part <- factor(df$part, levels = part_levels)
dom <- tapply(df$value[df$part == part_levels[1]], df$sample[df$part == part_levels[1]], sum)
ord <- unlist(lapply(levels(df$group), function(g) {
  ss <- unique(df$sample[df$group == g])
  ss[order(dom[ss], decreasing = TRUE)]
}))
df$sample <- factor(df$sample, levels = ord)
named <- setdiff(part_levels, "Other")
pal <- stats::setNames(c(pv_palette("categorical", length(named)), "#E0E0E0"), c(named, "Other"))

p <- ggplot2::ggplot(df, ggplot2::aes(sample, value, fill = part)) +
  ggplot2::geom_col(
    width = 0.86,
    position = if (isTRUE(as_percent)) "fill" else "stack",
    colour = "white", linewidth = 0.1
  ) +
  ggplot2::scale_fill_manual(values = pal, name = NULL) +
  ggplot2::scale_y_continuous(
    expand = c(0, 0),
    labels = if (isTRUE(as_percent)) scales::label_percent() else scales::label_comma()
  ) +
  ggplot2::labs(
    x = NULL,
    y = if (isTRUE(as_percent)) "Relative abundance" else "Read count"
  ) +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 0, hjust = 0.5, size = 7),
    legend.position = "bottom"
  ) +
  ggplot2::facet_grid(~ group, scales = "free_x", space = "free_x")

pv_save(p, "figure", width_mm = 183, height_mm = 95)
message("wrote preview.png")
