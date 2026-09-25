# Synthetic clustered heatmap via pheatmap. Run from recipes/r.
set.seed(5)
source("../../styles/r/theme_viz.R")

genes <- paste0("Gene", sprintf("%02d", 1:20))
samples <- paste0("S", 1:8)
mat <- matrix(rnorm(20 * 8), nrow = 20, dimnames = list(genes, samples))
mat[1:6, 1:4] <- mat[1:6, 1:4] + 2
ann <- data.frame(Group = rep(c("A", "B"), each = 4), row.names = samples)
cols <- palette_viz(2)

grDevices::png("../../gallery/heatmap.png", width = 89 / 25.4, height = 90 / 25.4, units = "in", res = 300)
pheatmap::pheatmap(
  mat,
  annotation_col = ann,
  annotation_colors = list(Group = c(A = cols[1], B = cols[2])),
  color = grDevices::colorRampPalette(c("#2A629A", "white", "#C75050"))(50),
  fontsize = 7,
  border_color = NA
)
grDevices::dev.off()
message("wrote ../../gallery/heatmap.png")
