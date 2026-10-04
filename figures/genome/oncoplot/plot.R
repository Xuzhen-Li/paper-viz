# Oncoplot with a Ti/Tv bar and a cohort lane.
# Drawn with ggplot. ComplexHeatmap does not finish loading in this library.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_titv <- TRUE
show_sample_lane <- TRUE
cohort_order <- c("A", "B")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
genes <- unique(df$gene)
samples <- unique(df$sample)
classes <- c("Missense_Ti", "Missense_Tv", "Nonsense", "Frameshift", "Splice")
pal <- pv_palette("categorical", length(classes))
col <- c(
  Missense_Ti = pal[1],
  Missense_Tv = pal[2],
  Nonsense = pal[4],
  Frameshift = pal[3],
  Splice = pal[5]
)

mat <- matrix("", nrow = length(genes), ncol = length(samples), dimnames = list(genes, samples))
for (i in seq_len(nrow(df))) mat[df$gene[i], df$sample[i]] <- df$variant_class[i]
cohort <- tapply(df$cohort, df$sample, function(z) z[[1]])
cohort <- cohort[samples]

ti <- colSums(mat == "Missense_Ti")
tv <- colSums(mat == "Missense_Tv")

gene_n <- rowSums(mat != "")
gene_ord <- names(sort(gene_n, decreasing = TRUE))
sample_n <- colSums(mat != "")
sample_ord <- names(sort(sample_n, decreasing = TRUE))
gene_f <- factor(gene_ord, levels = rev(gene_ord))
sample_f <- factor(sample_ord, levels = sample_ord)

bg <- expand.grid(gene = gene_f, sample = sample_f, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
long <- as.data.frame(as.table(mat), stringsAsFactors = FALSE)
names(long) <- c("gene", "sample", "variant_class")
long <- long[long$variant_class != "", , drop = FALSE]
long$gene <- factor(long$gene, levels = levels(gene_f))
long$sample <- factor(long$sample, levels = levels(sample_f))
long$variant_class <- factor(long$variant_class, levels = classes)

show_names <- length(samples) <= 24
p_mat <- ggplot2::ggplot() +
  ggplot2::geom_tile(data = bg, ggplot2::aes(sample, gene), fill = "#F4F4F4", width = 0.92, height = 0.72) +
  ggplot2::geom_tile(
    data = long, ggplot2::aes(sample, gene, fill = variant_class),
    width = 0.86, height = 0.66
  ) +
  ggplot2::scale_fill_manual(values = col, name = NULL, drop = FALSE) +
  ggplot2::labs(x = if (isTRUE(show_names)) "Sample" else NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = if (isTRUE(show_names)) {
      ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5, size = 6)
    } else {
      ggplot2::element_blank()
    },
    axis.ticks.x = if (isTRUE(show_names)) ggplot2::element_line(linewidth = 0.3) else ggplot2::element_blank(),
    axis.title.x = ggplot2::element_text(size = 8),
    legend.position = "bottom",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  ) +
  ggplot2::guides(fill = ggplot2::guide_legend(nrow = 2))

panels <- list()
heights <- numeric()

if (isTRUE(show_titv)) {
  tv_long <- rbind(
    data.frame(sample = sample_f, class = "Ti", n = as.numeric(ti[sample_ord])),
    data.frame(sample = sample_f, class = "Tv", n = as.numeric(tv[sample_ord]))
  )
  tv_long$class <- factor(tv_long$class, levels = c("Ti", "Tv"))
  p_tv <- ggplot2::ggplot(tv_long, ggplot2::aes(sample, n, fill = class)) +
    ggplot2::geom_col(width = 0.86, colour = NA) +
    ggplot2::scale_fill_manual(
      values = c(Ti = unname(col["Missense_Ti"]), Tv = unname(col["Missense_Tv"])),
      name = NULL
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.08))) +
    ggplot2::labs(x = NULL, y = "Count") +
    theme_viz() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      axis.title.x = ggplot2::element_blank(),
      legend.position = "none",
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
  panels <- c(panels, list(p_tv))
  heights <- c(heights, 0.32)
}

if (isTRUE(show_sample_lane)) {
  coh <- data.frame(
    sample = sample_f,
    cohort = factor(cohort[sample_ord], levels = cohort_order),
    stringsAsFactors = FALSE
  )
  cohort_cols <- stats::setNames(pv_palette("categorical", 8)[c(6, 8)], cohort_order)
  p_coh <- ggplot2::ggplot(coh, ggplot2::aes(sample, 1, fill = cohort)) +
    ggplot2::geom_tile(height = 0.7, width = 0.92) +
    ggplot2::scale_fill_manual(values = cohort_cols, name = "Cohort") +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_viz() +
    ggplot2::theme(
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      legend.position = "bottom",
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
  panels <- c(panels, list(p_coh + ggplot2::theme(legend.position = "none")))
  heights <- c(heights, 0.07)
}

panels <- c(panels, list(p_mat + ggplot2::theme(legend.position = "none")))
heights <- c(heights, 1)

grab_legend <- function(plot) {
  g <- ggplot2::ggplotGrob(plot)
  k <- which(vapply(g$grobs, function(x) identical(x$name, "guide-box"), logical(1)))
  if (!length(k)) return(ggplot2::zeroGrob())
  g$grobs[[k[[1]]]]
}
legs <- list(grab_legend(p_mat))
if (isTRUE(show_sample_lane)) legs <- c(legs, list(grab_legend(p_coh)))
leg_row <- cowplot::plot_grid(plotlist = legs, ncol = 1) +
  ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))

body <- cowplot::plot_grid(
  plotlist = panels, ncol = 1, align = "v", axis = "lr", rel_heights = heights
)

pct <- data.frame(
  gene = gene_f,
  label = sprintf("%d%%", round(100 * gene_n[gene_ord] / length(sample_ord))),
  stringsAsFactors = FALSE
)
p_pct <- ggplot2::ggplot(pct, ggplot2::aes(1, gene, label = label)) +
  ggplot2::geom_text(size = 2.4, colour = "black") +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

pads <- rep(list(
  ggplot2::ggplot() + ggplot2::theme_void() +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))
), length(panels) - 1L)
right <- cowplot::plot_grid(plotlist = c(pads, list(p_pct)), ncol = 1, rel_heights = heights)
top <- cowplot::plot_grid(body, right, nrow = 1, rel_widths = c(1, 0.1), align = "h", axis = "tb")
p <- cowplot::plot_grid(top, leg_row, ncol = 1, rel_heights = c(1, 0.2)) +
  ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))

pv_save(p, "figure", width_mm = 183, height_mm = 120)
message("wrote preview.png")
