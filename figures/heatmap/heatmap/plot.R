# Clustered expression heatmap. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
genes <- unique(df$gene)
samples <- unique(df$sample)
mat <- matrix(NA_real_, length(genes), length(samples), dimnames = list(genes, samples))
mat[cbind(match(df$gene, genes), match(df$sample, samples))] <- df$value
ann <- df[!duplicated(df$sample), c("sample", "group")]
rownames(ann) <- ann$sample

rg <- stats::hclust(stats::dist(mat))$order
cg <- stats::hclust(stats::dist(t(mat)))$order
mat <- mat[rg, cg, drop = FALSE]
long <- data.frame(
  gene = factor(rownames(mat)[row(mat)], levels = rev(rownames(mat))),
  sample = factor(colnames(mat)[col(mat)], levels = colnames(mat)),
  value = as.vector(mat)
)
fills <- pv_palette("diverging", 50)

p <- ggplot2::ggplot(long, ggplot2::aes(sample, gene, fill = value)) +
  ggplot2::geom_tile() +
  ggplot2::scale_fill_gradientn(colours = fills, name = "z") +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(axis.text.y = ggplot2::element_text(size = 5), axis.text.x = ggplot2::element_text(size = 6))

pv_save(p, "figure", width_mm = 89, height_mm = 100)
message("wrote preview.png")
