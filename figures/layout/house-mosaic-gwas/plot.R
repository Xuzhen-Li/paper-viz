# House mosaic, GWAS: double-column 4x2 page (183 x 89 mm) of a simulated drought tolerance GWAS in
# grapevine: genome-wide Manhattan (4x1 long panel), regional plot of the top locus, effect of the
# lead SNP (box + raw points) and allele frequency by population (stacked bars). Reads data*.csv only.
suppressPackageStartupMessages({ library(ggplot2); library(patchwork) })
source("../../../styles/r/theme_house.R")
grDevices::cairo_pdf(tempfile(fileext = ".pdf"))   # Arial metrics while tiles are measured; closed at the end
pal <- pv_palette("house"); grey <- pv_palette("house_grey"); warm <- pv_palette("house_warm")
TAG_PT <- 10; T7 <- pv_pt2size(7)
minus <- function(x) gsub("-", "\u2212", format(x, trim = TRUE))
pt_layer <- function(...) geom_point(shape = HOUSE_POINT$shape, size = HOUSE_POINT$size,
                                     stroke = HOUSE_POINT$stroke, colour = "black", ...)
th <- theme_house()
tc <- c(WW = grey[["mid"]], SD = pal[["red"]])                         # treatment colours (whole series)
tis <- c("Leaf", "Root", "Shoot tip", "Berry skin", "Seed")
tis_c <- stats::setNames(unname(pal[c("green", "brown", "gold", "purple", "sky")]), tis)   # one colour per tissue
rd <- function(f) utils::read.csv(f, stringsAsFactors = FALSE, check.names = FALSE)

# --- tile helpers: every panel is a standalone ggplot placed on whole grid cells by
# pv_house_mosaic(). tile() pins the outer bands so panel frames line up across tiles.
# Fixed outer bands (mm) so panel frames line up across tiles in the same column/row:
# left = y ticks + title, bottom = x ticks + title, top = room for the tag.
BAND <- list(l = 11.5, b = 8.6, t = 4.2, r = 1.2)
.mm <- function(u) as.numeric(grid::convertUnit(u, "mm", valueOnly = TRUE))
.width_mm  <- function(g, idx) if (length(idx)) sum(vapply(idx, function(i) .mm(grid::convertWidth(g$widths[i], "mm")), 0)) else 0
.height_mm <- function(g, idx) if (length(idx)) sum(vapply(idx, function(i) .mm(grid::convertHeight(g$heights[i], "mm")), 0)) else 0

# tile(): ggplot -> grob with fixed bands and a bold tag at the tile's top-left corner.
tile <- function(p, tag = NULL, l = BAND$l, b = BAND$b, t = BAND$t, r = BAND$r) {
  p <- .pv_set_text_family(p + theme(plot.margin = margin(0, 0, 0, 0)))
  g <- ggplotGrob(p)
  pan <- g$layout[grepl("^panel", g$layout$name), ]
  pl <- min(pan$l); pr <- max(pan$r); pt <- min(pan$t); pb <- max(pan$b)
  nc <- length(g$widths); nr <- length(g$heights)
  fit <- function(have, want, side) {
    if (have > want + 0.01) stop(sprintf("tile %s: %s band needs %.2f mm > %.2f", tag, side, have, want))
    grid::unit(want - have, "mm")
  }
  g$widths[1]   <- g$widths[1]  + fit(.width_mm(g, seq_len(pl - 1)), l, "left")
  g$widths[nc]  <- g$widths[nc] + fit(.width_mm(g, if (pr < nc) (pr + 1):nc else integer()), r, "right")
  g$heights[1]  <- g$heights[1] + fit(.height_mm(g, seq_len(pt - 1)), t, "top")
  g$heights[nr] <- g$heights[nr] + fit(.height_mm(g, if (pb < nr) (pb + 1):nr else integer()), b, "bottom")
  if (!is.null(tag)) g <- add_tag(g, tag)
  g
}
add_tag <- function(g, tag) {
  grid::grobTree(g, grid::textGrob(tag, x = grid::unit(0.3, "mm"), y = grid::unit(1, "npc") - grid::unit(0.2, "mm"),
    hjust = 0, vjust = 1, gp = grid::gpar(fontfamily = house_family(), fontface = "bold", fontsize = TAG_PT)))
}
# patchwork / composite tiles: tag only (they control their own inner layout)
tile_pw <- function(p, tag) add_tag(patchwork::patchworkGrob(p), tag)

# --- parameters ---------------------------------------------------------------------------
page_cells <- c(4, 2)
lead_genes <- data.frame(chr = c(4, 11, 17), lab = c("VvNCED3", "VvPIP2;1", "VvLEA4"))   # candidate gene per peak
zoom <- c(10.8, 13.8)    # b: chr 4 window (Mb)
thr <- -log10(5e-8)      # genome-wide threshold

snp <- rd("data.csv"); chrs <- rd("data_chr.csv"); gt <- rd("data_genotype.csv"); af <- rd("data_allele.csv")

# a Manhattan -----------------------------------------------------------------------------------
off <- c(0, cumsum(chrs$length_mb + 1.2))[seq_len(nrow(chrs))]
snp$x <- snp$pos + off[snp$chr]; snp$lp <- -log10(snp$p)
mid <- off + chrs$length_mb / 2
leads <- do.call(rbind, lapply(lead_genes$chr, function(c) { s <- snp[snp$chr == c, ]; s[which.max(s$lp), ] }))
leads$lab <- lead_genes$lab
b3a <- ggplot(snp, aes(x, lp)) + geom_point(aes(colour = I(ifelse(chr %% 2 == 1, pal[["blue"]], pal[["sky"]]))), size = 0.35, shape = 16) +
  geom_hline(yintercept = thr, linetype = "22", linewidth = pv_house_lw("ref"), colour = pal[["red"]]) +
  geom_point(data = leads, shape = 23, size = 1.9, stroke = 0.3, fill = pal[["red"]], colour = "black") +
  geom_text(data = leads, aes(label = lab), nudge_x = 6, hjust = 0, size = T7, fontface = "italic") +
  annotate("text", x = 2, y = thr + 0.35, label = "Genome-wide threshold", hjust = 0, vjust = 0, size = T7, colour = pal[["red"]]) +
  scale_x_continuous(breaks = mid, labels = chrs$chr, limits = c(-1, max(snp$x) + 1), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 13), breaks = c(0, 4, 8, 12), expand = c(0, 0)) +
  labs(x = "Chromosome", y = "\u2212log10 P") + th

# b regional plot of the top locus, points coloured by r2 to the lead SNP ----------------------
loc <- snp[snp$chr == 4 & snp$pos > zoom[1] & snp$pos < zoom[2], ]
lead <- leads[leads$chr == 4, ]
# consistency: the genome-wide top hit is VvNCED3 on chr 4 (house-mosaic-aba-kinetics b claims it)
# and it is the lead SNP of the zoomed window
stopifnot(leads$lab[which.max(leads$lp)] == "VvNCED3", lead$chr == 4, lead$lp == max(loc$lp), !anyNA(loc$r2))
r2_cols <- c(pal[["blue"]], pal[["sky"]], pal[["green"]], pal[["orange"]], pal[["red"]])
loc$bin <- cut(loc$r2, c(-0.01, 0.2, 0.4, 0.6, 0.8, 1.01), labels = FALSE)
gm <- data.frame(s = c(11.1, 11.75, 12.15, 12.55, 13.05), e = c(11.5, 12.0, 12.45, 12.85, 13.5),
                 g = c("VvPP2C", "", "VvNCED3", "", "VvHAI1"))
b3b <- ggplot(loc, aes(pos, lp)) +
  geom_rect(data = gm, aes(xmin = s, xmax = e, ymin = -2.0, ymax = -1.0), fill = grey[["dark"]], inherit.aes = FALSE) +
  annotate("segment", x = zoom[1], xend = zoom[2], y = -1.5, yend = -1.5, linewidth = pv_house_lw("frame")) +
  geom_text(data = gm[gm$g != "", ], aes(x = (s + e) / 2, y = -2.3, label = g), vjust = 1, size = T7, fontface = "italic", inherit.aes = FALSE) +
  geom_hline(yintercept = thr, linetype = "22", linewidth = pv_house_lw("ref"), colour = pal[["red"]]) +
  geom_point(aes(fill = I(r2_cols[bin])), shape = 21, size = 1.3, stroke = 0.2, colour = "black") +
  geom_point(data = lead, shape = 23, size = 2.2, stroke = 0.3, fill = "#7B1FA2", colour = "black") +
  annotate("text", x = zoom[2] - 0.05, y = c(12.2, 10.9, 9.6, 8.3, 7.0), label = c("r\u00b2 > 0.8", "0.6\u20130.8", "0.4\u20130.6", "0.2\u20130.4", "< 0.2"),
           colour = c(rev(r2_cols)[1:4], "#164E7A"), hjust = 1, size = T7) +
  scale_x_continuous(limits = zoom, breaks = c(11, 12, 13), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-4.2, 13), breaks = c(0, 4, 8, 12), expand = c(0, 0)) +
  labs(x = "Chr 4 position (Mb)", y = "\u2212log10 P") + th

# c lead-SNP genotype effect --------------------------------------------------------------------
gt$x <- match(gt$genotype, c("AA", "AG", "GG"))
gcol <- c(AA = grey[["mid"]], AG = warm[3], GG = pal[["red"]])
b3c <- ggplot(gt, aes(x, dti, group = genotype)) +
  geom_point(aes(x = x + 0.16 * jitter, fill = genotype), shape = 21, size = 0.9, stroke = 0.15, alpha = 0.8) +
  geom_boxplot(fill = NA, width = 0.5, outlier.shape = NA, linewidth = pv_house_lw(0.6)) +
  scale_fill_manual(values = gcol, guide = "none") +
  scale_x_continuous(breaks = 1:3, labels = c("AA", "AG", "GG"), limits = c(0.4, 3.6), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0.15, 0.95), breaks = c(0.2, 0.5, 0.8), expand = c(0, 0)) +
  labs(x = "Lead SNP genotype", y = "Drought tolerance index") + th

# d allele frequency per population (stacked to 100%) -----------------------------------------
pops <- af$population
af <- rbind(data.frame(pop = pops, al = "G", f = af$g_percent), data.frame(pop = pops, al = "A", f = 100 - af$g_percent))
af$pop <- factor(af$pop, levels = pops); af$al <- factor(af$al, levels = c("A", "G"))
af$yi <- length(pops) + 1 - as.integer(af$pop)
b3d <- ggplot(af, aes(f, yi, fill = al)) + geom_col(width = 0.68, orientation = "y", colour = "white", linewidth = pv_house_lw(0.3)) +
  geom_text(data = af[af$al == "G", ], aes(x = f / 2, label = f), colour = "white", size = T7) +
  scale_fill_manual(values = c(A = grey[["light"]], G = pal[["red"]]), guide = "none") +
  annotate("text", x = 100, y = length(pops) + 0.62, label = "G (tolerant) allele, %", hjust = 1, vjust = 0, colour = pal[["red"]], size = T7) +
  scale_y_continuous(breaks = rev(seq_along(pops)), labels = pops, limits = c(0.5, length(pops) + 1), expand = c(0, 0)) +
  scale_x_continuous(limits = c(0, 100), breaks = c(0, 50, 100), expand = c(0, 0)) +
  labs(x = "Allele frequency (%)", y = NULL) + th

mosaic <- pv_house_mosaic(list(
  list(plot = tile(b3a, "a"), at = c(1, 1), cells = c(4, 1)),
  list(plot = tile(b3b, "b"), at = c(1, 2), cells = c(2, 1)),
  list(plot = tile(b3c, "c"), at = c(3, 2), cells = c(1, 1)),
  list(plot = tile(b3d, "d"), at = c(4, 2), cells = c(1, 1))
), cells = page_cells)
pv_save_house(mosaic, "figure", cells = page_cells)

grDevices::dev.off()
message("wrote preview.png")
