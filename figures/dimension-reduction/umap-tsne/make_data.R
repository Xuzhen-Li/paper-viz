# Two embeddings of the same cells. Colour and labels are applied in plot.R.
# Run from this directory.
set.seed(61)
n <- 200
sizes <- c(54, 46, 38, 36, 26)
cluster <- factor(rep(paste0("C", seq_along(sizes)), sizes), levels = paste0("C", seq_along(sizes)))
cell <- sprintf("cell%03d", seq_len(n))

blob <- function(idx, mx, my, sx, sy, rot, warp) {
  k <- length(idx)
  x0 <- stats::rnorm(k, 0, sx)
  y0 <- stats::rnorm(k, 0, sy)
  y0 <- y0 + warp * x0^2
  xr <- x0 * cos(rot) - y0 * sin(rot) + mx
  yr <- x0 * sin(rot) + y0 * cos(rot) + my
  cbind(xr, yr)
}

layouts <- list(
  UMAP = list(
    center = rbind(c(-2.4, -1.6), c(2.1, -2.2), c(-1.2, 2.6), c(3.4, 1.8), c(0.4, 0.2)),
    sx = c(0.72, 0.55, 0.90, 0.48, 0.62),
    sy = c(0.40, 0.85, 0.38, 0.70, 0.50),
    rot = c(0.4, -0.6, 0.9, 0.2, -1.1),
    warp = c(0.08, -0.05, 0.12, -0.09, 0.04)
  ),
  "t-SNE" = list(
    center = rbind(c(-18, 6), c(14, 16), c(-8, -18), c(20, -8), c(2, 4)),
    sx = c(3.2, 2.4, 4.1, 2.1, 3.6),
    sy = c(2.2, 3.8, 1.8, 3.1, 2.4),
    rot = c(-0.5, 0.7, 0.3, -0.9, 1.2),
    warp = c(0.04, -0.03, 0.05, 0.02, -0.04)
  )
)

rows <- list()
for (method in names(layouts)) {
  lay <- layouts[[method]]
  xy <- matrix(NA_real_, n, 2)
  for (i in seq_along(sizes)) {
    idx <- which(cluster == paste0("C", i))
    xy[idx, ] <- blob(idx, lay$center[i, 1], lay$center[i, 2], lay$sx[i], lay$sy[i], lay$rot[i], lay$warp[i])
  }
  rows[[method]] <- data.frame(
    cell = cell,
    cluster = as.character(cluster),
    dim1 = round(xy[, 1], 3),
    dim2 = round(xy[, 2], 3),
    method = method,
    stringsAsFactors = FALSE
  )
}

utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE, quote = FALSE)
message("wrote data.csv")
