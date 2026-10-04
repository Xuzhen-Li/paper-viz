# PAV heatmap. ComplexHeatmap (base graphics). Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
cluster_genomes <- TRUE
show_compartment <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
fam <- viz_sans_family()
genomes <- unique(df$genome)
families <- unique(df$family)
mat <- matrix(0L, nrow = length(genomes), ncol = length(families), dimnames = list(genomes, families))
for (i in seq_len(nrow(df))) {
  mat[df$genome[i], df$family[i]] <- df$present[i]
}
comp <- tapply(df$compartment, df$family, function(z) z[[1]])
comp <- comp[families]
comp <- factor(comp, levels = c("core", "shell", "cloud"))

# order families by compartment, then by how often they are present
ord <- order(comp, -colMeans(mat))
mat <- mat[, ord, drop = FALSE]
comp <- comp[ord]

pal <- pv_palette("categorical", 6)
comp_cols <- c(core = pal[1], shell = pal[3], cloud = pal[6])
cell_cols <- c("0" = "#E0E0E0", "1" = pal[1])

if (isTRUE(cluster_genomes)) {
  hc <- stats::hclust(stats::dist(mat, method = "binary"))
  mat <- mat[hc$order, , drop = FALSE]
}

long <- data.frame(
  genome = rownames(mat)[row(mat)],
  family = colnames(mat)[col(mat)],
  present = factor(as.vector(mat), levels = c("0", "1")),
  stringsAsFactors = FALSE
)
long$genome <- factor(long$genome, levels = rev(rownames(mat)))
long$family <- factor(long$family, levels = colnames(mat))

p_heat <- ggplot2::ggplot(long, ggplot2::aes(family, genome, fill = present)) +
  ggplot2::geom_tile(colour = "white", linewidth = 0.05) +
  ggplot2::scale_fill_manual(
    values = cell_cols, name = "Present",
    labels = c("0" = "absent", "1" = "present")
  ) +
  ggplot2::scale_x_discrete(expand = c(0, 0)) +
  ggplot2::labs(x = "Gene family", y = "Genome") +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank(),
    legend.position = "bottom",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

if (isTRUE(show_compartment)) {
  ann <- data.frame(
    family = factor(names(comp), levels = colnames(mat)),
    compartment = comp,
    stringsAsFactors = FALSE
  )
  spacer <- rownames(mat)[which.max(nchar(rownames(mat)))]
  p_ann <- ggplot2::ggplot(ann, ggplot2::aes(family, y = 1, fill = compartment)) +
    ggplot2::geom_tile(height = 1) +
    ggplot2::scale_fill_manual(values = comp_cols, name = "Compartment") +
    ggplot2::scale_x_discrete(expand = c(0, 0), drop = FALSE) +
    ggplot2::scale_y_continuous(breaks = 1, labels = spacer, expand = c(0, 0)) +
    ggplot2::labs(x = NULL, y = "Genome") +
    theme_viz() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(colour = "white"),
      axis.ticks = ggplot2::element_blank(),
      axis.title.x = ggplot2::element_blank(),
      axis.title.y = ggplot2::element_text(colour = "white"),
      panel.border = ggplot2::element_blank(),
      legend.position = "bottom",
      plot.margin = ggplot2::margin(1, 0, 0, 0, "mm"),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
  grab_legend <- function(plot) {
    g <- ggplot2::ggplotGrob(plot)
    k <- which(vapply(g$grobs, function(x) identical(x$name, "guide-box"), logical(1)))
    if (!length(k)) return(ggplot2::zeroGrob())
    g$grobs[[k[[1]]]]
  }
  p_ann <- p_ann + ggplot2::theme(legend.position = "none")
  p_heat <- p_heat + ggplot2::theme(legend.position = "none")
  body <- cowplot::plot_grid(
    p_ann, p_heat, ncol = 1, align = "v", axis = "lr",
    rel_heights = c(0.045, 1)
  )
  legs <- cowplot::plot_grid(
    grab_legend(p_ann + ggplot2::theme(legend.position = "bottom")),
    grab_legend(p_heat + ggplot2::theme(legend.position = "bottom")),
    nrow = 1
  ) +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))
  p <- cowplot::plot_grid(body, legs, ncol = 1, rel_heights = c(1, 0.14)) +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))
} else {
  p <- p_heat
}

pv_save(p, "figure", width_mm = 183, height_mm = 110)
message("wrote preview.png")
