# Ternary scatter (house style) in Cartesian barycentric coordinates. Cluster colours are a switch.
# The triangle and 25% grid are drawn here. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

colour_by_cluster <- TRUE
group_levels <- c("Cluster 1", "Cluster 2", "Cluster 3")
vertex_labels <- c(a = "Component A", b = "Component B", c = "Component C")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
h <- sqrt(3) / 2
df$x <- df$b * 0 + df$c * 1 + df$a * 0.5
df$y <- df$a * h
if (isTRUE(colour_by_cluster)) {
  df$group <- factor(df$group, levels = group_levels)
  pal <- stats::setNames(unname(pv_palette("house")[1:3]), group_levels)
} else {
  df$group <- factor(rep("All", nrow(df)))
  pal <- c(All = pv_palette("house")[["blue"]])
}
grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration; not biological results"

grid_line <- function(fixed, value, n = 40) {
  others <- setdiff(c("a", "b", "c"), fixed)
  t <- seq(0, 1 - value, length.out = n)
  comp <- list(a = 0, b = 0, c = 0)
  comp[[fixed]] <- value
  comp[[others[1]]] <- t
  comp[[others[2]]] <- 1 - value - t
  data.frame(
    x = comp$b * 0 + comp$c * 1 + comp$a * 0.5,
    y = comp$a * h,
    which = fixed,
    value = value
  )
}
grid <- do.call(rbind, lapply(c("a", "b", "c"), function(ax) {
  do.call(rbind, lapply(c(0.25, 0.5, 0.75), function(v) grid_line(ax, v)))
}))
grid$id <- paste(grid$which, grid$value, sep = "-")

tri <- data.frame(x = c(0.5, 0, 1), y = c(h, 0, 0))
labs <- data.frame(
  x = c(0.5, 0, 1),
  y = c(h + 0.03, -0.035, -0.035),
  label = unname(vertex_labels),
  hjust = c(0.5, 0, 1),
  vjust = c(0, 1, 1)
)

p <- ggplot() +
  geom_path(data = grid, aes(x, y, group = id), colour = grey[["light"]], linewidth = pv_house_lw("minor")) +
  geom_polygon(data = tri, aes(x, y), fill = NA, colour = grey[["dark"]], linewidth = pv_house_lw("frame")) +
  geom_point(data = df, aes(x, y, fill = group), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size,
             stroke = HOUSE_POINT$stroke, colour = HOUSE_POINT$colour) +
  geom_text(data = labs, aes(x, y, label = label, hjust = hjust, vjust = vjust),
            size = pv_pt2size(7), colour = "#1A1A1A", family = house_family()) +
  scale_fill_manual(values = pal, name = NULL) +
  scale_x_continuous(breaks = NULL) + scale_y_continuous(breaks = NULL) +
  coord_equal(clip = "off", xlim = c(-0.02, 1.02), ylim = c(-0.08, h + 0.07)) +
  labs(x = NULL, y = NULL, caption = footnote) +
  theme_house() +
  theme(axis.line = element_blank(), panel.border = element_blank(),
        legend.position = "inside", legend.position.inside = c(0, 1),
        legend.justification.inside = c(0, 1),
        plot.margin = margin(1, 4, 1, 4, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
