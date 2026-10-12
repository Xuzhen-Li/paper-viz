# House-style PCA scatter of accessions, coloured by region with pv_palette("geo") (west -> east).
# PCA is computed here from the genotypes in data.csv; axis titles give % variance explained.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

region_order <- c("Iberia", "W Europe", "Balkans", "Caucasus", "Central Asia", "East Asia")   # west -> east
SIM_NOTE <- "Simulated data for illustration; not biological results"

d <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
g <- as.matrix(d[, grepl("^snp", names(d))])
g <- g[, apply(g, 2, stats::var) > 0]
pc <- stats::prcomp(g, center = TRUE, scale. = TRUE)
ve <- 100 * pc$sdev^2 / sum(pc$sdev^2)                    # % variance explained
sc <- data.frame(region = factor(d$region, levels = region_order), pc1 = pc$x[, 1], pc2 = pc$x[, 2])
if (stats::cor(sc$pc1, as.integer(sc$region)) < 0) sc$pc1 <- -sc$pc1   # west on the left
cols <- stats::setNames(pv_palette("geo"), region_order)
n_per <- table(sc$region); n_snp <- ncol(g)
stopifnot(all(n_per == n_per[[1]]), n_snp == 300)
# the simulation draws every SNP independently (no linkage), i.e. what an LD-pruned panel approximates
FOOT <- sprintf("n = %d per region; %d unlinked SNPs (equivalent to LD-pruned)\n%s", n_per[[1]], n_snp, SIM_NOTE)
stopifnot(length(cols) == 6, nlevels(sc$region) == 6)

# --- text colour: group colour, darkened when it is too pale on white ---------------------------------
# WCAG 2 contrast ratio against white. Rule: keep the group colour if it reaches 3:1 on white; otherwise
# mix it toward black in 2 % steps until it reaches 4.5:1 (the 7 pt body-text level).
rel_lum <- function(hex) {
  v <- grDevices::col2rgb(hex)[, 1] / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  sum(c(0.2126, 0.7152, 0.0722) * v)
}
contrast_white <- function(hex) 1.05 / (rel_lum(hex) + 0.05)
text_col <- function(hex) {
  if (contrast_white(hex) >= 3) return(hex)
  for (k in seq(0.02, 1, by = 0.02)) {
    m <- grDevices::col2rgb(hex)[, 1] * (1 - k)
    h <- grDevices::rgb(m[1], m[2], m[3], maxColorValue = 255)
    if (contrast_white(h) >= 4.5) return(h)
  }
  "#000000"
}
tcols <- vapply(cols, text_col, "")
contrast_tab <- data.frame(region = region_order, fill = unname(cols), ratio_fill = vapply(cols, contrast_white, 0),
                           text = unname(tcols), ratio_text = vapply(tcols, contrast_white, 0))
stopifnot(all(contrast_tab$ratio_text >= 3))

# --- direct labels next to each cluster -------------------------------------------------------------
# Work in mm on the real panel: each label is moved out from its cluster centroid along one of 24
# directions until its box clears every point by >= 0.5 mm; a placement is accepted only if the box is
# <= 2 mm from the nearest point of its own cluster, inside the panel, clear of earlier labels, and its
# centre is closer (in canvas mm, axes are not equal) to its own group centroid than to any other centroid,
# on the side of its cluster facing away from the nearest other group.
LAB_PT <- 9                                                   # 7 pt + the 2x2 single-panel bump
r_pt <- pv_point_dims()[["outer_mm"]] / 2
lab_w <- vapply(region_order, function(t) {
  grDevices::cairo_pdf(tempfile()); on.exit(grDevices::dev.off())
  grid::convertWidth(grid::grobWidth(grid::textGrob(t, gp = grid::gpar(fontfamily = house_family(), fontsize = LAB_PT))),
                       "mm", valueOnly = TRUE)
}, 0)
LAB_H <- LAB_PT * 0.3528 * 0.74                               # cap height + small descender allowance, mm

build <- function(xl, yl, lab = NULL) {
  q <- ggplot(sc, aes(pc1, pc2)) +
    geom_point(aes(fill = region), shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
               colour = "black") +
    scale_fill_manual(values = cols, guide = "none") +
    scale_colour_manual(values = tcols, guide = "none") +
    scale_x_continuous(limits = xl, labels = minus, expand = c(0, 0)) +
    scale_y_continuous(limits = yl, labels = minus, expand = c(0, 0)) +
    labs(x = sprintf("PC1 (%.1f%%)", ve[1]), y = sprintf("PC2 (%.1f%%)", ve[2]), caption = FOOT) +
    theme_house() +
    theme(plot.caption = element_text(size = 5, hjust = 1, colour = pv_palette("house_grey")[["mid"]],
                                      lineheight = 0.95, margin = margin(t = 1.2, unit = "mm")),
          plot.caption.position = "plot")
  if (!is.null(lab)) q <- q + geom_text(data = lab, aes(x, y, label = region, colour = region), hjust = 0.5,
                                        vjust = 0.5, size = pv_pt2size(7))
  q
}
minus <- function(x) gsub("-", "\u2212", format(x, trim = TRUE))
panel_mm <- function(q) {                                     # panel size on the 89 x 89 mm canvas
  grDevices::cairo_pdf(tempfile(), width = 89 / 25.4, height = 89 / 25.4); on.exit(grDevices::dev.off())
  g <- ggplot2::ggplotGrob(pv_bump_text(q, 2))
  pn <- g$layout[g$layout$name == "panel", ]
  wnull <- sum(grid::convertWidth(g$widths[-pn$l], "mm", valueOnly = TRUE))
  hnull <- sum(grid::convertHeight(g$heights[-pn$t], "mm", valueOnly = TRUE))
  c(w = 89 - wnull, h = 89 - hnull)
}
place <- function(xl, yl) {
  pm <- panel_mm(build(xl, yl))
  kx <- pm[["w"]] / diff(xl); ky <- pm[["h"]] / diff(yl)
  P <- cbind((sc$pc1 - xl[1]) * kx, (sc$pc2 - yl[1]) * ky)
  boxes <- list(); out <- NULL
  C <- t(vapply(region_order, function(r) colMeans(P[sc$region == r, , drop = FALSE]), c(0, 0)))   # centroids, mm
  dist_c <- as.matrix(stats::dist(C)); colnames(dist_c) <- rownames(dist_c) <- region_order
  for (rg in region_order) {
    own <- sc$region == rg; c0 <- colMeans(P[own, , drop = FALSE]); w <- lab_w[[rg]]; best <- NULL
    for (ang in seq(0, 2 * pi, length.out = 25)[-25]) {
      for (t in seq(0, 30, by = 0.2)) {
        cx <- c0[1] + t * cos(ang); cy <- c0[2] + t * sin(ang)
        bx <- c(cx - w / 2, cy - LAB_H / 2, cx + w / 2, cy + LAB_H / 2)
        dx <- pmax(bx[1] - P[, 1], 0, P[, 1] - bx[3]); dy <- pmax(bx[2] - P[, 2], 0, P[, 2] - bx[4])
        gap <- sqrt(dx^2 + dy^2) - r_pt
        if (min(gap) < 0.5) next
        own_gap <- min(gap[own])
        dc <- sqrt((C[, 1] - cx)^2 + (C[, 2] - cy)^2)            # label centre to every centroid, mm
        nb <- names(which.min(dist_c[rg, colnames(dist_c) != rg]))   # nearest other group (centroid, mm)
        away <- sum((c(cx, cy) - C[rg, ]) * (C[nb, ] - C[rg, ])) <= 0   # label on the far side from it
        ok <- away && dc[[rg]] < min(dc[names(dc) != rg]) && own_gap <= 2 && bx[1] >= 0.8 && bx[3] <= pm[["w"]] - 0.8 && bx[2] >= 0.8 && bx[4] <= pm[["h"]] - 0.8 &&
          all(vapply(boxes, function(o) bx[3] < o[1] - 0.8 || bx[1] > o[3] + 0.8 || bx[4] < o[2] - 0.5 || bx[2] > o[4] + 0.5, TRUE))
        if (ok && (is.null(best) || own_gap < best$g)) best <- list(g = own_gap, bx = bx, dc = dc)
        break                                                 # first clear spot along this direction
      }
    }
    if (is.null(best)) return(NULL)
    boxes[[rg]] <- best$bx
    out <- rbind(out, data.frame(region = factor(rg, levels = region_order),
                                 x = xl[1] + mean(best$bx[c(1, 3)]) / kx, y = yl[1] + mean(best$bx[c(2, 4)]) / ky,
                                 own_gap_mm = best$g, own_centroid_mm = best$dc[[rg]],
                                 other_centroid_mm = min(best$dc[names(best$dc) != rg]),
                                 nearest_other = names(best$dc[names(best$dc) != rg])[which.min(best$dc[names(best$dc) != rg])]))
  }
  out
}
# tight axis ranges: start at the data range + 4 %, widen in 3 % steps only if some label has no spot
rx <- diff(range(sc$pc1)); ry <- diff(range(sc$pc2)); pad <- 0.04
repeat {
  xl <- range(sc$pc1) + c(-1, 1) * pad * rx; yl <- range(sc$pc2) + c(-1, 1) * pad * ry
  lab <- place(xl, yl)
  if (!is.null(lab) || pad > 0.3) break
  pad <- pad + 0.02                                           # widen a little if a label has no valid spot
}
stopifnot(!is.null(lab), nrow(lab) == 6, all(lab$own_gap_mm >= 0.5), all(lab$own_gap_mm <= 2),
          all(lab$own_centroid_mm < lab$other_centroid_mm))   # every label is nearest its own group centroid (mm)
p <- build(xl, yl, lab)
print(contrast_tab, digits = 3); print(lab, digits = 3); message(sprintf("axis pad %.2f", pad))

pv_save_house(p, "figure", cells = "2x2")
message(sprintf("PC1 %.2f%%, PC2 %.2f%%", ve[1], ve[2]))
message("wrote preview.png")
