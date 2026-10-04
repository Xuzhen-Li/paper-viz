# Sample clustering tree beside a stacked taxon bar, ordered by the tree.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
relative <- TRUE
top_n <- 12
group_order <- c("Gut", "Oral", "Skin", "Soil")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_order)

wide <- reshape(df[, c("sample", "taxon", "abundance")], idvar = "sample", timevar = "taxon", direction = "wide")
rownames(wide) <- wide$sample
wide$sample <- NULL
names(wide) <- sub("^abundance\\.", "", names(wide))
mat <- as.matrix(wide)
if (isTRUE(relative)) {
  mat <- mat / rowSums(mat)
}
# Bray-Curtis clustering
bc <- vegan::vegdist(mat, method = "bray")
hc <- stats::hclust(bc, method = "average")
tr <- ape::as.phylo(hc)

grp <- unique(df[, c("sample", "group")])
grp <- grp[match(tr$tip.label, grp$sample), ]
groups <- split(grp$sample, grp$group)
tr <- ggtree::groupOTU(tr, groups, group_name = "group")
gcols <- setNames(pv_palette("categorical", length(group_order)), group_order)

p_tree <- ggtree::ggtree(tr, ggplot2::aes(colour = group), linewidth = 0.35) +
  ggplot2::scale_colour_manual(values = gcols, name = "Group", na.value = "grey30") +
  theme_viz() +
  ggplot2::theme(
    axis.line = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    legend.position = "bottom",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

tip_order <- p_tree$data$label[p_tree$data$isTip][order(p_tree$data$y[p_tree$data$isTip])]
# ggtree y order
yd <- p_tree$data[p_tree$data$isTip, c("label", "y")]
yd <- yd[order(yd$y), , drop = FALSE]

mean_ab <- tapply(as.vector(mat), rep(colnames(mat), each = nrow(mat)), mean)
rank_taxa <- names(sort(mean_ab, decreasing = TRUE))
# More than six taxa would pull in #fbee61 as a wide stack. Fold the rest into Other.
n_keep <- min(6L, as.integer(top_n), length(rank_taxa))
keep <- rank_taxa[seq_len(n_keep)]
long <- as.data.frame(as.table(mat), stringsAsFactors = FALSE)
names(long) <- c("sample", "taxon", "abundance")
long$taxon <- ifelse(long$taxon %in% keep, as.character(long$taxon), "Other")
long <- stats::aggregate(abundance ~ sample + taxon, long, sum)
long$sample <- factor(long$sample, levels = yd$label)
tax_levels <- c(keep, if ("Other" %in% long$taxon) "Other")
long$taxon <- factor(long$taxon, levels = tax_levels)
named <- setdiff(as.character(tax_levels), "Other")
tcols <- setNames(pv_palette("categorical", length(named)), named)
if ("Other" %in% tax_levels) tcols["Other"] <- "#E0E0E0"

long <- merge(long, yd, by.x = "sample", by.y = "label")
p_bar <- ggplot2::ggplot(long, ggplot2::aes(abundance, y, fill = taxon)) +
  ggplot2::geom_col(
    width = 0.8, orientation = "y", colour = NA,
    position = ggplot2::position_stack(reverse = TRUE)
  ) +
  ggplot2::scale_fill_manual(values = tcols, name = "Taxon") +
  ggplot2::scale_y_continuous(limits = range(yd$y) + c(-0.5, 0.5), expand = c(0, 0)) +
  ggplot2::labs(x = if (isTRUE(relative)) "Relative abundance" else "Abundance", y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    axis.line.y = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.position = "bottom",
    legend.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.box.background = ggplot2::element_rect(fill = "white", colour = NA)
  ) +
  ggplot2::guides(fill = ggplot2::guide_legend(ncol = 3, byrow = TRUE))

p_tree <- p_tree + ggplot2::theme(
  legend.background = ggplot2::element_rect(fill = "white", colour = NA),
  legend.box.background = ggplot2::element_rect(fill = "white", colour = NA)
)

grab_legend <- function(plot) {
  g <- ggplot2::ggplotGrob(plot)
  k <- which(vapply(g$grobs, function(x) identical(x$name, "guide-box"), logical(1)))
  if (!length(k)) return(ggplot2::zeroGrob())
  g$grobs[[k[[1]]]]
}
leg_grp <- grab_legend(p_tree)
leg_tax <- grab_legend(p_bar)
p_tree <- p_tree + ggplot2::theme(legend.position = "none")
p_bar <- p_bar + ggplot2::theme(legend.position = "none")
body <- cowplot::plot_grid(p_tree, p_bar, nrow = 1, align = "h", axis = "tb", rel_widths = c(0.62, 1.38))
legs <- cowplot::plot_grid(leg_grp, leg_tax, ncol = 1, rel_heights = c(0.38, 0.62)) +
  ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))
p <- cowplot::plot_grid(body, legs, ncol = 1, rel_heights = c(1, 0.28)) +
  ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))
pv_save(p, "figure", width_mm = 183, height_mm = 120)
message("wrote preview.png")
