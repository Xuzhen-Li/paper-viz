# Circos: ideogram, density heatmap, bar ring, link ribbons.
# Base graphics (circlize). Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_heatmap <- TRUE
show_bars <- TRUE
show_links <- TRUE
link_alpha <- 0.35

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
bins <- df[!is.na(df$value), , drop = FALSE]
links <- df[is.na(df$value) & nzchar(df$link_to), , drop = FALSE]

fam <- viz_sans_family()
chr_col <- c(pv_palette("categorical", 7), "#882255")
names(chr_col) <- sprintf("Chr%d", 1:8)
heat_cols <- pv_palette("sequential", 64)

parse_link <- function(x) {
  parts <- strsplit(x, ":", fixed = TRUE)[[1]]
  se <- strsplit(parts[2], "-", fixed = TRUE)[[1]]
  data.frame(chr = parts[1], start = as.numeric(se[1]), end = as.numeric(se[2]), stringsAsFactors = FALSE)
}

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
  graphics::par(mar = c(0.4, 0.4, 0.6, 0.4), family = fam)
  ideo <- stats::aggregate(end ~ chr, bins, max)
  ideo$start <- 0
  ideo <- ideo[, c("chr", "start", "end")]
  circlize::circos.clear()
  circlize::circos.par(
    cell.padding = c(0, 0, 0, 0),
    track.margin = c(0.006, 0.006),
    gap.degree = 2,
    start.degree = 90,
    points.overflow.warning = FALSE
  )
  circlize::circos.genomicInitialize(ideo, plotType = NULL, tickLabelsStartFromZero = FALSE)
  circlize::circos.track(
    ylim = c(0, 1), track.height = 0.08, bg.border = NA,
    panel.fun = function(x, y) {
      chr <- circlize::get.cell.meta.data("sector.index")
      xlim <- circlize::get.cell.meta.data("xlim")
      circlize::circos.rect(xlim[1], 0, xlim[2], 1, col = chr_col[[chr]], border = NA)
      circlize::circos.text(
        mean(xlim), 1.6, chr,
        cex = 0.85, facing = "bending.inside", niceFacing = TRUE, adj = c(0.5, 0)
      )
    }
  )
  if (isTRUE(show_heatmap)) {
    brk <- seq(min(bins$value), max(bins$value), length.out = length(heat_cols) + 1L)
    circlize::circos.genomicTrack(
      bins[, c("chr", "start", "end", "value")],
      ylim = c(0, 1), track.height = 0.12, bg.border = NA,
      panel.fun = function(region, value, ...) {
        v <- value[[1]]
        idx <- findInterval(v, brk, all.inside = TRUE)
        circlize::circos.genomicRect(
          region, value, ytop = 1, ybottom = 0,
          col = heat_cols[idx], border = NA
        )
      }
    )
  }
  if (isTRUE(show_bars)) {
    ymax <- max(bins$value) * 1.05
    circlize::circos.genomicTrack(
      bins[, c("chr", "start", "end", "value")],
      ylim = c(0, ymax), track.height = 0.16, bg.border = "#D0D0D0",
      panel.fun = function(region, value, ...) {
        circlize::circos.genomicRect(
          region, value, ytop = value[[1]], ybottom = 0,
          col = "#2A629A", border = NA
        )
      }
    )
  }
  if (isTRUE(show_links) && nrow(links)) {
    to <- do.call(rbind, lapply(links$link_to, parse_link))
    from <- links[, c("chr", "start", "end")]
    circlize::circos.genomicLink(
      from, to,
      col = grDevices::adjustcolor("#E69F00", alpha.f = link_alpha),
      border = NA
    )
  }
  circlize::circos.clear()
}

save_base(draw, width_mm = 140, height_mm = 140)
message("wrote preview.png")
