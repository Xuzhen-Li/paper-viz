# STAMP-style mean-difference bars with 95% CI.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
p_cut <- 0.05
show_ci <- TRUE
label_p <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$taxon <- factor(df$taxon, levels = df$taxon[order(df$diff)])
df$direction <- ifelse(df$diff >= 0, "higher in B", "higher in A")
df$sig <- df$p < p_cut
cols <- c("higher in A" = pv_palette("categorical", 3)[3], "higher in B" = pv_palette("categorical", 4)[4])

p <- ggplot2::ggplot(df, ggplot2::aes(diff, taxon, colour = direction)) +
  ggplot2::geom_vline(xintercept = 0, linewidth = 0.3, colour = "black")
if (isTRUE(show_ci)) {
  p <- p + ggplot2::geom_errorbar(
    ggplot2::aes(xmin = low, xmax = high),
    orientation = "y", width = 0.25, linewidth = 0.3
  )
}
p <- p +
  ggplot2::geom_point(ggplot2::aes(shape = sig), size = 1.6) +
  ggplot2::scale_colour_manual(values = cols, name = NULL) +
  ggplot2::scale_shape_manual(
    values = c(`TRUE` = 16, `FALSE` = 1),
    breaks = c(TRUE, FALSE),
    labels = c("yes", "no"),
    name = sprintf("p < %s", p_cut)
  ) +
  ggplot2::labs(x = "Mean proportion difference (B - A)", y = NULL) +
  theme_viz() +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.position = "bottom",
    legend.box = "horizontal"
  )
if (isTRUE(label_p)) {
  p <- p + ggplot2::geom_text(
    ggplot2::aes(x = max(high) + 0.012, label = sprintf("%.3f", p)),
    colour = "black", size = 1.7, hjust = 0, family = viz_sans_family()
  ) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme(plot.margin = ggplot2::margin(4, 28, 4, 4))
}

pv_save(p, "figure", width_mm = 140, height_mm = 120)
message("wrote preview.png")
