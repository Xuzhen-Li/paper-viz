# Gene models with optional domains, isoform track, and mutation marks.
source("../../../styles/r/theme_viz.R")

show_domains <- TRUE
show_isoforms <- TRUE
show_mutations <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
if (!isTRUE(show_isoforms)) {
  df <- df[df$gene != "Gene2.2", , drop = FALSE]
}
if (!isTRUE(show_domains)) {
  df <- df[df$feature != "domain", , drop = FALSE]
}
if (!isTRUE(show_mutations)) {
  df <- df[df$feature != "mutation", , drop = FALSE]
}

preferred <- c("Gene1", "Gene2.1", "Gene2.2", "Gene3", "Gene4", "Gene5", "Gene6")
gene_order <- c(preferred[preferred %in% unique(df$gene)], setdiff(unique(df$gene), preferred))
df$gene <- factor(df$gene, levels = rev(gene_order))
df$y <- as.numeric(df$gene)

body <- df[df$feature %in% c("exon", "utr"), , drop = FALSE]
span <- do.call(rbind, lapply(split(body, body$gene), function(d) {
  data.frame(
    gene = d$gene[1], y = d$y[1], strand = d$strand[1],
    start = min(d$start), end = max(d$end)
  )
}))
exons <- df[df$feature == "exon", , drop = FALSE]
utrs <- df[df$feature == "utr", , drop = FALSE]
doms <- df[df$feature == "domain", , drop = FALSE]
muts <- df[df$feature == "mutation", , drop = FALSE]
exons$part <- "CDS"
utrs$part <- "UTR"
if (nrow(doms)) doms$part <- "Domain"
part_cols <- c(CDS = "#0072B2", UTR = "#56B4E9", Domain = "#E69F00")

span$x_tip <- ifelse(span$strand == "+", span$end, span$start)
span$x_end <- ifelse(span$strand == "+", span$end + 160, span$start - 160)

p <- ggplot2::ggplot() +
  ggplot2::geom_segment(
    data = span,
    ggplot2::aes(x = start, xend = end, y = y, yend = y),
    linewidth = 0.3, colour = "#4D4D4D"
  ) +
  ggplot2::geom_segment(
    data = span,
    ggplot2::aes(x = x_tip, xend = x_end, y = y, yend = y),
    linewidth = 0.3, colour = "#4D4D4D",
    arrow = ggplot2::arrow(length = ggplot2::unit(1.3, "mm"), type = "closed")
  ) +
  ggplot2::geom_rect(
    data = exons,
    ggplot2::aes(xmin = start, xmax = end, ymin = y - 0.16, ymax = y + 0.16, fill = part),
    colour = NA
  ) +
  ggplot2::geom_rect(
    data = utrs,
    ggplot2::aes(xmin = start, xmax = end, ymin = y - 0.09, ymax = y + 0.09, fill = part),
    colour = NA
  )

if (nrow(doms)) {
  p <- p + ggplot2::geom_rect(
    data = doms,
    ggplot2::aes(xmin = start, xmax = end, ymin = y - 0.08, ymax = y + 0.08, fill = part),
    colour = NA
  )
}
if (nrow(muts)) {
  p <- p + ggplot2::geom_point(
    data = muts,
    ggplot2::aes(x = start, y = y + 0.34, shape = "Mutation"),
    size = 1.1, colour = "#D55E00"
  )
}

y_labs <- sprintf("%s (%s)", span$gene, span$strand)
names(y_labs) <- as.character(span$y)

p <- p +
  ggplot2::scale_fill_manual(values = part_cols, name = NULL) +
  ggplot2::scale_shape_manual(values = c(Mutation = 17), name = NULL) +
  ggplot2::scale_y_continuous(
    breaks = span$y,
    labels = y_labs,
    expand = ggplot2::expansion(add = 0.45)
  ) +
  ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.03, 0.06))) +
  ggplot2::labs(x = "Position within locus (bp)", y = NULL) +
  theme_viz() +
  ggplot2::theme(
    legend.position = "bottom",
    legend.key.size = ggplot2::unit(3, "mm")
  )

pv_save(p, "figure", width_mm = 160, height_mm = 88)
message("wrote preview.png")
