# Sampling map (house style): sites sized by sample number and coloured by population on the geo
# palette (north -> south), optional convex hulls, population names written beside their sites.
# Coastline from ggplot2::map_data (maps package, no network). Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_hull <- TRUE
show_pie <- FALSE
show_labels <- TRUE
pops_show <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")
# side of its site group each population name sits on: left, right, above, below or above_left
# (above, shifted west)
label_side <- c("Wild N" = "left", "Wild S" = "right", "Landrace E" = "above_left",
                "Landrace W" = "below", "Cultivar A" = "left", "Cultivar B" = "below")
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# label text: the group colour if it reaches 3:1 contrast on white, else #1A1A1A (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  stats::setNames(ifelse(ratio >= 3, hex, "#1A1A1A"), names(hex))
}
caption_theme <- theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                                   lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
                       plot.caption.position = "plot")
# push end-of-line label positions apart to at least `gap` (data units), keeping their order
spread <- function(y, gap) {
  o <- order(y); z <- y[o]
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  shift <- mean(z) - mean(y[o]); z <- z - shift
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  y[o] <- z; y
}
# fixed house colour per population (same in every B2 figure)
pop_cols <- c("Wild N" = hp[["blue"]], "Wild S" = hp[["sky"]], "Landrace E" = hp[["green"]],
              "Landrace W" = hp[["gold"]], "Cultivar A" = hp[["red"]], "Cultivar B" = hp[["purple"]])
# populations ordered by geography (mean sampling latitude, north -> south) on the geo palette
pop_geo <- stats::setNames(pv_palette("geo"),
                           c("Wild N", "Cultivar A", "Landrace W", "Landrace E", "Cultivar B", "Wild S"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$pop %in% pops_show, ]
df$pop <- factor(df$pop, levels = pops_show)
cols <- pop_geo[pops_show]
xlim <- c(100, 126); ylim <- c(20, 45)

world <- map_data("world")
hulls <- do.call(rbind, lapply(split(df, df$pop), function(d) {
  if (nrow(d) < 3) return(NULL)
  h <- grDevices::chull(d$x, d$y)
  d[c(h, h[1]), ]
}))

p <- ggplot() +
  geom_polygon(data = world, aes(long, lat, group = group),
               fill = grey[["bg"]], colour = grey[["ci"]], linewidth = pv_house_lw("minor"))
if (isTRUE(show_hull) && !isTRUE(show_pie) && !is.null(hulls) && nrow(hulls)) {
  p <- p + geom_polygon(data = hulls, aes(x, y, group = pop, fill = pop), alpha = 0.18,
                        colour = NA, show.legend = FALSE)
}
p <- p +
  geom_point(data = df, aes(x, y, fill = pop, size = n), shape = HOUSE_POINT$shape,
             stroke = HOUSE_POINT$stroke, colour = HOUSE_POINT$colour) +
  scale_fill_manual(values = cols, guide = "none") +
  scale_size_area(name = "Samples", max_size = 3.2, breaks = c(10, 20, 30)) +
  coord_quickmap(xlim = xlim, ylim = ylim, expand = FALSE) +
  scale_x_continuous(breaks = seq(105, 120, 5), labels = function(x) paste0(x, "\u00b0E")) +
  scale_y_continuous(breaks = seq(25, 40, 5), labels = function(x) paste0(x, "\u00b0N")) +
  labs(x = NULL, y = NULL, caption = footnote) +
  guides(size = guide_legend(override.aes = list(fill = grey[["ci"]]))) +
  theme_house() +
  theme(axis.ticks = element_blank(),
        legend.position = "inside", legend.position.inside = c(0.02, 0.98),
        legend.justification.inside = c(0, 1),
        legend.background = element_rect(fill = "white", colour = NA),
        legend.title = element_text(size = 7), legend.text = element_text(size = 7),
        plot.margin = margin(1, 1.5, 1, 1, "mm")) +
  caption_theme
if (isTRUE(show_labels)) {
  # fixed coordinates just outside the population's sites (no repel)
  pad <- 0.9
  cen <- do.call(rbind, lapply(split(df, df$pop, drop = TRUE), function(d) {
    g <- as.character(d$pop[1])
    side <- if (g %in% names(label_side)) label_side[[g]] else "right"
    switch(side,
      left  = data.frame(pop = g, x = min(d$x) - pad, y = stats::median(d$y), hjust = 1, vjust = 0.5),
      right = data.frame(pop = g, x = max(d$x) + pad, y = stats::median(d$y), hjust = 0, vjust = 0.5),
      above = data.frame(pop = g, x = stats::median(d$x), y = max(d$y) + pad, hjust = 0.5, vjust = 0),
      above_left = data.frame(pop = g, x = stats::median(d$x), y = max(d$y) + pad, hjust = 0.62, vjust = 0),
      below = data.frame(pop = g, x = stats::median(d$x), y = min(d$y) - pad, hjust = 0.5, vjust = 1))
  }))
  p <- p + geom_text(data = cen, aes(x, y, label = pop, hjust = hjust, vjust = vjust),
                     colour = text_col(cols)[cen$pop], size = pv_pt2size(7), family = house_family())
}

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
