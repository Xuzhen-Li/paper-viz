# TreeMix-style drift tree (house style) with migration arrows coloured by weight on house_warm;
# optional residual matrix on house_div beside it (patchwork). The tree panel has no frame.
# Reads data.csv (and data_residual.csv when show_residual = TRUE). Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_migration <- TRUE
show_residual <- FALSE
arrow_curvature <- 0.55

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
edges <- df[nzchar(df$pop), , drop = FALSE]
migs <- df[nzchar(df$mig_from), , drop = FALSE]

tip_names <- sort(setdiff(edges$pop, edges$parent))
root <- setdiff(edges$parent, edges$pop)
internals <- c(root, sort(setdiff(unique(edges$parent), root)))
ids <- setNames(seq_along(c(tip_names, internals)), c(tip_names, internals))
tr <- list(
  edge = cbind(unname(ids[edges$parent]), unname(ids[edges$pop])),
  edge.length = edges$drift,
  tip.label = tip_names,
  Nnode = length(internals)
)
class(tr) <- "phylo"

p <- ggtree::ggtree(tr, linewidth = pv_house_lw("main"), colour = grey[["dark"]]) +
  ggtree::geom_tiplab(size = pv_pt2size(7), offset = 0.14, family = house_family(), colour = "#1A1A1A") +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.12))) +
  labs(x = "Drift parameter", caption = footnote) +
  theme_house() +
  theme(
    panel.border = element_blank(),
    axis.line.x = element_line(linewidth = pv_house_lw("frame"), colour = "black"),
    axis.line.y = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    legend.position = "inside", legend.position.inside = c(0.02, 0.98),
    legend.justification.inside = c(0, 1), legend.direction = "horizontal",
    legend.title = element_text(size = 7, margin = margin(b = 0.8, unit = "mm")),
    legend.text = element_text(size = 7),
    legend.key.width = unit(8, "mm"), legend.key.height = unit(2, "mm"),
    plot.margin = margin(1, 1.5, 1, 1, "mm")
  ) +
  caption_theme

if (isTRUE(show_migration) && nrow(migs)) {
  dd <- p$data
  # arrow leaves the parent of the source tip and arrives at the parent of the target
  # midpoint of the terminal branch, left of the tip label
  mid_of <- function(tip) {
    child <- dd[dd$label == tip, , drop = FALSE]
    parent <- dd[dd$node == child$parent[1], , drop = FALSE]
    data.frame(x = parent$x, y = child$y, stringsAsFactors = FALSE)
  }
  seg <- lapply(seq_len(nrow(migs)), function(i) {
    a <- mid_of(migs$mig_from[i])
    b <- mid_of(migs$mig_to[i])
    data.frame(
      x = a$x, y = a$y, xend = b$x, yend = b$y,
      weight = migs$weight[i],
      stringsAsFactors = FALSE
    )
  })
  seg <- do.call(rbind, seg)
  p <- p + geom_curve(
    data = seg,
    aes(x = x, y = y, xend = xend, yend = yend, colour = weight),
    curvature = arrow_curvature,
    arrow = grid::arrow(length = grid::unit(1.4, "mm"), type = "closed"),
    linewidth = pv_house_lw("main"),
    inherit.aes = FALSE
  ) +
    scale_colour_gradientn(colours = pv_palette("house_warm"), name = "Migration weight",
                           breaks = function(l) pretty(l, n = 2),
                           guide = guide_colourbar(title.position = "top"))
}

if (isTRUE(show_residual)) {
  res <- utils::read.csv("data_residual.csv", stringsAsFactors = FALSE)
  pops <- sort(unique(res$pop_a))
  res$pop_a <- factor(res$pop_a, levels = pops)
  res$pop_b <- factor(res$pop_b, levels = rev(pops))
  pr <- ggplot(res, aes(pop_a, pop_b, fill = residual)) +
    geom_tile(colour = "white", linewidth = 0.3) +
    scale_fill_gradientn(colours = pv_palette("house_div"), name = "Residual",
                         limits = c(-1, 1) * max(abs(res$residual))) +
    coord_fixed() +
    labs(x = NULL, y = NULL) +
    theme_house() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5), axis.ticks = element_blank(),
          legend.title = element_text(size = 7), legend.text = element_text(size = 7),
          legend.key.width = unit(2, "mm"), legend.key.height = unit(10, "mm"))
  p <- patchwork::wrap_plots(p, pr, nrow = 1, widths = c(1.15, 0.9))
}

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
