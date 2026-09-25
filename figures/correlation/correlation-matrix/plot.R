# Correlation matrix. Circle or square; optional stars; optional upper triangle.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

cell_shape <- "circle"
show_significance <- TRUE
upper_only <- TRUE
sig_cut <- 0.05

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
vars <- unique(c(df$var_a, df$var_b))
r_mat <- matrix(0, length(vars), length(vars), dimnames = list(vars, vars))
diag(r_mat) <- 1
r_mat[cbind(df$var_a, df$var_b)] <- df$r
r_mat[cbind(df$var_b, df$var_a)] <- df$r
ord <- vars[stats::hclust(stats::as.dist(1 - r_mat))$order]
df$var_a <- factor(df$var_a, levels = ord)
df$var_b <- factor(df$var_b, levels = ord)
ia <- as.integer(df$var_a)
ib <- as.integer(df$var_b)
keep <- if (isTRUE(upper_only)) ia < ib else ia != ib
plot_df <- df[keep, , drop = FALSE]
plot_df$stars <- ifelse(plot_df$p < sig_cut, "*", "")
fills <- pv_palette("diverging", 9)

p <- ggplot2::ggplot(plot_df, ggplot2::aes(var_a, var_b, fill = r))
if (cell_shape == "square") {
  p <- p + ggplot2::geom_tile(colour = "white", linewidth = 0.2)
} else {
  p <- p + ggplot2::geom_point(ggplot2::aes(size = abs(r)), shape = 21, stroke = 0.15)
  p <- p + ggplot2::scale_size_area(max_size = 5.5, limits = c(0, 1), guide = "none")
}
if (isTRUE(show_significance)) {
  p <- p + ggplot2::geom_text(ggplot2::aes(label = stars), size = 2.2, colour = "black")
}
p <- p +
  ggplot2::scale_fill_gradientn(colours = fills, limits = c(-1, 1), name = "r") +
  ggplot2::scale_x_discrete(drop = FALSE) +
  ggplot2::scale_y_discrete(drop = FALSE) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 5.5),
    axis.text.y = ggplot2::element_text(size = 5.5),
    legend.key.height = ggplot2::unit(8, "mm")
  )

pv_save(p, "figure", width_mm = 140, height_mm = 120)
message("wrote preview.png")
