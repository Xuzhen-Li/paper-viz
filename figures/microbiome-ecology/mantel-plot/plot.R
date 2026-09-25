# Environment correlation triangle with Mantel links to omics distances.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
p_cut <- 0.05
show_env_heatmap <- TRUE
show_links <- TRUE
link_p_only <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
env <- df[is.na(df$mantel_r), , drop = FALSE]
man <- df[!is.na(df$mantel_r), , drop = FALSE]

env_names <- unique(c(env$var_a, env$var_b))
# keep first-seen order from the file
env_names <- unique(c(env$var_a, env$var_b))
omics <- unique(man$var_a)

# mirror the triangle
swap <- env[env$var_a != env$var_b, ]
swap <- data.frame(var_a = swap$var_b, var_b = swap$var_a, r = swap$r, p = swap$p, mantel_r = NA_real_, stringsAsFactors = FALSE)
env_full <- rbind(env, swap)
env_full$x <- match(env_full$var_b, env_names)
env_full$y <- match(env_full$var_a, env_names)
# lower triangle including diagonal (y >= x in a flipped axis)
tri <- env_full[env_full$y >= env_full$x, , drop = FALSE]

if (isTRUE(link_p_only)) man <- man[man$p < p_cut, , drop = FALSE]
man$x <- length(env_names) + 0.35
man$xend <- length(env_names) + 2.4
man$y <- match(man$var_b, env_names)
om_y <- seq(1, length(env_names), length.out = length(omics))
names(om_y) <- omics
man$yend <- om_y[man$var_a]
man$sig <- ifelse(man$p < 0.01, "p < 0.01", "p < 0.05")

cols_div <- pv_palette("diverging", 7)

p <- ggplot2::ggplot()
if (isTRUE(show_env_heatmap)) {
  p <- p + ggplot2::geom_tile(
    data = tri,
    ggplot2::aes(x, y, fill = r),
    colour = "white", linewidth = 0.15
  )
}
if (isTRUE(show_links) && nrow(man)) {
  p <- p + ggplot2::geom_curve(
    data = man,
    ggplot2::aes(x = x, y = y, xend = xend, yend = yend, colour = mantel_r, linewidth = abs(mantel_r), linetype = sig),
    curvature = 0.12, alpha = 0.9
  )
}
om_df <- data.frame(name = omics, x = length(env_names) + 2.55, y = om_y[omics], stringsAsFactors = FALSE)
p <- p +
  ggplot2::geom_point(data = om_df, ggplot2::aes(x, y), size = 1.4, colour = "#1e3a5f") +
  ggplot2::geom_text(
    data = om_df, ggplot2::aes(x + 0.15, y, label = name),
    hjust = 0, size = 2.0, family = viz_sans_family()
  ) +
  ggplot2::scale_fill_gradientn(colours = cols_div, limits = c(-1, 1), name = "Pearson r", na.value = "grey90") +
  ggplot2::scale_colour_gradientn(colours = cols_div, limits = c(-1, 1), name = "Mantel r") +
  ggplot2::scale_linewidth(range = c(0.25, 0.9), guide = "none") +
  ggplot2::scale_linetype_manual(values = c("p < 0.01" = "solid", "p < 0.05" = "dashed"), name = NULL) +
  ggplot2::scale_x_continuous(
    breaks = seq_along(env_names), labels = env_names,
    expand = ggplot2::expansion(add = c(0.4, 2.2))
  ) +
  ggplot2::scale_y_continuous(breaks = seq_along(env_names), labels = env_names, expand = ggplot2::expansion(add = 0.4)) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, vjust = 1),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.position = "right",
    panel.border = ggplot2::element_blank()
  ) +
  ggplot2::coord_fixed(clip = "off")

pv_save(p, "figure", width_mm = 183, height_mm = 130)
message("wrote preview.png")
