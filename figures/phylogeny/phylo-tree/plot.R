# Annotated phylogeny (house style): branches coloured by population (house colours), bootstrap values
# on well-supported branches, population names written as clade strips right of the tips (no legend).
# The tree panel has no frame. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
layout <- "rectangular" # rectangular | circular | fan | dendrogram
show_bootstrap <- TRUE
bootstrap_min <- 70
show_tip_bar <- FALSE
show_tip_label <- TRUE

footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# label text: the group colour if it reaches 3:1 contrast on white (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  # below 3:1, use the darker step of the same hue where one exists in the house palettes
  # (orange -> chrom12 orange #E17927, 3.01:1); otherwise #1A1A1A
  darker <- c("#E17D52" = "#E17927", "#F77E12" = "#E17927")
  up <- toupper(hex)
  stats::setNames(ifelse(ratio >= 3, hex, ifelse(up %in% names(darker), darker[up], "#1A1A1A")),
                  names(hex))
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
grp_cols <- c("Wild N" = hp[["blue"]], "Wild S" = hp[["sky"]], "Landrace E" = hp[["green"]],
              "Landrace W" = hp[["gold"]], "Cultivar A" = hp[["red"]], "Cultivar B" = hp[["purple"]])
# populations ordered by geography (mean sampling latitude, north -> south) on the geo palette
pop_geo <- stats::setNames(pv_palette("geo"),
                           c("Wild N", "Cultivar A", "Landrace W", "Landrace E", "Cultivar B", "Wild S"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)

edges_to_phylo <- function(df) {
  tip_names <- sort(setdiff(df$tip, df$parent))
  root <- setdiff(df$parent, df$tip)
  internals <- c(root, sort(setdiff(unique(df$parent), root)))
  ids <- setNames(seq_along(c(tip_names, internals)), c(tip_names, internals))
  edge <- cbind(unname(ids[df$parent]), unname(ids[df$tip]))
  bs_map <- setNames(df$bootstrap, df$tip)
  node_label <- bs_map[internals]
  node_label[is.na(node_label)] <- ""
  tr <- list(
    edge = edge,
    edge.length = df$length,
    tip.label = tip_names,
    node.label = as.character(node_label),
    Nnode = length(internals)
  )
  class(tr) <- "phylo"
  gmap <- setNames(df$group[match(tip_names, df$tip)], tip_names)
  gmap <- gmap[!is.na(gmap)]
  groups <- split(names(gmap), gmap)
  tr <- ggtree::groupOTU(tr, groups, group_name = "group")
  tr
}

tr <- edges_to_phylo(df)
lay <- if (layout == "dendrogram") "rectangular" else layout
brlen <- if (layout == "dendrogram") "none" else "branch.length"
grp_cols <- c(North = hp[["blue"]], South = hp[["red"]], East = hp[["green"]], West = hp[["purple"]])

p <- ggtree::ggtree(tr, aes(colour = group), layout = lay, branch.length = brlen,
                    linewidth = pv_house_lw("main")) +
  scale_colour_manual(values = grp_cols, guide = "none", na.value = grey[["dark"]]) +
  labs(x = if (layout == "dendrogram") NULL else "Divergence", caption = footnote) +
  theme_house() +
  theme(
    panel.border = element_blank(),
    axis.line.x = if (layout %in% c("rectangular")) element_line(linewidth = pv_house_lw("frame")) else element_blank(),
    axis.text.x = if (layout %in% c("rectangular")) element_text() else element_blank(),
    axis.ticks.x = if (layout %in% c("rectangular")) element_line() else element_blank(),
    axis.line.y = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    plot.margin = margin(1, 1.5, 1, 1, "mm")
  ) +
  caption_theme

if (isTRUE(show_tip_label) && layout %in% c("rectangular", "dendrogram")) {
  p <- p + ggtree::geom_tiplab(size = pv_pt2size(7), colour = "#1A1A1A", offset = 0.02, family = house_family())
}
if (isTRUE(show_tip_label) && layout %in% c("circular", "fan")) {
  p <- p + ggtree::geom_tiplab2(size = pv_pt2size(7), colour = "#1A1A1A", offset = 0.02, family = house_family())
}
if (isTRUE(show_bootstrap)) {
  nd <- p$data[!p$data$isTip & nzchar(p$data$label), , drop = FALSE]
  nd$bs <- suppressWarnings(as.numeric(nd$label))
  nd <- nd[!is.na(nd$bs) & nd$bs >= bootstrap_min & !is.na(nd$branch.length), , drop = FALSE]
  # A value is written only on a branch long enough to hold it (about 4 mm of the ~80 mm wide
  # x range); shorter branches would push the number into the parent node or the tip labels.
  short <- 0.05 * max(p$data$x) * 1.13
  nd <- nd[nd$branch.length >= short, , drop = FALSE]
  nd$xlab <- nd$x - 0.55 * nd$branch.length
  p <- p + geom_text(
    data = nd,
    aes(x = xlab, y = y, label = label),
    nudge_y = 0.55, vjust = 0, hjust = 0.5,
    size = pv_pt2size(7), colour = grey[["mid"]], family = house_family(),
    inherit.aes = FALSE
  )
}

# population names as clade strips beyond the tip labels (rectangular trees)
if (layout %in% c("rectangular", "dendrogram")) {
  td <- p$data[p$data$isTip & !is.na(p$data$group) & p$data$group %in% names(grp_cols), ]
  xmax <- max(p$data$x)
  strip_x <- xmax * 1.16
  st <- do.call(rbind, lapply(split(td, as.character(td$group)), function(d)
    data.frame(group = d$group[1], y0 = min(d$y) - 0.3, y1 = max(d$y) + 0.3, ym = mean(range(d$y)))))
  p <- p +
    geom_segment(data = st, aes(x = strip_x, xend = strip_x, y = y0, yend = y1), inherit.aes = FALSE,
                 colour = grp_cols[as.character(st$group)], linewidth = pv_house_lw("main")) +
    geom_text(data = st, aes(x = strip_x, y = ym, label = group), inherit.aes = FALSE, hjust = -0.15,
              colour = text_col(grp_cols)[as.character(st$group)], size = pv_pt2size(7),
              family = house_family()) +
    scale_x_continuous(expand = expansion(mult = c(0.01, 0.12))) +
    coord_cartesian(clip = "off")
}

if (isTRUE(show_tip_bar) && layout %in% c("rectangular", "dendrogram")) {
  tip_len <- df[!is.na(df$group), c("tip", "length", "group")]
  yd <- p$data[p$data$isTip, c("label", "y")]
  tip_len <- merge(tip_len, yd, by.x = "tip", by.y = "label")
  p2 <- ggplot(tip_len, aes(length, y, fill = group)) +
    geom_col(width = 0.7, orientation = "y") +
    scale_fill_manual(values = grp_cols, guide = "none") +
    scale_y_continuous(limits = range(p$data$y) + c(-0.5, 0.5), expand = c(0, 0)) +
    labs(x = "Tip length", y = NULL) +
    theme_house() +
    theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())
  p <- patchwork::wrap_plots(p, p2, nrow = 1, widths = c(1.4, 0.45))
}

pv_save_house(p, "figure", cells = if (layout %in% c("circular", "fan")) "2x2" else "2x3", bump = 0)
message("wrote preview.png")
