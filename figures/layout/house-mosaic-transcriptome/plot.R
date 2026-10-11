# House mosaic, transcriptome: overview (PCA, DEG counts), main result (heatmap, UpSet of up-regulated
# DEGs) and statistics (GO forest, up/down share) of a simulated grapevine drought trial on a 4x3 page
# (183 x 135 mm). Reads data*.csv only. Run from this directory.
suppressPackageStartupMessages({ library(ggplot2); library(patchwork) })
source("../../../styles/r/theme_house.R")
grDevices::cairo_pdf(tempfile(fileext = ".pdf"))   # Arial metrics while tiles are measured; closed at the end
pal <- pv_palette("house"); grey <- pv_palette("house_grey"); warm <- pv_palette("house_warm")
TAG_PT <- 10; T7 <- pv_pt2size(7)
minus <- function(x) gsub("-", "\u2212", if (is.character(x)) x else format(x, trim = TRUE))   # no padding of strings
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
# footnote(): small grey 7 pt note inside a tile's band (simulated data disclaimer)
SIM_NOTE <- "Simulated data for illustration; not biological results"
footnote <- function(g, label = SIM_NOTE, x = 1, y = 1, hjust = 1, vjust = 1, dx = -1.2, dy = -0.6) {
  grid::grobTree(g, grid::textGrob(label, x = grid::unit(x, "npc") + grid::unit(dx, "mm"), y = grid::unit(y, "npc") + grid::unit(dy, "mm"),
    hjust = hjust, vjust = vjust, gp = grid::gpar(fontfamily = house_family(), fontsize = 7, col = grey[["mid"]], lineheight = 0.95)))
}
# top_anchor(): cairo_pdf truncates the page to whole points (e.g. 183 mm = 518.74 pt -> 518 pt) and the
# mosaic is placed from the bottom, so the top lost up to 0.26 mm. On PDF devices, shift the page down by
# that fraction so blocks are laid out from the top edge; PNG devices are exact and need no shift.
top_anchor <- function(m, h_mm) structure(grid::gTree(children = grid::gList(m), h_mm = h_mm, cl = c("pv_top", class(m))),
                                          pv_cells = attr(m, "pv_cells"))
makeContext.pv_top <- function(x) {
  h_pt <- x$h_mm / 25.4 * 72
  dy <- if (grepl("pdf", names(grDevices::dev.cur()), ignore.case = TRUE)) h_pt - floor(h_pt) else 0
  x$vp <- grid::viewport(y = grid::unit(1, "npc") - grid::unit(dy, "bigpts"), height = grid::unit(1, "npc"), just = "top")
  x
}
# patchwork / composite tiles: tag only (they control their own inner layout)
tile_pw <- function(p, tag) add_tag(patchwork::patchworkGrob(p), tag)

# Text colour on a filled shape (WCAG 2.x, as in house-upset #32): white if its contrast
# reaches 4.5:1, otherwise near-black #1A1A1A.
wcag_lum <- function(hex) { c <- grDevices::col2rgb(hex)[, 1] / 255
  c <- ifelse(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055)^2.4); sum(c(0.2126, 0.7152, 0.0722) * c) }
wcag_contrast <- function(a, b) { l <- sort(c(wcag_lum(a), wcag_lum(b)), decreasing = TRUE); (l[1] + 0.05) / (l[2] + 0.05) }
on_fill_text <- function(fill) vapply(fill, function(f) if (wcag_contrast("#FFFFFF", f) >= 4.5) "#FFFFFF" else "#1A1A1A", "", USE.NAMES = FALSE)

# UpSet as one tile. m: logical matrix items x sets (colnames = set labels).
# Layout: [note + key | intersection bars] over [set-size bars | set names | matrix]; the note
# block fills the corner above the set bars. Set-size values: inside the bar end when they fit
# with 1 mm either side (colour by on_fill_text), else just outside in the set colour.
upset_tile <- function(m, cols, n_show, tag, set_w = c(22, 16), bar_frac = 0.5,
                       ylab = "Shared genes", unit = "genes", dot = 1.8, head = NULL) {
  sets <- colnames(m); k <- length(sets)
  key <- apply(m, 1, function(r) paste(as.integer(r), collapse = ""))
  key <- key[grepl("1", key)]
  tab_all <- sort(table(key), decreasing = TRUE); n_inter <- length(tab_all)
  tab <- tab_all[seq_len(min(n_show, n_inter))]
  bits <- do.call(rbind, lapply(strsplit(names(tab), ""), as.integer))
  inter <- data.frame(x = seq_along(tab), n = as.integer(tab), deg = rowSums(bits))
  inter$fill <- ifelse(inter$deg == 1, cols[apply(bits, 1, which.max)], "#000000")
  set_n <- data.frame(set = factor(sets, levels = sets), row = k:1, n = colSums(m), fill = cols)
  y_top <- ceiling(max(inter$n) * 1.3 / 50) * 50
  shade <- data.frame(x = seq(2, nrow(inter), 2))
  xs <- scale_x_continuous(limits = c(0.5, nrow(inter) + 0.5), expand = c(0, 0))
  ys <- scale_y_continuous(limits = c(0.5, k + 0.5), expand = c(0, 0))
  noax <- theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.title.x = element_blank())
  blank_xy <- theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank(),
                    axis.title.x = element_blank(), axis.title.y = element_blank())
  pb <- ggplot(inter) +
    geom_rect(data = shade, aes(xmin = x - 0.5, xmax = x + 0.5, ymin = -Inf, ymax = Inf), fill = grey[["bg"]], inherit.aes = FALSE) +
    geom_col(aes(x, n, fill = I(fill)), width = 0.66) +
    geom_text(aes(x, n, label = n, colour = I(fill)), vjust = -0.35, size = T7) +
    xs + scale_y_continuous(limits = c(0, y_top), breaks = c(0, floor(y_top * 0.8 / 100) * 100), expand = c(0, 0)) +
    labs(y = ylab) + th + noax + theme(plot.margin = margin(4.2, 1.2, 0, 0, "mm"))
  dots <- do.call(rbind, lapply(seq_len(nrow(bits)), function(i)
    data.frame(x = i, row = k:1, on = bits[i, ] == 1, fill = ifelse(inter$deg[i] == 1, inter$fill[i], "#000000"))))
  segs <- do.call(rbind, lapply(seq_len(nrow(bits)), function(i) { r <- (k:1)[bits[i, ] == 1]
    data.frame(x = i, y0 = min(r), y1 = max(r)) }))
  pm <- ggplot() +
    geom_rect(data = shade, aes(xmin = x - 0.5, xmax = x + 0.5, ymin = -Inf, ymax = Inf), fill = grey[["bg"]]) +
    geom_point(data = dots[!dots$on, ], aes(x, row), shape = 21, size = dot, stroke = HOUSE_POINT$stroke, fill = grey[["light"]], colour = grey[["light"]]) +
    geom_segment(data = segs, aes(x, y0, xend = x, yend = y1), linewidth = pv_house_lw("main")) +
    geom_point(data = dots[dots$on, ], aes(x, row, fill = I(fill)), shape = 21, size = dot, stroke = HOUSE_POINT$stroke, colour = "black") +
    xs + ys + th + blank_xy + theme(plot.margin = margin(0.8, 1.2, 0, 0, "mm"))
  x_set <- ceiling(max(set_n$n) * 1.08 / 250) * 250
  dig <- 0.556 * 7 * 25.4 / 72; pad <- 1
  set_n$inside <- set_n$n / x_set * set_w[1] >= nchar(set_n$n) * dig + 2 * pad
  set_n$lab_col <- ifelse(set_n$inside, on_fill_text(set_n$fill), set_n$fill)
  set_n$lab_x <- set_n$n + ifelse(set_n$inside, -1, 1.2) * pad / set_w[1] * x_set
  set_n$lab_h <- ifelse(set_n$inside, 0, 1)
  ps <- ggplot(set_n, aes(n, row)) + geom_col(aes(fill = I(fill)), width = 0.74, orientation = "y") +
    geom_text(aes(x = lab_x, label = format(n, big.mark = ","), hjust = lab_h, colour = I(lab_col)), size = T7) +
    scale_x_reverse(limits = c(x_set, 0), breaks = c(x_set, 0), labels = function(v) format(v, big.mark = ","), expand = c(0, 0)) + ys +
    labs(x = "Set size") + th + theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), axis.title.y = element_blank(),
                                      plot.margin = margin(0.8, 1.5, 0, 0.4, "mm"))   # 1.5 mm gap to the set names
  pl <- ggplot(set_n, aes(1.95, row, label = set, colour = I(fill))) + geom_text(size = T7, hjust = 1) + ys +
    scale_x_continuous(limits = c(0, 2), expand = c(0, 0)) + theme_void() + theme(plot.margin = margin(0.8, 0, 0, 0, "mm"))
  # two-line note at the top-left: what is shown out of what (tissue colour = one tissue, black = shared)
  nl <- data.frame(y = c(5.1, 4.05), x = 0,
                   lab = c(sprintf("Top %d of %d intersections", nrow(inter), n_inter),
                           sprintf("%s of %s %s", format(sum(tab), big.mark = ","), format(sum(tab_all), big.mark = ","), unit)),
                   col = c("#000000", grey[["mid"]]))
  pn <- ggplot() + geom_text(data = nl, aes(x, y, label = lab, colour = I(col)), hjust = 0, size = T7) +
    scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) + scale_y_continuous(limits = c(0.3, 5.6), expand = c(0, 0)) +
    coord_cartesian(clip = "off") + theme_void() + theme(plot.margin = margin(4.2, 0, 0.5, 0.6, "mm"))
  p <- pn + pb + ps + pl + pm + plot_layout(design = "AAB\nCDE", widths = unit(c(set_w, 1), c("mm", "mm", "null")),
                                             heights = c(bar_frac, 1 - bar_frac))
  tile_pw(p, tag)
}
# --- parameters ---------------------------------------------------------------------------
page_cells <- c(4, 3)
# One SD-vs-WW contrast per tissue at a single sampling time (make_data.R simulates no time course, so no union).
# ASCII ">=" keeps the PDF to Arial subsets only.
DEG_DEF <- "DEG: |log2FC| >= 1, padj < 0.05, SD vs WW, 1 time point; e, f: upregulated genes only."
FOOT <- paste(DEG_DEF, "Simulated data for illustration; not biological results")
FOOT_X <- 0.0   # right inset (mm): ends on the block edge at 182 mm, clear of e's "Set size" title
n_show <- 12          # UpSet: intersections shown
BT <- 7; BB <- 8.6    # shared top / bottom band of a, b, c, d so their frames line up
LB <- 14.5            # left band of a, b: room for "Berry skin" / "Shoot tip"

smp <- rd("data.csv"); deg <- rd("data_deg.csv"); hm <- rd("data_heatmap.csv"); go <- rd("data_go.csv")
up <- rd("data_upset.csv")
deg$n <- ifelse(deg$direction == "Down", -deg$n, deg$n)

# a PCA ---------------------------------------------------------------------------------------
b1a <- ggplot(smp, aes(pc1, pc2)) +
  geom_point(aes(fill = treatment, shape = tissue), size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke, colour = "black") +
  scale_shape_manual(values = c(Leaf = 21, Root = 24), guide = "none") + scale_fill_manual(values = tc, guide = "none") +
  annotate("text", x = c(-18, 20), y = -21, label = c("Leaf", "Root"), size = T7, colour = tis_c[c("Leaf", "Root")], fontface = "bold") +
  annotate("text", x = 30, y = c(20.5, 15.5), label = c("SD", "WW"), colour = tc[c("SD", "WW")], fontface = "bold", size = T7, hjust = 1) +
  scale_x_continuous(limits = c(-32, 32), breaks = c(-20, 0, 20), labels = minus, expand = c(0, 0)) +
  scale_y_continuous(limits = c(-25, 24), breaks = c(-20, 0, 20), labels = minus, expand = c(0, 0)) +
  labs(x = "PC1 (48%)", y = "PC2 (21%)") + th

# b DEG counts, diverging horizontal bars ----------------------------------------------------
deg$yi <- 6 - match(deg$tissue, tis)
b1b <- ggplot(deg, aes(n, yi, fill = direction)) + geom_col(width = 0.68, orientation = "y") +
  geom_vline(xintercept = 0, linewidth = pv_house_lw("frame")) +
  geom_text(aes(label = format(abs(n), big.mark = ","), hjust = ifelse(n > 0, -0.12, 1.12), colour = direction), size = T7) +
  scale_fill_manual(values = c(Up = pal[["red"]], Down = pal[["blue"]]), guide = "none") +
  scale_colour_manual(values = c(Up = pal[["red"]], Down = pal[["blue"]]), guide = "none") +
  annotate("text", x = c(2150, -2150), y = 5.62, label = c("Up", "Down"), hjust = c(1, 0), colour = c(pal[["red"]], pal[["blue"]]), fontface = "bold", size = T7) +
  scale_y_continuous(breaks = 5:1, labels = tis, limits = c(0.45, 6.0), expand = c(0, 0)) +
  scale_x_continuous(limits = c(-2200, 2200), breaks = c(-1000, 0, 1000), labels = c("1k", "0", "1k"), expand = c(0, 0)) +
  labs(x = "DEGs (SD vs WW)", y = NULL) + th

# c heatmap with a thin group strip ---------------------------------------------------------
ng <- max(hm$gene); ns <- max(hm$sample)
cl <- unique(hm[order(hm$gene), c("gene", "cluster")])$cluster
cut_y <- ng + 1 - (cumsum(rle(cl)$lengths)[-length(rle(cl)$lengths)] + 0.5)
cl_y <- data.frame(lab = sub(" in ", " in\n", rle(cl)$values), y = ng + 1 - c(8.5, 22.5, 31))   # 2 lines: stay inside the block
strip <- data.frame(x0 = c(0.5, 4.5, 8.5, 12.5), lab = c("WW", "SD", "WW", "SD"), tis = c("Leaf", "Leaf", "Root", "Root"))
strip$txt <- paste(strip$tis, strip$lab)
b1c <- ggplot(hm, aes(sample, ng + 1 - gene, fill = z)) + geom_raster() +
  geom_hline(yintercept = cut_y, colour = "white", linewidth = pv_house_lw(1)) +
  geom_vline(xintercept = c(4.5, 8.5, 12.5), colour = "white", linewidth = pv_house_lw(c(0.6, 1.2, 0.6))) +
  geom_text(data = cl_y, aes(x = 16.8, y = y, label = lab), hjust = 0, size = T7, lineheight = 0.9, inherit.aes = FALSE) +
  geom_rect(data = strip, aes(xmin = x0 + 0.08, xmax = x0 + 3.92, ymin = ng + 0.75, ymax = ng + 1.45), fill = tc[strip$lab], inherit.aes = FALSE) +
  geom_text(data = strip, aes(x = x0 + 2, y = ng + 1.75, label = txt, colour = I(tc[lab])), fontface = "bold", size = T7, vjust = 0, inherit.aes = FALSE) +
  scale_fill_gradient2(low = pal[["blue"]], mid = "white", high = pal[["red"]], limits = c(-2, 2), guide = "none") +
  annotate("rect", xmin = 16.8 + (0:19) * 0.13, xmax = 16.8 + (1:20) * 0.13, ymin = 2.2, ymax = 3.4,
           fill = scales::gradient_n_pal(c(pal[["blue"]], "white", pal[["red"]]))(seq(0, 1, length.out = 20))) +
  annotate("text", x = c(16.8, 19.4), y = 1.7, label = c(minus(-2), "2"), size = T7, vjust = 1, hjust = c(0, 1)) +
  annotate("text", x = 16.8, y = 3.9, label = "z-score", size = T7, vjust = 0, hjust = 0) +
  scale_x_continuous(expand = c(0, 0)) + scale_y_continuous(expand = c(0, 0)) +
  coord_cartesian(xlim = c(0.5, ns + 0.5), ylim = c(0.5, ng + 0.5), clip = "off") +
  labs(x = sprintf("%d libraries (%d per group)", nrow(smp), max(table(paste(smp$tissue, smp$treatment)))),
       y = sprintf("%d top DEGs", ng)) + th +
  theme(axis.text.x = element_blank(), axis.text.y = element_blank(), axis.ticks = element_blank())

# d GO forest -----------------------------------------------------------------------------------
go$lab <- vapply(go$term, function(t) paste(strwrap(sub("biosynthetic", "biosynth.", t), 19), collapse = "\n"), "")
go$y <- rev(seq_len(nrow(go))); go$col <- ifelse(go$or > 1, pal[["red"]], pal[["blue"]])
b1d <- ggplot(go, aes(or, y)) + geom_vline(xintercept = 1, linetype = "22", linewidth = pv_house_lw("ref"), colour = grey[["ref"]]) +
  geom_errorbar(aes(xmin = lo, xmax = hi, colour = I(col)), width = 0, orientation = "y", linewidth = pv_house_lw("errorbar")) +
  geom_point(aes(fill = I(col)), shape = 22, size = 2.1, stroke = 0.3) +
  annotate("text", x = c(0.75, 1.35), y = nrow(go) + 0.85, label = c("Down", "Up"), hjust = c(1, 0), vjust = 0, colour = c(pal[["blue"]], pal[["red"]]), fontface = "bold", size = T7) +
  scale_x_log10(limits = c(0.18, 8), oob = scales::oob_keep, breaks = c(0.25, 1, 4), labels = c("0.25", "1", "4"), expand = c(0, 0)) +
  scale_y_continuous(breaks = go$y, labels = go$lab, expand = c(0, 0)) +
  coord_cartesian(ylim = c(0.4, nrow(go) + 0.6), clip = "off") +
  labs(x = "Odds ratio (GO)", y = NULL) + th

# e UpSet of up-regulated DEGs (set sizes must equal b's Up column) ---------------------------
mm <- as.matrix(up[, tis]) == 1
up_n <- stats::setNames(deg$n[deg$direction == "Up"], deg$tissue[deg$direction == "Up"])[tis]
stopifnot(identical(as.numeric(colSums(mm)), as.numeric(up_n)))
# UpSet column capacity (measured on house-mosaic-transcriptome e, 3x1 = 135 mm): everything outside the
# intersection columns (set bars, set names, gaps, y-axis band, right margin) takes 59 mm; each column needs
# >= 4.8 mm (three-digit label 4.23 mm + 0.6 mm). Limit = floor((width_mm - 59) / 4.8): 2x1 6, 3x1 15, 4x1 25.
UPSET_OVERHEAD_MM <- 59; UPSET_COL_MM <- 4.8
stopifnot(floor((pv_grid_span(3) - UPSET_OVERHEAD_MM) / UPSET_COL_MM) >= n_show)   # e is 3 cells wide
b1e <- upset_tile(mm, unname(tis_c), n_show = n_show, tag = "e", set_w = c(26, 15), bar_frac = 0.44,
                  ylab = "Up DEGs", unit = "up DEGs", dot = 1.5)

# f donut: the same unique up-regulated DEGs as e, split by how many tissues share each gene.
# Sectors do not overlap (each gene counted once) and sum to e's unique total.
k_tis <- rowSums(mm)
ud <- data.frame(lab = c("3+ tissues", "2 tissues", "1 tissue"),          # small sectors on the right half
                 n = c(sum(k_tis >= 3), sum(k_tis == 2), sum(k_tis == 1)))
ud$f <- ud$n / sum(ud$n); ud$e <- cumsum(ud$f); ud$s <- ud$e - ud$f; ud$mid <- (ud$s + ud$e) / 2
ud$col <- warm[5:3]                                              # house_warm: up-regulated family
n_unique <- sum(ud$n)
stopifnot(sum(ud$n) == nrow(mm), n_unique == nrow(mm),                                  # sectors == unique up-DEG total
          sum(ud$n) == sum(table(apply(mm, 1, paste, collapse = ""))),   # == e's "of N" (all intersections)
          sum(up_n) == sum(deg$n[deg$n > 0]),                       # e set sizes == b Up column (total)
          go$or[go$term == "water transport"] < 1, go$or[go$term == "response to desiccation"] > 1)
R0_FRAC <- 0.87   # inner radius sized so the widest centre line ("upregulated genes", 21.5 mm at 7 pt bold) clears the ring
# drawn in mm (1 unit = 1 mm): panel spans e's data block (top of the bars to the bottom of the matrix)
F_T <- 6.13; F_B <- 10.43; f_h <- 43 - F_T - F_B   # e bar area: top of the tallest bar to the bottom of the set-size bars (measured)
cx <- 13.4; cy <- f_h / 2; R1 <- f_h / 2; R0 <- R1 * R0_FRAC
arc <- function(s, e, r) { a <- pi / 2 - 2 * pi * seq(s, e, length.out = max(3, ceiling(abs(e - s) * 120))); cbind(cx + r * cos(a), cy + r * sin(a)) }
ring <- do.call(rbind, lapply(seq_len(nrow(ud)), function(i) {
  p <- rbind(arc(ud$s[i], ud$e[i], R1), arc(ud$e[i], ud$s[i], R0)); data.frame(x = p[, 1], y = p[, 2], id = i, col = ud$col[i]) }))
# leader anchor: the point of each sector nearest 3 o'clock (the label column), so no leader crosses the ring
ud$anc <- pmin(pmax(0.25, ud$s + 0.02), ud$e - 0.02)
ang <- pi / 2 - 2 * pi * ud$anc
ud$ex <- cx + R1 * cos(ang); ud$ey <- cy + R1 * sin(ang)
ud$ly <- seq(f_h - 4, 4, length.out = nrow(ud))[rank(-ud$ey)]   # label column, same vertical order as the sectors
ud$lx <- 2 * cx + 1.2
lo <- which.min(ud$ey); ud$ly[lo] <- min(ud$ly[lo], ud$ey[lo] - 0.5)   # lowest leader slopes down off the ring bottom, never across a sector
b1f <- ggplot() + geom_polygon(data = ring, aes(x, y, group = id, fill = I(col)), colour = "white", linewidth = pv_house_lw(0.6)) +
  geom_segment(data = ud, aes(x = ex, y = ey, xend = lx - 0.6, yend = ly, colour = I(col)), linewidth = pv_house_lw("ref")) +
  geom_text(data = ud, aes(x = lx, y = ly, label = sprintf("%s\n%s", lab, format(n, big.mark = ",")), colour = I(col)),
            hjust = 0, size = T7, lineheight = 0.9) +
  # widest line sits on the ring centre; the two short lines stack above it
  annotate("text", x = cx, y = cy + c(5.6, 2.8, 0), label = c(format(n_unique, big.mark = ","), "unique", "upregulated genes"),
           size = T7, fontface = "bold") +
  scale_x_continuous(limits = c(0, 43), expand = c(0, 0)) + scale_y_continuous(limits = c(0, f_h), oob = scales::oob_keep, expand = c(0, 0)) +
  coord_cartesian(clip = "off") + theme_void()

mosaic <- pv_house_mosaic(list(
  list(plot = tile(b1a, "a", l = LB, t = BT, b = BB), at = c(1, 1), cells = c(1, 1)),
  list(plot = tile(b1b, "b", l = LB, t = BT, b = BB), at = c(1, 2), cells = c(1, 1)),
  list(plot = tile(b1c, "c", l = 6, r = 14, t = BT, b = BB), at = c(2, 1), cells = c(2, 2)),
  list(plot = tile(b1d, "d", l = 24, t = BT, b = BB), at = c(4, 1), cells = c(1, 2)),
  list(plot = b1e, at = c(1, 3), cells = c(3, 1)),
  list(plot = tile(b1f, "f", l = 0, b = F_B, t = F_T, r = 0), at = c(4, 3), cells = c(1, 1))
), cells = page_cells)
# page footnote: one 7 pt grey line on the bottom edge, right of e's set-size axis title
mosaic <- structure(grid::gTree(children = grid::gList(mosaic, grid::textGrob(FOOT, x = grid::unit(1, "npc") - grid::unit(FOOT_X, "mm"),
  y = grid::unit(0.9, "mm"), hjust = 1, vjust = 0, gp = grid::gpar(fontfamily = house_family(), fontsize = 7, col = grey[["mid"]]))),
  cl = class(mosaic)), pv_cells = attr(mosaic, "pv_cells"))
mosaic <- top_anchor(mosaic, pv_grid_span(page_cells[2]) + if (page_cells[2] == 4) 2 else 0)
pv_save_house(mosaic, "figure", cells = page_cells)

grDevices::dev.off()
message("wrote preview.png")
