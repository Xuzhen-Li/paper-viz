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

comp_cols <- c(core = "#08306B", shell = "#6BAED6", cloud = "#FDB863")
cell_cols <- c("0" = "#F2F2F2", "1" = "#0072B2")

save_base <- function(draw, width_mm, height_mm) {
  w <- width_mm / 25.4
  h <- height_mm / 25.4
  grDevices::cairo_pdf("figure.pdf", width = w, height = h, family = fam, pointsize = 6.5)
  draw()
  grDevices::dev.off()
  grDevices::png("figure.png", width = w, height = h, units = "in", res = 600, type = "cairo", family = fam, pointsize = 6.5)
  draw()
  grDevices::dev.off()
  grDevices::png("preview.png", width = w, height = h, units = "in", res = 1200 / w, type = "cairo", family = fam, pointsize = 6.5)
  draw()
  grDevices::dev.off()
}

draw <- function() {
  top <- NULL
  if (isTRUE(show_compartment)) {
    top <- ComplexHeatmap::HeatmapAnnotation(
      compartment = comp,
      col = list(compartment = comp_cols),
      annotation_name_gp = grid::gpar(fontsize = 6.5, fontfamily = fam),
      annotation_legend_param = list(
        title_gp = grid::gpar(fontsize = 6.5, fontfamily = fam),
        labels_gp = grid::gpar(fontsize = 6, fontfamily = fam)
      ),
      simple_anno_size = grid::unit(3.2, "mm"),
      show_legend = TRUE
    )
  }
  ht <- ComplexHeatmap::Heatmap(
    mat,
    name = "PAV",
    col = cell_cols,
    cluster_rows = isTRUE(cluster_genomes),
    cluster_columns = FALSE,
    show_column_names = FALSE,
    row_names_gp = grid::gpar(fontsize = 6, fontfamily = fam),
    column_title = "Gene family",
    column_title_gp = grid::gpar(fontsize = 7, fontfamily = fam),
    row_title = "Genome",
    row_title_gp = grid::gpar(fontsize = 7, fontfamily = fam),
    top_annotation = top,
    heatmap_legend_param = list(
      title = "Present",
      at = c(0, 1),
      labels = c("absent", "present"),
      title_gp = grid::gpar(fontsize = 6.5, fontfamily = fam),
      labels_gp = grid::gpar(fontsize = 6, fontfamily = fam)
    ),
    border = TRUE,
    rect_gp = grid::gpar(col = "white", lwd = 0.2)
  )
  ComplexHeatmap::draw(ht, padding = grid::unit(c(2, 2, 2, 8), "mm"))
}

save_base(draw, width_mm = 183, height_mm = 110)
message("wrote preview.png")
