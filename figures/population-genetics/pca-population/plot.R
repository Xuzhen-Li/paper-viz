# Population PCA. Reads data.csv and data_variance.csv.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_ellipse <- TRUE
show_labels <- TRUE
ellipse_level <- 0.95
pc_x <- "PC1"
pc_y <- "PC2"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
ve <- utils::read.csv("data_variance.csv", stringsAsFactors = FALSE)
ve_map <- stats::setNames(ve$var_explained, ve$pc)
pop_order <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")
df$pop <- factor(df$pop, levels = pop_order)
pal <- pv_palette("categorical", 6)
names(pal) <- pop_order

axis_lab <- function(pc) sprintf("%s (%.1f%%)", pc, ve_map[[pc]])
cen <- aggregate(df[, c(pc_x, pc_y)], list(pop = df$pop), mean)
names(cen) <- c("pop", "x", "y")
cx <- mean(cen$x)
cy <- mean(cen$y)
cen$dx <- cen$x - cx
cen$dy <- cen$y - cy
len <- sqrt(cen$dx^2 + cen$dy^2)
cen$lx <- cen$x + cen$dx / len * 2.2
cen$ly <- cen$y + cen$dy / len * 1.7

p <- ggplot2::ggplot(df, ggplot2::aes(.data[[pc_x]], .data[[pc_y]], colour = pop, fill = pop)) +
  ggplot2::geom_point(size = 1.35, alpha = 0.9)
if (isTRUE(show_ellipse)) {
  p <- p + ggplot2::stat_ellipse(
    geom = "polygon", type = "norm", level = ellipse_level,
    alpha = 0.14, linewidth = 0.3, show.legend = FALSE
  )
}
if (isTRUE(show_labels)) {
  p <- p +
    ggplot2::geom_segment(
      data = cen, ggplot2::aes(x = x, y = y, xend = lx, yend = ly),
      inherit.aes = FALSE, linewidth = 0.2, colour = "grey35"
    ) +
    ggplot2::geom_label(
      data = cen, ggplot2::aes(lx, ly, label = pop), inherit.aes = FALSE,
      size = 2.0, colour = "black", fill = "white", linewidth = 0,
      label.padding = ggplot2::unit(0.12, "lines"), show.legend = FALSE
    )
}
p <- p +
  ggplot2::scale_colour_manual(values = pal, name = "Population") +
  ggplot2::scale_fill_manual(values = pal, guide = "none") +
  ggplot2::labs(x = axis_lab(pc_x), y = axis_lab(pc_y)) +
  theme_viz() +
  ggplot2::theme(legend.key = ggplot2::element_blank())

pv_save(p, "figure", width_mm = 140, height_mm = 100)
message("wrote preview.png")
