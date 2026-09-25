# Clustered heatmap. Annotation, column split, geneset, or module-trait.
# Run from this directory.
source("../../../styles/r/theme_viz.R")
library(patchwork)

view <- "expression"
show_annotation <- TRUE
split_columns <- TRUE

if (view == "module-trait") {
  mt <- utils::read.csv("data_module.csv", stringsAsFactors = FALSE)
  mt$module <- factor(mt$module, levels = unique(mt$module))
  mt$trait <- factor(mt$trait, levels = unique(mt$trait))
  p <- ggplot2::ggplot(mt, ggplot2::aes(trait, module, fill = r)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.3) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", r)), size = 2.4) +
    ggplot2::scale_fill_gradientn(
      colours = pv_palette("diverging", 9), limits = c(-1, 1), name = "r"
    ) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_viz()
  pv_save(p, "figure", width_mm = 110, height_mm = 70)
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
ann_pal <- pv_palette("categorical", 4)
names(ann_pal) <- levels(grp)
lim <- max(abs(long$value), na.rm = TRUE)

heat <- ggplot2::ggplot(long, ggplot2::aes(sample, feature, fill = value)) +
  ggplot2::geom_tile() +
  ggplot2::scale_fill_gradientn(
    colours = pv_palette("diverging", 11),
    limits = c(-lim, lim), name = "z"
  ) +
  ggplot2::scale_x_discrete(
    drop = FALSE,
    labels = function(x) ifelse(grepl("^\\.gap", x), "", x)
  ) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = 4.6),
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 5),
    legend.key.height = ggplot2::unit(8, "mm")
  )

if (isTRUE(show_annotation)) {
  bar <- ggplot2::ggplot(ann, ggplot2::aes(sample, 1, fill = group)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_manual(values = ann_pal, name = NULL) +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_viz() +
    ggplot2::theme(
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.line = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(0, 5, 0, 5)
    )
  p <- bar / heat + patchwork::plot_layout(heights = c(0.06, 1), guides = "collect")
} else {
  p <- heat
}

pv_save(p, "figure", width_mm = 183, height_mm = 150)
message("wrote preview.png")
