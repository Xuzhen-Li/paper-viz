# Chord diagram of flows among groups (house style). circlize base graphics, wrapped with
# ggplotify for pv_save_house(); text is Arial 7 pt via cex = pt / 12 (ggplotify replays on a
# 12 pt device). Sector names take the sector colour when it is >= 3:1 on white, else #1A1A1A.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_labels <- TRUE
link_alpha <- 0.55
directional <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
fam <- house_family()
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration; not biological results"
cex_pt <- function(pt) pt / 12
groups0 <- sort(unique(c(df$source, df$target)))
w_src <- tapply(df$value, df$source, sum)
w_tgt <- tapply(df$value, df$target, sum)
score <- vapply(groups0, function(g) sum(w_src[g], w_tgt[g], na.rm = TRUE), numeric(1))
# More than six sectors tangle the ribbons: keep five named groups plus Other.
if (length(groups0) > 6) {
  keep <- names(sort(score, decreasing = TRUE))[seq_len(5)]
  map_g <- function(g) if (g %in% keep) g else "Other"
  df$source <- vapply(df$source, map_g, character(1))
  df$target <- vapply(df$target, map_g, character(1))
  df <- stats::aggregate(value ~ source + target, df, sum)
  df <- df[df$source != df$target, , drop = FALSE]
  groups <- c(keep, "Other")
  pal <- c(unname(hp[seq_along(keep)]), grey[["light"]])
} else {
  groups <- groups0
  pal <- unname(hp[seq_along(groups)])
}
grid_col <- stats::setNames(pal, groups)
label_col <- ifelse(pal %in% c(hp[c("orange", "sky", "gold")], grey[["light"]]), "#1A1A1A", pal)
names(label_col) <- groups
df$source <- factor(df$source, levels = groups)
df$target <- factor(df$target, levels = groups)

draw <- function() {
  graphics::par(bg = "white", mar = c(0, 0, 0, 0), family = fam)
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
    small.gap = 1,
    link.border = NA
  )
  if (isTRUE(show_labels)) {
    circlize::circos.track(
      track.index = 1, panel.fun = function(x, y) {
        circlize::circos.text(
          circlize::CELL_META$xcenter,
          circlize::CELL_META$ylim[1],
          circlize::CELL_META$sector.index,
          facing = "inside", niceFacing = TRUE,
          adj = c(0.5, 0), cex = cex_pt(7),
          col = label_col[[circlize::CELL_META$sector.index]]
        )
      }, bg.border = NA
    )
  }
  circlize::circos.clear()
}

p <- ggplotify::as.ggplot(draw) +
  labs(caption = footnote) +
  theme(text = element_text(family = fam),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot", plot.background = element_rect(fill = "white", colour = NA))

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
