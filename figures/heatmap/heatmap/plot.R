# Clustered heatmap (house style): z-scores on the house blue-red scale centred at 0, white cell
# borders, sample groups as a coloured bar with the group names written above it (no legend),
# colour bar just right of the panel. Views: expression, geneset or module-trait (r in each cell).
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

view <- "expression"
show_annotation <- TRUE
split_columns <- TRUE

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration; not biological results"
cap_theme <- theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                               margin = margin(t = 0.8, unit = "mm")),
                   plot.caption.position = "plot")
cbar <- function(h_mm) guide_colourbar(theme = theme(legend.key.width = unit(2, "mm"),
                                                     legend.key.height = unit(h_mm, "mm")))

if (view == "module-trait") {
  mt <- utils::read.csv("data_module.csv", stringsAsFactors = FALSE)
  mt$module <- factor(mt$module, levels = rev(unique(mt$module)))
  mt$trait <- factor(mt$trait, levels = unique(mt$trait))
  mt$txt <- ifelse(abs(mt$r) > 0.6, "white", "black")   # dark cells get white text
  p <- ggplot(mt, aes(trait, module, fill = r)) +
    geom_tile(colour = "white", linewidth = pv_house_lw(0.3)) +
    geom_text(aes(label = sprintf("%.2f", r), colour = txt)) +
    scale_colour_identity() +
    scale_fill_gradientn(colours = pv_palette("house_div"), limits = c(-1, 1), name = "r", guide = cbar(30)) +
    scale_x_discrete(expand = c(0, 0)) +
    scale_y_discrete(expand = c(0, 0)) +
    labs(x = NULL, y = NULL, caption = footnote) +
    theme_house() + cap_theme +
    theme(panel.border = element_blank(), axis.ticks = element_blank(), legend.position = "right",
          legend.box.spacing = unit(1, "mm"), legend.title = element_text(face = "italic"),
          axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))
  pv_save_house(p, "figure", cells = "2x2")
  message("wrote preview.png")
  quit(save = "no", status = 0)
}

src <- if (view == "geneset") "data_geneset.csv" else "data.csv"
df <- utils::read.csv(src, stringsAsFactors = FALSE)
feats <- unique(df$feature)
samps <- unique(df$sample)
mat <- matrix(NA_real_, length(feats), length(samps), dimnames = list(feats, samps))
mat[cbind(match(df$feature, feats), match(df$sample, samps))] <- df$value
mat <- t(scale(t(mat)))
grp <- df$group[match(samps, df$sample)]
names(grp) <- samps
grp <- factor(grp, levels = c("Tumor", "Adjacent", "Normal", "Treated"))

if (isTRUE(split_columns)) {
  col_ord <- unlist(lapply(levels(grp), function(g) {
    cols <- samps[grp == g]
    if (length(cols) > 2) cols[stats::hclust(stats::dist(t(mat[, cols, drop = FALSE])))$order] else cols
  }), use.names = FALSE)
} else {
  col_ord <- samps[stats::hclust(stats::dist(t(mat)))$order]
}
row_ord <- feats[stats::hclust(stats::dist(mat))$order]
mat <- mat[row_ord, col_ord, drop = FALSE]

levels_x <- character()
for (g in levels(grp)) {
  cols <- col_ord[grp[col_ord] == g]
  if (!length(cols)) next
  if (length(levels_x) && isTRUE(split_columns)) levels_x <- c(levels_x, paste0(".gap.", g))
  levels_x <- c(levels_x, cols)
}

long <- data.frame(
  feature = factor(rownames(mat)[row(mat)], levels = rev(rownames(mat))),
  sample = factor(colnames(mat)[col(mat)], levels = levels_x),
  value = as.vector(mat)
)
ann <- data.frame(
  sample = factor(col_ord, levels = levels_x),
  group = grp[col_ord]
)
# blue, red, green, purple: all >= 3:1 on white, so the group names keep the bar colour
ann_pal <- stats::setNames(c(hp[["blue"]], hp[["red"]], hp[["green"]], hp[["purple"]]), levels(grp))
lim <- ceiling(max(abs(long$value), na.rm = TRUE))
ann_lab <- do.call(rbind, lapply(levels(grp), function(g) {
  x <- match(col_ord[grp[col_ord] == g], levels_x)
  if (!length(x)) return(NULL)
  data.frame(group = factor(g, levels = levels(grp)), x = mean(range(x)))
}))
stat_lab <- sprintf("%d features, %d samples, rows clustered", nrow(mat), ncol(mat))

heat <- ggplot(long, aes(sample, feature, fill = value)) +
  geom_tile(colour = "white", linewidth = pv_house_lw(0.3)) +
  scale_fill_gradientn(colours = pv_palette("house_div"), limits = c(-lim, lim), name = "z",
                       guide = cbar(40)) +
  scale_x_discrete(drop = FALSE, expand = c(0, 0), labels = function(x) ifelse(grepl("^\\.gap", x), "", x)) +
  scale_y_discrete(expand = c(0, 0)) +
  labs(x = NULL, y = NULL) +
  theme_house() +
  theme(panel.border = element_blank(), axis.ticks = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
        legend.position = "right", legend.box.spacing = unit(1, "mm"),
        legend.title = element_text(face = "italic", margin = margin(b = 1, unit = "mm")))

if (isTRUE(show_annotation)) {
  bar <- ggplot(ann, aes(sample, 1, fill = group)) +
    geom_tile(colour = "white", linewidth = pv_house_lw(0.3)) +
    geom_text(data = ann_lab, aes(x = x, y = 1.75, label = group, colour = group), vjust = 0,
              inherit.aes = FALSE) +
    scale_fill_manual(values = ann_pal, guide = "none") +
    scale_colour_manual(values = ann_pal, guide = "none") +
    scale_x_discrete(drop = FALSE, expand = c(0, 0)) +
    coord_cartesian(ylim = c(0.5, 1.5), clip = "off") +
    labs(x = NULL, y = NULL, title = stat_lab) +
    theme_house() +
    theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank(),
          panel.border = element_blank(),
          plot.title = element_text(size = 7, margin = margin(b = 4.2, unit = "mm")),
          plot.margin = margin(1.2, 0.8, 0.6, 0.4, "mm"))
  p <- bar / heat + plot_layout(heights = c(0.035, 1), guides = "collect") +
    plot_annotation(caption = footnote,
                    theme = cap_theme + theme(text = element_text(family = house_family()))) &
    theme(legend.position = "right")
} else {
  p <- heat + labs(caption = footnote) + cap_theme
}

pv_save_house(p, "figure", cells = c(3, 4))
message("wrote preview.png")
