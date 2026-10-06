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
cen$sx <- cen$x
cen$sy <- cen$y
cen$hjust <- 0.5
cen$vjust <- 0.5
# Cultivar A is the left-hand cluster; a leftward label is cut by the frame.
# Place it on the open side, toward Landrace E.
a <- cen$pop == "Cultivar A"
if (any(a)) {
  right <- max(df[[pc_x]][df$pop == "Cultivar A"])
  cen$sx[a] <- right + 0.12
  cen$sy[a] <- cen$y[a]
  cen$lx[a] <- right + 0.42
  cen$ly[a] <- cen$y[a] + 0.05
  cen$hjust[a] <- 0
}
b <- cen$pop == "Cultivar B"
if (any(b)) {
  left <- min(df[[pc_x]][df$pop == "Cultivar B"])
  bottom <- min(df[[pc_y]][df$pop == "Cultivar B"])
  cen$sx[b] <- left
  cen$sy[b] <- bottom - 0.05
  cen$lx[b] <- left - 0.2
  cen$ly[b] <- bottom - 0.9
  cen$hjust[b] <- 1
  cen$vjust[b] <- 0.5
}

p <- ggplot2::ggplot(df, ggplot2::aes(.data[[pc_x]], .data[[pc_y]], colour = pop, fill = pop)) +
  ggplot2::geom_point(size = 2.2, alpha = 0.9)
if (isTRUE(show_ellipse)) {
  p <- p + ggplot2::stat_ellipse(
    geom = "polygon", type = "norm", level = ellipse_level,
    alpha = 0.14, linewidth = 0.3, show.legend = FALSE
  )
}
if (isTRUE(show_labels)) {
  p <- p +
    ggplot2::geom_segment(
      data = cen, ggplot2::aes(x = sx, y = sy, xend = lx, yend = ly),
      inherit.aes = FALSE, linewidth = 0.2, colour = "grey35"
    ) +
    ggplot2::geom_label(
      data = cen, ggplot2::aes(lx, ly, label = pop, hjust = hjust, vjust = vjust),
      inherit.aes = FALSE,
      size = 2.0, colour = "black", fill = "white", linewidth = 0,
      label.padding = ggplot2::unit(0.12, "lines"), show.legend = FALSE
    )
}
p <- p +
  ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.22, 0.06))) +
  ggplot2::scale_colour_manual(values = pal, name = "Population") +
  ggplot2::scale_fill_manual(values = pal, guide = "none") +
  ggplot2::labs(x = axis_lab(pc_x), y = axis_lab(pc_y)) +
  theme_viz(base_size = 7) +
  ggplot2::theme(
    legend.key = ggplot2::element_blank(),
    legend.position = if (isTRUE(show_labels)) "none" else "inside"
  )

pv_save(p, "figure", width_mm = 85, height_mm = 60)
message("wrote preview.png")
