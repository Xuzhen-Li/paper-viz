# Slope chart. Highlighted series are coloured and both ends are labeled.
source("../../../styles/r/theme_viz.R")

# 可调参数
highlight <- c("P04", "P07", "P11")
label_ends <- TRUE
stage_levels <- c("Before", "After")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$stage <- factor(df$stage, levels = stage_levels)
df$item <- factor(df$item, levels = unique(df$item))
df$emph <- ifelse(df$item %in% highlight, as.character(df$item), "Other")
emph_levels <- c("Other", highlight)
pal <- setNames(
  c("#B0B0B0", pv_palette("categorical", length(highlight))),
  emph_levels
)

p <- ggplot2::ggplot(df, ggplot2::aes(stage, value, group = item, colour = emph)) +
  ggplot2::geom_line(linewidth = 0.45) +
  ggplot2::geom_point(size = 1.6) +
  ggplot2::scale_colour_manual(values = pal, breaks = highlight, name = NULL) +
  ggplot2::labs(x = NULL, y = "Index") +
  theme_viz() +
  ggplot2::theme(legend.position = "top")

if (label_ends) {
  ends <- df[df$emph != "Other", ]
  p <- p + ggrepel::geom_text_repel(
    data = ends,
    ggplot2::aes(label = item),
    size = 2.1,
    direction = "y",
    min.segment.length = 0,
    segment.size = 0.2,
    box.padding = 0.25,
    show.legend = FALSE,
    seed = 51
  )
}

pv_save(p, "figure", width_mm = 100, height_mm = 105)
message("wrote preview.png")
