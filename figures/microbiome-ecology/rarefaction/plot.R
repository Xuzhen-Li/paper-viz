# Rarefaction curves by group, with a mean ribbon.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_individuals <- TRUE
show_ribbon <- TRUE
group_order <- c("Forest", "Cropland", "Grassland", "Wetland")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_order)
cols <- setNames(pv_palette("categorical", length(group_order)), group_order)

summ <- stats::aggregate(richness ~ group + depth, df, function(z) c(mean = mean(z), sd = stats::sd(z)))
summ <- do.call(data.frame, summ)
names(summ)[3:4] <- c("mean", "sd")
summ$ymin <- pmax(0, summ$mean - summ$sd)
summ$ymax <- summ$mean + summ$sd

p <- ggplot2::ggplot()
if (isTRUE(show_ribbon)) {
  p <- p + ggplot2::geom_ribbon(
    data = summ,
    ggplot2::aes(depth, ymin = ymin, ymax = ymax, fill = group),
    alpha = 0.18, colour = NA
  )
}
if (isTRUE(show_individuals)) {
  p <- p + ggplot2::geom_line(
    data = df,
    ggplot2::aes(depth, richness, group = sample, colour = group),
    linewidth = 0.25, alpha = 0.45
  )
}
p <- p +
  ggplot2::geom_line(
    data = summ,
    ggplot2::aes(depth, mean, colour = group),
    linewidth = 0.6
  ) +
  ggplot2::scale_colour_manual(values = cols, name = NULL) +
  ggplot2::scale_fill_manual(values = cols, name = NULL) +
  ggplot2::labs(x = "Reads", y = "Expected richness") +
  theme_viz() +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.position = "right"
  )

pv_save(p, "figure", width_mm = 140, height_mm = 90)
message("wrote preview.png")
