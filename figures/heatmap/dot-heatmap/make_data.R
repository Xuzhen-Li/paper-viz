# Dot-heatmap values stay continuous. Pie fractions are a second table.
# Run from this directory.
set.seed(516)
rows <- c(
  "CD4 T", "CD8 T", "Treg", "NK", "B cell", "Plasma", "Mono", "Macro",
  "cDC", "pDC", "Neutro", "Mast", "Fibro", "Endo", "Pericyte", "Epi",
  "Malig", "Keratin", "Melano", "Schwann"
)
cols <- sprintf("P%02d", 1:12)
n <- length(rows) * length(cols)
value <- stats::rnorm(n, 0, 0.9)
size <- stats::rbeta(n, 1.4, 2.2)
value <- value + 0.35 * stats::qlogis(pmax(pmin(size, 0.98), 0.02))
dot <- data.frame(
  row = rep(rows, times = length(cols)),
  col = rep(cols, each = length(rows)),
  value = value,
  size = size,
  stringsAsFactors = FALSE
)
utils::write.csv(dot, "data.csv", row.names = FALSE)

parts <- c("Lymphoid", "Myeloid", "Stromal")
pie_rows <- lapply(seq_len(nrow(dot)), function(i) {
  w <- stats::rgamma(3, shape = c(1.4, 1.1, 0.8) + c(0.4, 0.2, 0.15) * dot$size[i])
  data.frame(
    row = dot$row[i], col = dot$col[i],
    Lymphoid = w[1] / sum(w), Myeloid = w[2] / sum(w), Stromal = w[3] / sum(w),
    size = dot$size[i]
  )
})
utils::write.csv(do.call(rbind, pie_rows), "data_pie.csv", row.names = FALSE)
message("wrote data.csv data_pie.csv")
