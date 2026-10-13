# Circular heatmap (house style): circlize draws in base graphics, so theme_house() cannot reach it;
# the house look is set by hand (Arial, 7 pt via cex, 0.5 pt borders, house_div scale) and the
# drawing is wrapped with ggplotify for pv_save_house(). Colour key and counts sit in the hole.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

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

div <- pv_palette("house_div"); grey <- pv_palette("house_grey")
col_fun <- circlize::colorRamp2(seq(-2, 2, length.out = length(div)), div)
fam <- house_family()
footnote <- "Simulated data for illustration; not biological results"
lwd_pt <- function(pt) pt / (72.27 / 96)   # base lwd 1 = 1/96 inch
# ggplotify replays the drawing on a 12 pt device, so text size is set as cex = pt / 12
cex_pt <- function(pt) pt / 12

draw_heat <- function() {
  graphics::par(bg = "white", mar = c(0, 0, 0, 0), family = fam)
  circlize::circos.clear()
  circlize::circos.par(
    start.degree = 90,
    gap.degree = if (isTRUE(split_sectors)) 8 else 2,
    canvas.xlim = c(-1.25, 1.25),
    canvas.ylim = c(-1.25, 1.25),
    points.overflow.warning = FALSE
  )
  circlize::circos.heatmap(
    mat,
    split = split,
    col = col_fun,
    cluster = FALSE,
    rownames.side = "outside",
    rownames.cex = cex_pt(7),
    rownames.font = 1,
    show.sector.labels = FALSE,
    track.height = 0.26,
    bg.border = grey[["dark"]],
    bg.lwd = lwd_pt(0.5),
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
      # circlize() returns polar coordinates (degrees, radius); module name goes outside the row names
      pol <- circlize::circlize(
        circlize::get.cell.meta.data("xcenter", sector.index = s, track.index = 1), 0,
        sector.index = s, track.index = 1
      )
      ang <- pol[1, 1] * pi / 180
      graphics::text(1.19 * cos(ang), 1.19 * sin(ang), s, cex = cex_pt(8))
    }
  }
  # Same colorRamp2 scale as a ComplexHeatmap legend. Drawn in base graphics
  # so it stays inside the circos hole; a grid legend on this device hangs.
  n <- 80
  z <- seq(-2, 2, length.out = n)
  cols <- col_fun(z)
  xs <- seq(-0.46, 0.46, length.out = n)
  graphics::rect(utils::head(xs, -1), -0.07, xs[-1], 0.07, col = utils::head(cols, -1), border = NA)
  graphics::text(0, 0.17, "z-score", cex = cex_pt(7))
  graphics::text(c(-0.46, 0, 0.46), -0.17, c("-2", "0", "2"), cex = cex_pt(7))
  graphics::text(0, -0.36, sprintf("%d features, %d samples", nrow(mat), ncol(mat)), cex = cex_pt(7))
  circlize::circos.clear()
}

p <- ggplotify::as.ggplot(draw_heat) +
  labs(caption = footnote) +
  theme(text = element_text(family = fam),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot", plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(0.4, 0.4, 0.9, 0.4, "mm"))
# base-graphics text is set to 7/8 pt above; no +2 pt single-panel bump for the wrapped drawing
pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
