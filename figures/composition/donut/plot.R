# Donut (annular proportion). Reads data.csv only. Run from this directory.
# Dedicated slug; does not modify figures/composition/pie/.
source("../../../styles/r/theme_viz.R")

# 可调参数
show_labels <- TRUE
inner_r <- 1.15
outer_r <- 2.2
part_drop <- character(0)

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
if (length(part_drop)) df <- df[!df$part %in% part_drop, , drop = FALSE]
df <- df[order(df$value, decreasing = TRUE), , drop = FALSE]
df$part <- factor(df$part, levels = df$part)
df$share <- df$value / sum(df$value)
df$label <- sprintf("%s\n%.0f%%", df$part, 100 * df$share)
n_part <- nlevels(df$part)
pal <- stats::setNames(pv_palette("categorical", n_part), levels(df$part))

cx <- (inner_r + outer_r) / 2
cw <- outer_r - inner_r
lab_r <- outer_r + 0.42

p <- ggplot2::ggplot(df, ggplot2::aes(x = cx, y = value, fill = part)) +
  ggplot2::geom_col(width = cw, colour = "white", linewidth = 0.35) +
  ggplot2::scale_fill_manual(values = pal, name = NULL) +
  ggplot2::coord_polar(theta = "y", clip = "off") +
  ggplot2::xlim(0, 3.15) +
  theme_viz() +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.margin = ggplot2::margin(4, 4, 4, 4, "mm"),
    legend.position = if (isTRUE(show_labels)) "none" else "right"
  )

if (isTRUE(show_labels)) {
  p <- p + ggplot2::geom_text(
    ggplot2::aes(x = lab_r, label = label),
    position = ggplot2::position_stack(vjust = 0.5),
    size = 2.05,
    lineheight = 0.9,
    colour = "black"
  )
}

# Ring charts stay near square; not forced to 85×60 mm.
pv_save(p, "figure", width_mm = 110, height_mm = 100)
message("wrote preview.png")
