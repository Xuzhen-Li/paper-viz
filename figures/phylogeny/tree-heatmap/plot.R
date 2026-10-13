# Tree aligned to a trait heatmap (house_div, symmetric around 0) or to one trait drawn as bars
# (house style). Branches coloured by clade (house colours); clade names written at each clade's
# strip instead of a legend. The tree panel has no frame. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
anno_mode <- "heatmap" # heatmap | bar
bar_trait <- "T01"
n_clade <- 4

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
edges <- df[df$trait == "", , drop = FALSE]
traits <- df[df$trait != "", , drop = FALSE]

tip_names <- sort(setdiff(edges$tip, edges$parent))
root <- setdiff(edges$parent, edges$tip)
internals <- c(root, sort(setdiff(unique(edges$parent), root)))
ids <- setNames(seq_along(c(tip_names, internals)), c(tip_names, internals))
tr <- list(
  edge = cbind(unname(ids[edges$parent]), unname(ids[edges$tip])),
  edge.length = edges$length,
  tip.label = tip_names,
  Nnode = length(internals)
)
class(tr) <- "phylo"
tr <- ape::ladderize(tr)

d <- ape::cophenetic.phylo(tr)
cl <- stats::cutree(stats::hclust(stats::as.dist(d), method = "average"), k = n_clade)
groups <- split(names(cl), sprintf("C%d", cl))
tr <- ggtree::groupOTU(tr, groups, group_name = "clade")
clade_cols <- stats::setNames(unname(hp[c("blue", "red", "green", "purple", "brown", "magenta")][seq_len(n_clade)]),
                             paste0("C", seq_len(n_clade)))

p <- ggtree::ggtree(tr, aes(colour = clade), linewidth = pv_house_lw("main")) +
  ggtree::geom_tiplab(size = pv_pt2size(7), colour = "#1A1A1A", offset = 0.02, family = house_family()) +
  scale_colour_manual(values = clade_cols, guide = "none", na.value = grey[["dark"]]) +
  labs(x = "Divergence", caption = footnote) +
  theme_house() +
  theme(
    panel.border = element_blank(),
    axis.line.x = element_line(linewidth = pv_house_lw("frame")),
    axis.line.y = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    legend.position = "bottom", legend.justification = "right",
    legend.title = element_text(size = 7), legend.text = element_text(size = 7)
  ) +
  caption_theme
# clade names as strips right of the annotation (no legend)
td <- p$data[p$data$isTip, c("label", "y")]
td$clade <- as.character(cl[td$label]); td$clade <- paste0("C", td$clade)
cs <- do.call(rbind, lapply(split(td, td$clade), function(d)
  data.frame(clade = d$clade[1], y0 = min(d$y) - 0.35, y1 = max(d$y) + 0.35, ym = mean(range(d$y)))))

xmax <- max(p$data$x, na.rm = TRUE)
yd <- p$data[p$data$isTip, c("label", "y")]
if (anno_mode == "bar") {
  sub <- merge(traits[traits$trait == bar_trait, , drop = FALSE], yd, by.x = "tip", by.y = "label")
  x0 <- xmax + 0.55
  p <- p + geom_rect(
    data = sub,
    aes(xmin = x0, xmax = x0 + value * 0.12, ymin = y - 0.35, ymax = y + 0.35),
    fill = grey[["ref"]], inherit.aes = FALSE
  ) +
    annotate("text", x = x0, y = max(yd$y) + 1.2, label = bar_trait,
             size = pv_pt2size(7), hjust = 0, family = house_family())
} else {
  sub <- merge(traits, yd, by.x = "tip", by.y = "label")
  sub$trait <- factor(sub$trait, levels = sprintf("T%02d", 1:12))
  sub$tx <- xmax + 0.5 + (as.numeric(sub$trait) - 1) * 0.16
  labs <- unique(sub[, c("trait", "tx")])
  p <- p + geom_tile(
    data = sub,
    aes(x = tx, y = y, fill = value),
    width = 0.15, height = 0.85, inherit.aes = FALSE
  ) +
    geom_text(
      data = labs,
      aes(tx, max(yd$y) + 0.8, label = trait),
      size = pv_pt2size(7), angle = 90, hjust = 0, inherit.aes = FALSE, family = house_family()
    ) +
    scale_fill_gradientn(colours = pv_palette("house_div"), name = "Trait value",
                         limits = c(-1, 1) * max(abs(sub$value), na.rm = TRUE)) +
    guides(fill = guide_colourbar(title.position = "left", title.vjust = 0.9,
                                  theme = theme(legend.key.width = unit(30, "mm"),
                                                legend.key.height = unit(2.2, "mm"),
                                                legend.title = element_text(margin = margin(r = 2, unit = "mm")))))
}
strip_x <- if (anno_mode == "bar") xmax + 0.55 + max(sub$value, na.rm = TRUE) * 0.12 + 0.12 else max(sub$tx) + 0.15
p <- p +
  geom_segment(data = cs, aes(x = strip_x, xend = strip_x, y = y0, yend = y1), inherit.aes = FALSE,
               colour = clade_cols[cs$clade], linewidth = pv_house_lw("main")) +
  geom_text(data = cs, aes(x = strip_x, y = ym, label = clade), inherit.aes = FALSE, hjust = -0.3,
            colour = text_col(clade_cols)[cs$clade], size = pv_pt2size(7), family = house_family())
p <- p + expand_limits(x = xmax + 2.75, y = max(yd$y) + 3.2) +
  scale_x_continuous(breaks = function(l) pretty(c(0, xmax), n = 3)[pretty(c(0, xmax), n = 3) <= xmax]) +
  coord_cartesian(clip = "off") +
  theme(plot.margin = margin(1, 1.5, 1, 1, "mm"))

pv_save_house(p, "figure", cells = "2x3", bump = 0)
message("wrote preview.png")
