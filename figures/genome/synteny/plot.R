# Synteny ribbons between chromosome bars, plus an anchor dot plot.
# Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_ribbon <- TRUE
show_dotplot <- TRUE
chr_layout <- "all" # all | A1-B1 only when "pair"
pair_chr <- "A1"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
chr_rows <- df[df$block == "", , drop = FALSE]
feat <- df[df$block != "", , drop = FALSE]
is_anchor <- feat$start == feat$end
blocks <- feat[!is_anchor, , drop = FALSE]
anchors <- feat[is_anchor, , drop = FALSE]

place_genome <- function(chr_df) {
  chr_df <- chr_df[order(chr_df$chr), , drop = FALSE]
  gap <- 6e6
  off <- 0
  pos <- list()
  for (i in seq_len(nrow(chr_df))) {
    pos[[chr_df$chr[i]]] <- off
    off <- off + (chr_df$end[i] - chr_df$start[i]) + gap
  }
  pos
}

off_a <- place_genome(chr_rows[chr_rows$genome == "A", , drop = FALSE])
off_b <- place_genome(chr_rows[chr_rows$genome == "B", , drop = FALSE])

chr_bars <- function(chr_df, y, off) {
  chr_df$xmin <- vapply(chr_df$chr, function(z) off[[z]], numeric(1))
  chr_df$xmax <- chr_df$xmin + chr_df$end
  chr_df$ymin <- y - 0.08
  chr_df$ymax <- y + 0.08
  chr_df$lab_x <- (chr_df$xmin + chr_df$xmax) / 2
  chr_df
}

bars_a <- chr_bars(chr_rows[chr_rows$genome == "A", , drop = FALSE], 1, off_a)
bars_b <- chr_bars(chr_rows[chr_rows$genome == "B", , drop = FALSE], 0, off_b)

blk_ids <- unique(blocks$block)
poly <- list()
for (b in blk_ids) {
  sub <- blocks[blocks$block == b, , drop = FALSE]
  ra <- sub[sub$genome == "A", , drop = FALSE]
  rb <- sub[sub$genome == "B", , drop = FALSE]
  if (!nrow(ra) || !nrow(rb)) next
  xa1 <- off_a[[ra$chr[1]]] + min(ra$start[1], ra$end[1])
  xa2 <- off_a[[ra$chr[1]]] + max(ra$start[1], ra$end[1])
  xb1 <- off_b[[rb$chr[1]]] + min(rb$start[1], rb$end[1])
  xb2 <- off_b[[rb$chr[1]]] + max(rb$start[1], rb$end[1])
  forward <- ra$end[1] > ra$start[1]
  # forward ribbon does not cross; reverse ribbon twists once
  xs <- if (forward) c(xa1, xa2, xb2, xb1) else c(xa1, xa2, xb1, xb2)
  orient <- if (forward) "forward" else "reverse"
  poly[[b]] <- data.frame(
    block = b,
    orient = orient,
    x = xs,
    y = c(0.92, 0.92, 0.08, 0.08),
    stringsAsFactors = FALSE
  )
}
poly <- do.call(rbind, poly)

orient_cols <- c(forward = pv_palette("categorical", 1), reverse = pv_palette("categorical", 4)[4])

p_rib <- ggplot2::ggplot() +
  ggplot2::geom_polygon(
    data = poly,
    ggplot2::aes(x = x / 1e6, y = y, group = block, fill = orient),
    alpha = 0.38, colour = NA
  ) +
  ggplot2::geom_rect(
    data = rbind(bars_a, bars_b),
    ggplot2::aes(xmin = xmin / 1e6, xmax = xmax / 1e6, ymin = ymin, ymax = ymax),
    fill = "#F4F4F4", colour = "#1e3a5f", linewidth = 0.25
  ) +
  ggplot2::geom_text(
    data = bars_a,
    ggplot2::aes(lab_x / 1e6, 1.16, label = chr),
    size = 2.1, family = viz_sans_family()
  ) +
  ggplot2::geom_text(
    data = bars_b,
    ggplot2::aes(lab_x / 1e6, -0.16, label = chr),
    size = 2.1, family = viz_sans_family()
  ) +
  ggplot2::annotate("text", x = -4, y = 1, label = "Genome A", size = 2.2, hjust = 1, family = viz_sans_family()) +
  ggplot2::annotate("text", x = -4, y = 0, label = "Genome B", size = 2.2, hjust = 1, family = viz_sans_family()) +
  ggplot2::scale_fill_manual(values = orient_cols, name = "Orientation") +
  ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.08, 0.02))) +
  ggplot2::scale_y_continuous(limits = c(-0.35, 1.35), expand = c(0, 0)) +
  ggplot2::labs(x = "Position (Mb)", y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank(),
    axis.line.y = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    legend.position = "right"
  )

# anchors: pair rows that share block order
anc_a <- anchors[anchors$genome == "A", , drop = FALSE]
anc_b <- anchors[anchors$genome == "B", , drop = FALSE]
anc_a <- anc_a[order(anc_a$block, anc_a$start), , drop = FALSE]
anc_b <- anc_b[order(anc_b$block, seq_len(nrow(anc_b))), , drop = FALSE]
# restore pair order from file order
anc_a <- anchors[anchors$genome == "A", , drop = FALSE]
anc_b <- anchors[anchors$genome == "B", , drop = FALSE]
stopifnot(nrow(anc_a) == nrow(anc_b))
dots <- data.frame(
  chr_a = anc_a$chr,
  chr_b = anc_b$chr,
  x = vapply(seq_len(nrow(anc_a)), function(i) off_a[[anc_a$chr[i]]] + anc_a$start[i], numeric(1)),
  y = vapply(seq_len(nrow(anc_b)), function(i) off_b[[anc_b$chr[i]]] + anc_b$start[i], numeric(1)),
  identity = anc_a$identity,
  stringsAsFactors = FALSE
)
if (chr_layout == "pair") {
  dots <- dots[dots$chr_a == pair_chr, , drop = FALSE]
}

p_dot <- ggplot2::ggplot(dots, ggplot2::aes(x / 1e6, y / 1e6, colour = identity)) +
  ggplot2::geom_point(size = 0.35, alpha = 0.75) +
  ggplot2::scale_colour_gradientn(colours = pv_palette("sequential", 5), name = "Identity (%)") +
  ggplot2::labs(x = "Genome A (Mb)", y = "Genome B (Mb)") +
  theme_viz() +
  ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white", colour = NA))

plots <- list()
if (isTRUE(show_ribbon)) plots[[length(plots) + 1L]] <- p_rib
if (isTRUE(show_dotplot)) plots[[length(plots) + 1L]] <- p_dot
if (length(plots) == 2L) {
  p <- cowplot::plot_grid(plots[[1]], plots[[2]], ncol = 1, rel_heights = c(0.85, 1.15), align = "v")
  h <- 150
} else {
  p <- plots[[1]]
  h <- if (isTRUE(show_dotplot)) 110 else 70
}
pv_save(p, "figure", width_mm = 183, height_mm = h)
message("wrote preview.png")
