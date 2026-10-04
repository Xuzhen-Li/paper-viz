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
fam <- viz_sans_family()

draw_heat <- function() {
  graphics::par(bg = "white", mar = c(1.4, 1.4, 1.4, 1.4), family = fam)
  circlize::circos.clear()
  circlize::circos.par(
    start.degree = 90,
    gap.degree = if (isTRUE(split_sectors)) 8 else 2,
    canvas.xlim = c(-1.55, 1.55),
    canvas.ylim = c(-1.55, 1.55),
    points.overflow.warning = FALSE
  )
  circlize::circos.heatmap(
    mat,
    split = split,
    col = col_fun,
    cluster = FALSE,
    rownames.side = "outside",
    rownames.cex = 0.5,
    rownames.font = 1,
    show.sector.labels = FALSE,
    track.height = 0.26,
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
      track.height = 0.05,
      cell.border = NA
    )
  }
  if (isTRUE(split_sectors)) {
    for (s in circlize::get.all.sector.index()) {
      xy <- circlize::circlize(
        circlize::get.cell.meta.data("xcenter", sector.index = s, track.index = 1),
        1.35,
        sector.index = s,
        track.index = 1
      )
      graphics::text(xy[[1]][1], xy[[2]][1], s, cex = 0.72, font = 2)
    }
  }
  # Same colorRamp2 scale as a ComplexHeatmap legend. Drawn in base graphics
  # so it stays inside the circos hole; a grid legend on this device hangs.
  n <- 80
  z <- seq(-2, 2, length.out = n)
  cols <- col_fun(z)
  xs <- seq(-0.46, 0.46, length.out = n)
  graphics::rect(utils::head(xs, -1), -0.07, xs[-1], 0.07, col = utils::head(cols, -1), border = NA)
  graphics::text(0, 0.16, "z-score", cex = 0.85)
  graphics::text(c(-0.46, 0, 0.46), -0.16, c("-2", "0", "2"), cex = 0.7)
  circlize::circos.clear()
}

p <- ggplotify::as.ggplot(draw_heat)
pv_save(p, "figure", width_mm = 120, height_mm = 120)
message("wrote preview.png")
