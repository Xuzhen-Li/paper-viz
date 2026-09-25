# Sampling map. Reads data.csv. Coastline from ggplot2::map_data (no network).
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_hull <- TRUE
show_pie <- FALSE
show_labels <- TRUE
pops_show <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$pop %in% pops_show, ]
df$pop <- factor(df$pop, levels = pops_show)
pal <- pv_palette("categorical", length(pops_show))
names(pal) <- pops_show

world <- ggplot2::map_data("world")
hulls <- do.call(rbind, lapply(split(df, df$pop), function(d) {
  if (nrow(d) < 3) return(NULL)
  h <- chull(d$x, d$y)
  d[c(h, h[1]), ]
}))

p <- ggplot2::ggplot() +
  ggplot2::geom_polygon(
    data = world, ggplot2::aes(long, lat, group = group),
    fill = "#F7F7F7", colour = "#C8C8C8", linewidth = 0.15
  )
if (isTRUE(show_hull) && !isTRUE(show_pie) && nrow(hulls)) {
  p <- p + ggplot2::geom_polygon(
    data = hulls, ggplot2::aes(x, y, group = pop, fill = pop),
    alpha = 0.18, colour = NA, show.legend = FALSE
  )
}
p <- p +
  ggplot2::geom_point(
    data = df, ggplot2::aes(x, y, colour = pop, size = n), alpha = 0.95
  ) +
  ggplot2::scale_colour_manual(values = pal, name = "Population") +
  ggplot2::scale_fill_manual(values = pal, guide = "none") +
  ggplot2::scale_size_continuous(name = "Samples", range = c(1.1, 3.2), breaks = c(10, 20, 30)) +
  ggplot2::coord_quickmap(xlim = c(100, 126), ylim = c(20, 45)) +
  ggplot2::labs(x = "Longitude", y = "Latitude") +
  theme_viz() +
  ggplot2::theme(legend.key = ggplot2::element_blank())
if (isTRUE(show_labels)) {
  cen <- do.call(rbind, lapply(split(df, df$pop), function(d) {
    data.frame(
      pop = d$pop[1], x = median(d$x), y = median(d$y),
      lx = median(d$x), ly = max(d$y) + 0.9,
      stringsAsFactors = FALSE
    )
  }))
  p <- p +
    ggplot2::geom_segment(
      data = cen, ggplot2::aes(x = x, y = y, xend = lx, yend = ly),
      linewidth = 0.2, colour = "grey40", inherit.aes = FALSE
    ) +
    ggplot2::geom_label(
      data = cen, ggplot2::aes(lx, ly, label = pop),
      size = 1.9, colour = "black", fill = "white", linewidth = 0,
      label.padding = ggplot2::unit(0.1, "lines"), inherit.aes = FALSE
    )
}

pv_save(p, "figure", width_mm = 150, height_mm = 120)
message("wrote preview.png")
