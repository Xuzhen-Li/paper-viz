# Circos (house style): ideogram ring with chromosome names, density heatmap ring (warm house ramp),
# bar ring and link ribbons. circlize base graphics, wrapped with ggplotify for pv_save_house(); text is
# Arial 7 pt via cex = pt / 12 (ggplotify replays on a 12 pt device). Ring key and link count sit in
# the hole. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_heatmap <- TRUE
show_bars <- TRUE
show_links <- TRUE
link_alpha <- 0.35

set.seed(1)   # fixed RNG state, so the figure never depends on the session
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# orange marks/labels use the darker chrom12 step of the same hue (#E17927, 3.01:1 on white)
hp[["orange"]] <- pv_palette("chrom12")[[8]]
# label text: the group colour if it reaches 3:1 contrast on white, else #1A1A1A (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  stats::setNames(ifelse(ratio >= 3, hex, "#1A1A1A"), names(hex))
}
caption_theme <- theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                                   lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
                       plot.caption.position = "plot")
# push end-of-line label positions apart to at least `gap` (data units), keeping their order
spread <- function(y, gap) {
  o <- order(y); z <- y[o]
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  shift <- mean(z) - mean(y[o]); z <- z - shift
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  y[o] <- z; y
}
df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
bins <- df[!is.na(df$value), , drop = FALSE]
links <- df[is.na(df$value) & nzchar(df$link_to), , drop = FALSE]

fam <- house_family()
# ggplotify measures text on an off-screen pdf device, which only knows the PostScript font list; give
# it Helvetica metrics for the house family so that step does not warn (output devices use real Arial)
if (is.null(grDevices::pdfFonts()[[fam]])) {
  do.call(grDevices::pdfFonts, stats::setNames(list(grDevices::pdfFonts()$Helvetica), fam))
}
cex_pt <- function(pt) pt / 12
heat_cols <- grDevices::colorRampPalette(pv_palette("house_warm"))(64)
bar_col <- hp[["blue"]]
link_col <- hp[["purple"]]

parse_link <- function(x) {
  parts <- strsplit(x, ":", fixed = TRUE)[[1]]
  se <- strsplit(parts[2], "-", fixed = TRUE)[[1]]
  data.frame(chr = parts[1], start = as.numeric(se[1]), end = as.numeric(se[2]), stringsAsFactors = FALSE)
}

draw <- function() {
  graphics::par(bg = "white", mar = c(0, 0, 0, 0), family = fam)
  ideo <- stats::aggregate(end ~ chr, bins, max)
  ideo$start <- 0
  ideo <- ideo[, c("chr", "start", "end")]
  circlize::circos.clear()
  circlize::circos.par(cell.padding = c(0, 0, 0, 0), track.margin = c(0.006, 0.006), gap.degree = 2,
                       start.degree = 90, points.overflow.warning = FALSE, canvas.xlim = c(-1.12, 1.12),
                       canvas.ylim = c(-1.12, 1.12))
  circlize::circos.genomicInitialize(ideo, plotType = NULL, tickLabelsStartFromZero = FALSE)
  circlize::circos.track(
    ylim = c(0, 1), track.height = 0.07, bg.border = NA,
    panel.fun = function(x, y) {
      chr <- circlize::get.cell.meta.data("sector.index")
      xlim <- circlize::get.cell.meta.data("xlim")
      circlize::circos.rect(xlim[1], 0, xlim[2], 1, col = grey[["light"]], border = grey[["text"]],
                            lwd = 0.5 / 0.75)
      circlize::circos.text(mean(xlim), 1.5, chr, cex = cex_pt(7), col = "#1A1A1A",
                            facing = "inside", niceFacing = TRUE, adj = c(0.5, 0))
    }
  )
  if (isTRUE(show_heatmap)) {
    brk <- seq(min(bins$value), max(bins$value), length.out = length(heat_cols) + 1L)
    circlize::circos.genomicTrack(
      bins[, c("chr", "start", "end", "value")], ylim = c(0, 1), track.height = 0.11, bg.border = NA,
      panel.fun = function(region, value, ...) {
        idx <- findInterval(value[[1]], brk, all.inside = TRUE)
        circlize::circos.genomicRect(region, value, ytop = 1, ybottom = 0, col = heat_cols[idx], border = NA)
      }
    )
  }
  if (isTRUE(show_bars)) {
    ymax <- max(bins$value) * 1.05
    circlize::circos.genomicTrack(
      bins[, c("chr", "start", "end", "value")], ylim = c(0, ymax), track.height = 0.15,
      bg.border = grey[["light"]],
      panel.fun = function(region, value, ...) {
        circlize::circos.genomicRect(region, value, ytop = value[[1]], ybottom = 0, col = bar_col, border = NA)
      }
    )
  }
  if (isTRUE(show_links) && nrow(links)) {
    to <- do.call(rbind, lapply(links$link_to, parse_link))
    circlize::circos.genomicLink(links[, c("chr", "start", "end")], to,
                                 col = grDevices::adjustcolor(link_col, alpha.f = link_alpha), border = NA)
  }
  circlize::circos.clear()
}
# ring key + stat in the top-left corner, outside the circle
key <- c(if (isTRUE(show_heatmap)) sprintf("Heat ring: density\n(%.0f-%.0f)", min(bins$value), max(bins$value)),
         if (isTRUE(show_bars)) "Bar ring: density",
         if (isTRUE(show_links) && nrow(links)) sprintf("%d links", nrow(links)))
key_col <- c(if (isTRUE(show_heatmap)) "#1A1A1A", if (isTRUE(show_bars)) text_col(c(b = bar_col))[[1]],
             if (isTRUE(show_links) && nrow(links)) text_col(c(l = link_col))[[1]])
key_y <- 1 - c(0, cumsum(ifelse(grepl("\n", key), 0.075, 0.042)))[seq_along(key)]

p <- ggplotify::as.ggplot(draw) +
  annotate("text", x = 0, y = key_y, label = key, colour = key_col, hjust = 0, vjust = 1, lineheight = 0.9,
           size = pv_pt2size(7), family = fam) +
  coord_fixed(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) +
  labs(caption = footnote) +
  theme(text = element_text(family = fam), plot.background = element_rect(fill = "white", colour = NA)) +
  caption_theme

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
