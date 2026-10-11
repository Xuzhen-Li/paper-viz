# House mosaic, ABA kinetics: single-column 2x4 page (89 x 183 mm) of a simulated grapevine drought
# trial: time course (line), expression vs stem water potential (small multiples), VvNCED3 by
# tissue (raincloud) and log2 FC of DEGs (density). Reads data*.csv only. Run from this directory.
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
page_cells <- c(2, 4)
gwas_top <- "VvNCED3"   # top hit of the companion GWAS figure (house-mosaic-gwas); the b title claims it

kin <- rd("data.csv"); sm <- rd("data_psi.csv"); vi <- rd("data_raincloud.csv"); fc <- rd("data_fc.csv")

# a time course ---------------------------------------------------------------------------------
genes <- c(VvNCED3 = pal[["red"]], VvRD29B = pal[["orange"]], "VvPIP2;1" = pal[["blue"]])
b2a <- ggplot(kin, aes(hours, log2fc, colour = gene, fill = gene)) +
  geom_hline(yintercept = 0, linetype = "22", linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_ribbon(aes(ymin = log2fc - se, ymax = log2fc + se), colour = NA, alpha = 0.22) + geom_line(linewidth = pv_house_lw("main")) + pt_layer() +
  geom_text(data = kin[kin$hours == max(kin$hours), ], aes(x = max(kin$hours) + 7, label = gene), hjust = 0, size = T7, fontface = "bold.italic") +
  scale_colour_manual(values = genes, guide = "none") + scale_fill_manual(values = genes, guide = "none") +
  scale_x_continuous(limits = c(-5, 214), breaks = c(0, 48, 96, 144), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-3, 6), breaks = c(-2, 0, 2, 4), labels = minus, expand = c(0, 0)) +
  labs(x = "Hours after irrigation cut", y = "log2 FC (leaf)") + th

# b small multiples: expression vs stem water potential -----------------------------------------
sm$gene <- factor(sm$gene, levels = c("VvNCED3", "VvRD29B", "VvPIP2;1", "VvLEA4"))
rlab <- do.call(rbind, lapply(split(sm, sm$gene), function(s) data.frame(gene = s$gene[1], r = stats::cor(s$psi, s$expression))))
rlab$lab <- sprintf("italic(r)*' = %s'", minus(sprintf("%.2f", rlab$r)))
r_top <- as.character(rlab$gene[which.max(abs(rlab$r))])        # gene with the tightest link
rlab$col <- ifelse(rlab$gene == r_top, pal[["red"]], "#000000")
sm$hl <- ifelse(sm$gene == r_top, pal[["red"]], pal[["sky"]])
# consistency: b's claim, and the sign of r vs the direction in a (up in drought <-> negative r)
stopifnot(r_top == gwas_top,
          diff(sort(round(abs(rlab$r), 2), decreasing = TRUE)[1:2]) <= -0.02,   # "tightest" is visible at the printed 2 dp
          sign(rlab$r[rlab$gene == "VvNCED3"]) == -sign(kin$log2fc[kin$gene == "VvNCED3" & kin$hours == 48]),
          sign(rlab$r[rlab$gene == "VvPIP2;1"]) == -sign(kin$log2fc[kin$gene == "VvPIP2;1" & kin$hours == 48]))
b2b <- ggplot(sm, aes(psi, expression)) +
  geom_smooth(aes(colour = I(ifelse(gene == r_top, pal[["red"]], "black"))), method = "lm", formula = y ~ x, fill = grey[["ci"]], linewidth = pv_house_lw("main")) +
  geom_point(aes(fill = I(hl)), shape = 21, size = 1.5, stroke = HOUSE_POINT$stroke, colour = "black") + facet_wrap(~gene, nrow = 2) +
  geom_text(data = rlab, aes(x = -0.35, y = 10.6, label = lab, colour = I(col)), hjust = 1, vjust = 1, size = T7, parse = TRUE) +
  scale_x_continuous(limits = c(-1.8, -0.2), breaks = c(-1.5, -1, -0.5), labels = minus, expand = c(0, 0)) +
  scale_y_continuous(limits = c(1, 11), breaks = c(3, 6, 9), expand = c(0, 0)) +
  labs(x = "\u03a8stem (MPa)", y = "Expression (log2 CPM)",
       title = sprintf("Tightest link to \u03a8stem (red, r = %s) is also the top GWAS hit (Fig. 3a)",
                       minus(sprintf("%.2f", rlab$r[rlab$gene == r_top])))) + th +
  theme(panel.spacing = unit(2.5, "mm"), strip.text = element_text(face = "italic"),
        plot.title = element_text(size = 7, colour = pal[["red"]], hjust = 1, margin = margin(b = 1.2, unit = "mm")))

# c horizontal raincloud: VvNCED3 by tissue x treatment ---------------------------------------
vi$y0 <- ifelse(vi$tissue == "Leaf", 3.15, 1.05) + ifelse(vi$treatment == "WW", 0.45, -0.45)
dens <- do.call(rbind, lapply(split(vi, list(vi$tissue, vi$treatment)), function(s) {
  d <- stats::density(s$expression, adjust = 1.1, n = 128)
  data.frame(x = d$x, h = d$y / max(d$y) * 0.55, y0 = s$y0[1], treatment = s$treatment[1]) }))
dens <- dens[dens$x >= 2 & dens$x <= 10, ]
qs <- do.call(rbind, lapply(split(vi, list(vi$tissue, vi$treatment)), function(s) data.frame(y0 = s$y0[1],
  q1 = stats::quantile(s$expression, .25), md = stats::median(s$expression), q3 = stats::quantile(s$expression, .75))))
vi$yj <- vi$y0 - 0.08 - vi$jitter * 0.18
b2c <- ggplot() +
  geom_ribbon(data = dens, aes(x, ymin = y0, ymax = y0 + h, fill = treatment, group = interaction(y0, treatment)), alpha = 0.7, colour = NA) +
  geom_segment(data = qs, aes(x = q1, xend = q3, y = y0, yend = y0), linewidth = pv_house_lw("emph")) +
  geom_point(data = qs, aes(md, y0), shape = 21, size = 1.4, stroke = 0.3, fill = "white") +
  geom_point(data = vi, aes(expression, yj, fill = treatment), shape = 21, size = 0.8, stroke = 0.15, colour = "black") +
  scale_fill_manual(values = tc, guide = "none") +
  annotate("text", x = c(5.75, 8.55), y = c(3.75, 2.85), label = c("WW", "SD"), colour = tc[c("WW", "SD")], fontface = "bold", hjust = 0, size = T7) +
  annotate("text", x = 9.85, y = 4.45, label = "VvNCED3", fontface = "italic", hjust = 1, vjust = 1, size = T7) +
  scale_y_continuous(breaks = c(3.15, 1.05), labels = c("Leaf", "Root"), limits = c(0.2, 4.55), expand = c(0, 0)) +
  scale_x_continuous(limits = c(2, 10), breaks = c(3, 6, 9), expand = c(0, 0)) +
  labs(x = "Expression (log2 CPM)", y = NULL) + th +
  theme(axis.text.y = element_text(colour = "black"))

# d density of DEG log2 FC ----------------------------------------------------------------------
dl <- do.call(rbind, lapply(c("Leaf", "Root"), function(t) {
  d <- stats::density(fc$log2fc[fc$tissue == t], from = -5, to = 5, n = 256, adjust = 0.9); data.frame(tissue = t, x = d$x, y = d$y) }))
tcol <- tis_c[c("Leaf", "Root")]
b2d <- ggplot(dl, aes(x, y, colour = tissue)) + geom_vline(xintercept = 0, linetype = "22", linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_line(linewidth = pv_house_lw("main")) +
  annotate("text", x = c(-0.5, 2.9), y = c(0.3, 0.275), label = c("Leaf", "Root"), colour = tcol, hjust = c(1, 0), fontface = "bold", size = T7) +
  scale_colour_manual(values = tcol, guide = "none") +
  scale_x_continuous(limits = c(-5, 5), breaks = c(-4, 0, 4), labels = minus, expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 0.35), breaks = c(0, 0.1, 0.2, 0.3), expand = c(0, 0)) +
  labs(x = "log2 FC of DEGs", y = "Density") + th

mosaic <- pv_house_mosaic(list(
  list(plot = tile(b2a, "a"), at = c(1, 1), cells = c(2, 1)),
  list(plot = tile(b2b, "b", t = 7.6), at = c(1, 2), cells = c(2, 2)),
  list(plot = tile(b2c, "c"), at = c(1, 4), cells = c(1, 1)),
  list(plot = tile(b2d, "d"), at = c(2, 4), cells = c(1, 1))
), cells = page_cells)
pv_save_house(mosaic, "figure", cells = page_cells)

grDevices::dev.off()
message("wrote preview.png")
