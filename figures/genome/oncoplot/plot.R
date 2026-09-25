# Oncoplot with a Ti/Tv bar and a cohort lane. ComplexHeatmap.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_titv <- TRUE
show_sample_lane <- TRUE
cohort_order <- c("A", "B")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
fam <- viz_sans_family()
genes <- unique(df$gene)
samples <- unique(df$sample)
classes <- c("Missense_Ti", "Missense_Tv", "Nonsense", "Frameshift", "Splice")
col <- c(
  Missense_Ti = "#0072B2",
  Missense_Tv = "#E69F00",
  Nonsense = "#D55E00",
  Frameshift = "#009E73",
  Splice = "#CC79A7"
)

mat <- matrix("", nrow = length(genes), ncol = length(samples), dimnames = list(genes, samples))
for (i in seq_len(nrow(df))) mat[df$gene[i], df$sample[i]] <- df$variant_class[i]
cohort <- tapply(df$cohort, df$sample, function(z) z[[1]])
cohort <- cohort[samples]

ti <- colSums(mat == "Missense_Ti")
tv <- colSums(mat == "Missense_Tv")
titv <- cbind(Ti = ti, Tv = tv)

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

alter_fun <- list(
  background = function(x, y, w, h) {
    grid::grid.rect(x, y, w * 0.9, h * 0.9, gp = grid::gpar(fill = "#F4F4F4", col = NA))
  }
)
for (cl in classes) {
  alter_fun[[cl]] <- local({
    fill <- col[[cl]]
    function(x, y, w, h) {
      grid::grid.rect(x, y, w * 0.85, h * 0.75, gp = grid::gpar(fill = fill, col = NA))
    }
  })
}

draw <- function() {
  top_list <- list()
  if (isTRUE(show_titv)) {
    top_list$TiTv <- ComplexHeatmap::anno_barplot(
      titv,
      gp = grid::gpar(fill = c("#0072B2", "#E69F00"), col = NA),
      height = grid::unit(14, "mm"),
      border = FALSE
    )
  }
  if (isTRUE(show_sample_lane)) {
    top_list$Cohort <- cohort
  }
  top <- if (length(top_list)) {
    do.call(ComplexHeatmap::HeatmapAnnotation, c(top_list, list(
      col = list(Cohort = setNames(pv_palette("categorical", 2), cohort_order)),
      annotation_name_gp = grid::gpar(fontsize = 6, fontfamily = fam),
      annotation_name_side = "left",
      simple_anno_size = grid::unit(3, "mm"),
      show_legend = TRUE,
      annotation_legend_param = list(
        title_gp = grid::gpar(fontsize = 6.5, fontfamily = fam),
        labels_gp = grid::gpar(fontsize = 6, fontfamily = fam)
      )
    )))
  } else {
    NULL
  }
  ht <- ComplexHeatmap::oncoPrint(
    mat,
    alter_fun = alter_fun,
    col = col,
    top_annotation = top,
    row_names_gp = grid::gpar(fontsize = 6.5, fontfamily = fam),
    column_names_gp = grid::gpar(fontsize = 5.5, fontfamily = fam),
    column_title = "Sample",
    column_title_gp = grid::gpar(fontsize = 7, fontfamily = fam),
    row_title = "Gene",
    row_title_gp = grid::gpar(fontsize = 7, fontfamily = fam),
    show_column_names = TRUE,
    remove_empty_columns = FALSE,
    remove_empty_rows = FALSE,
    pct_gp = grid::gpar(fontsize = 5.5, fontfamily = fam),
    alter_fun_is_vectorized = FALSE
  )
  ComplexHeatmap::draw(ht, padding = grid::unit(c(2, 2, 2, 2), "mm"))
}

save_base(draw, width_mm = 183, height_mm = 120)
message("wrote preview.png")
