# Sample clustering tree beside a stacked taxon bar, ordered by the tree (house style).
# Tree branches carry the sample group; bars use the first six house colours plus grey Other.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

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
hp <- pv_palette("house")
grey <- pv_palette("house_grey")
footnote <- "Bray-Curtis distance, average linkage.\nSimulated data for illustration; not biological results"
# Groups take the house colours not used by the taxa, so no colour means two things.
gcols <- setNames(c(hp[c("gold", "magenta", "brown")], grey[["dark"]])[seq_along(group_order)], group_order)

p_tree <- ggtree::ggtree(tr, ggplot2::aes(colour = group), linewidth = pv_house_lw("main")) +
  ggtree::geom_tiplab(ggplot2::aes(label = label), size = pv_pt2size(7), colour = "#1A1A1A",
                      family = house_family(), offset = 0.01, align = FALSE) +
  ggplot2::scale_colour_manual(values = gcols, name = "Group", na.value = grey[["dark"]],
                               breaks = group_order) +
  ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.02, 0.18))) +
  theme_house() +
  ggplot2::theme(
    panel.border = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_blank(), axis.text.y = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank(),
    axis.line.x = ggplot2::element_blank(), axis.line.y = ggplot2::element_blank(),
    axis.title.x = ggplot2::element_blank(), axis.title.y = ggplot2::element_blank()
  ) +
  ggplot2::guides(colour = ggplot2::guide_legend(nrow = 1, override.aes = list(linewidth = 1.2)))

yd <- p_tree$data[p_tree$data$isTip, c("label", "y")]
yd <- yd[order(yd$y), , drop = FALSE]

mean_ab <- tapply(as.vector(mat), rep(colnames(mat), each = nrow(mat)), mean)
rank_taxa <- names(sort(mean_ab, decreasing = TRUE))
# At most six named taxa (the first six house colours); the rest fold into Other.
n_keep <- min(6L, as.integer(top_n), length(rank_taxa))
keep <- rank_taxa[seq_len(n_keep)]
long <- as.data.frame(as.table(mat), stringsAsFactors = FALSE)
names(long) <- c("sample", "taxon", "abundance")
long$taxon <- ifelse(long$taxon %in% keep, as.character(long$taxon), "Other")
long <- stats::aggregate(abundance ~ sample + taxon, long, sum)
tax_levels <- c(keep, if ("Other" %in% long$taxon) "Other")
long$taxon <- factor(long$taxon, levels = tax_levels)
named <- setdiff(as.character(tax_levels), "Other")
tcols <- setNames(unname(hp[seq_along(named)]), named)
if ("Other" %in% tax_levels) tcols["Other"] <- grey[["light"]]

long <- merge(long, yd, by.x = "sample", by.y = "label")
p_bar <- ggplot2::ggplot(long, ggplot2::aes(abundance, y, fill = taxon)) +
  ggplot2::geom_col(
    width = 0.8, orientation = "y", colour = NA,
    position = ggplot2::position_stack(reverse = TRUE)
  ) +
  ggplot2::scale_fill_manual(values = tcols, name = "Taxon") +
  ggplot2::scale_x_continuous(expand = c(0, 0), breaks = scales::breaks_pretty(n = 3)) +
  ggplot2::scale_y_continuous(limits = range(yd$y) + c(-0.5, 0.5), expand = c(0, 0)) +
  ggplot2::labs(x = if (isTRUE(relative)) "Relative abundance" else "Abundance", y = NULL) +
  theme_house() +
  ggplot2::theme(
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    axis.line.y = ggplot2::element_blank()
  ) +
  ggplot2::guides(fill = ggplot2::guide_legend(ncol = 3, byrow = TRUE))

p <- (p_tree | p_bar) +
  patchwork::plot_layout(widths = c(0.8, 1.2), guides = "collect") +
  patchwork::plot_annotation(
    caption = footnote,
    theme = ggplot2::theme(
      text = ggplot2::element_text(family = house_family()),
      plot.caption = ggplot2::element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                           margin = ggplot2::margin(t = 0.8, unit = "mm")),
      plot.caption.position = "plot"
    )
  ) &
  ggplot2::theme(legend.position = "bottom", legend.box = "vertical",
                 legend.box.just = "left", legend.justification = "left",
                 legend.key.size = ggplot2::unit(3, "mm"), legend.margin = ggplot2::margin(0, 0, 0, 0))
pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
