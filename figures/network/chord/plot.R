# Chord diagram of flows among groups. circlize, base graphics.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_labels <- TRUE
link_alpha <- 0.55
directional <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
fam <- viz_sans_family()
groups0 <- sort(unique(c(df$source, df$target)))
w_src <- tapply(df$value, df$source, sum)
w_tgt <- tapply(df$value, df$target, sum)
score <- vapply(groups0, function(g) sum(w_src[g], w_tgt[g], na.rm = TRUE), numeric(1))
# Eight sectors pull in #fbee61 and tangle the ribbons. Five named groups plus Other.
if (length(groups0) > 6) {
  keep <- names(sort(score, decreasing = TRUE))[seq_len(5)]
  map_g <- function(g) if (g %in% keep) g else "Other"
  df$source <- vapply(df$source, map_g, character(1))
  df$target <- vapply(df$target, map_g, character(1))
  df <- stats::aggregate(value ~ source + target, df, sum)
  df <- df[df$source != df$target, , drop = FALSE]
  groups <- c(keep, "Other")
  pal <- c(pv_palette("categorical", length(keep)), "#E0E0E0")
} else {
  groups <- groups0
  pal <- pv_palette("categorical", length(groups))
  pal[pal == "#fbee61"] <- "#981b1e"
}
grid_col <- stats::setNames(pal, groups)
df$source <- factor(df$source, levels = groups)
df$target <- factor(df$target, levels = groups)

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
  graphics::par(mar = c(0.2, 0.2, 0.4, 0.2), family = fam)
  circlize::circos.clear()
  circlize::chordDiagram(
    df[, c("source", "target", "value")],
    grid.col = grid_col,
    transparency = 1 - link_alpha,
    directional = if (isTRUE(directional)) 1 else 0,
    direction.type = "arrows",
    link.arr.type = "big.arrow",
    annotationTrack = "grid",
    preAllocateTracks = list(track.height = 0.08),
    big.gap = 4,
    small.gap = 1
  )
  if (isTRUE(show_labels)) {
    circlize::circos.track(
      track.index = 1, panel.fun = function(x, y) {
        circlize::circos.text(
          circlize::CELL_META$xcenter,
          circlize::CELL_META$ylim[1],
          circlize::CELL_META$sector.index,
          facing = "bending.outside", niceFacing = TRUE,
          adj = c(0.5, 0), cex = 0.85
        )
      }, bg.border = NA
    )
  }
  circlize::circos.clear()
}

save_base(draw, width_mm = 140, height_mm = 140)
message("wrote preview.png")
