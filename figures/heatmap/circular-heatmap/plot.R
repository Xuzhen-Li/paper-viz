# Circular heatmap. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
split_sectors <- TRUE
show_track <- TRUE
# ------------------

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
rows <- unique(df$row)
cols <- unique(df$col)
mat <- matrix(NA_real_, length(rows), length(cols), dimnames = list(rows, cols))
mat[cbind(match(df$row, rows), match(df$col, cols))] <- df$value
modules <- df$module[match(rows, df$row)]
split <- if (isTRUE(split_sectors)) factor(modules, levels = unique(modules)) else NULL

pal <- pv_palette("diverging")
col_fun <- circlize::colorRamp2(c(-2, 0, 2), c(pal[1], pal[4], pal[7]))
draw_heat <- function() {
  graphics::par(bg = "white", mar = c(1.2, 1.2, 1.2, 1.2))
  circlize::circos.clear()
  circlize::circos.par(
    start.degree = 90,
    gap.degree = if (isTRUE(split_sectors)) 8 else 2,
    canvas.xlim = c(-1.35, 1.35),
    canvas.ylim = c(-1.35, 1.35)
  )
  circlize::circos.heatmap(
    mat,
    split = split,
    col = col_fun,
    cluster = FALSE,
    rownames.side = "none",
    show.sector.labels = isTRUE(split_sectors),
    track.height = 0.28,
    bg.border = "grey35",
    cell.border = "white",
    cell.lwd = 0.25
  )
  if (isTRUE(show_track)) {
    nc <- ncol(mat)
    left <- seq_len(max(1, nc %/% 3))
    right <- seq(nc - max(1, nc %/% 3) + 1, nc)
    score <- rowMeans(mat[, left, drop = FALSE]) - rowMeans(mat[, right, drop = FALSE])
    track <- cbind(score = score)
    rownames(track) <- rownames(mat)
    circlize::circos.heatmap(
      track,
      split = split,
      col = col_fun,
      cluster = FALSE,
      rownames.side = "none",
      track.height = 0.06,
      cell.border = NA
    )
  }
  graphics::text(0, 0, "z-score", cex = 0.65)
  circlize::circos.clear()
}

p <- ggplotify::as.ggplot(draw_heat)
pv_save(p, "figure", width_mm = 120, height_mm = 120)
message("wrote preview.png")
