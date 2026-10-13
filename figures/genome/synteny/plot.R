# Synteny (house style): ribbons between chromosome bars (forward blue, reversed red, named in the panel)
# and an anchor dot plot coloured by identity on the warm house ramp. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# 可调参数 -----------------------------------------------------------------
show_ribbon <- TRUE
show_dotplot <- TRUE
chr_layout <- "all" # all | A1-B1 only when "pair"
pair_chr <- "A1"

set.seed(1)   # fixed RNG state, so the figure never depends on the session
footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
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

orient_cols <- c(forward = hp[["blue"]], reverse = hp[["red"]])
n_rev <- length(unique(poly$block[poly$orient == "reverse"]))
n_blk <- length(unique(poly$block))
xr_rib <- range(c(bars_a$xmin, bars_a$xmax, bars_b$xmin, bars_b$xmax)) / 1e6
bars <- rbind(bars_a, bars_b)

p_rib <- ggplot() +
  geom_polygon(data = poly, aes(x = x / 1e6, y = y, group = block, fill = orient), alpha = 0.4, colour = NA) +
  geom_rect(data = bars, aes(xmin = xmin / 1e6, xmax = xmax / 1e6, ymin = ymin, ymax = ymax),
            fill = grey[["bg"]], colour = grey[["text"]], linewidth = pv_house_lw("frame")) +
  geom_text(data = bars_a, aes(lab_x / 1e6, 1.13, label = chr), vjust = 0, size = pv_pt2size(7),
            colour = "#1A1A1A", family = house_family()) +
  geom_text(data = bars_b, aes(lab_x / 1e6, -0.13, label = chr), vjust = 1, size = pv_pt2size(7),
            colour = "#1A1A1A", family = house_family()) +
  annotate("text", x = xr_rib[1] - 0.02 * diff(xr_rib), y = c(1, 0), label = c("Genome A", "Genome B"),
           hjust = 1, size = pv_pt2size(7), colour = "#1A1A1A", family = house_family()) +
  # ribbon key + stat, stacked in the empty top left
  annotate("text", x = xr_rib[1] - 0.2 * diff(xr_rib), y = c(1.5, 1.39, 1.28), hjust = 0, vjust = 1,
           label = c(sprintf("%d blocks", n_blk), sprintf("forward %d", n_blk - n_rev), sprintf("reversed %d", n_rev)),
           colour = c("#1A1A1A", text_col(orient_cols)[["forward"]], text_col(orient_cols)[["reverse"]]),
           size = pv_pt2size(7), family = house_family()) +
  scale_fill_manual(values = orient_cols, guide = "none") +
  scale_x_continuous(breaks = seq(0, 1000, 50), expand = expansion(mult = c(0.2, 0.02))) +
  scale_y_continuous(limits = c(-0.35, 1.55), expand = c(0, 0)) +
  labs(x = "Position (Mb)", y = NULL) +
  theme_house() +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

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

p_dot <- ggplot(dots, aes(x / 1e6, y / 1e6, fill = identity)) +
  geom_point(shape = 21, size = 1.2, stroke = 0.2, colour = grey[["dark"]]) +
  annotate("text", x = Inf, y = -Inf, hjust = 1.05, vjust = -0.6,
           label = sprintf("%d anchors\nmedian identity %.1f%%", nrow(dots), stats::median(dots$identity)),
           lineheight = 0.95, size = pv_pt2size(7), colour = "#1A1A1A", family = house_family()) +
  scale_fill_gradientn(colours = pv_palette("house_warm"), name = "Identity (%)", breaks = c(80, 90)) +
  guides(fill = guide_colourbar(direction = "horizontal", title.position = "top", ticks = FALSE,
                                barwidth = unit(16, "mm"), barheight = unit(2, "mm"))) +
  labs(x = "Genome A (Mb)", y = "Genome B (Mb)") +
  theme_house() +
  theme(legend.position = "inside", legend.position.inside = c(0.03, 0.97),
        legend.justification.inside = c(0, 1), legend.background = element_blank(),
        legend.title = element_text(size = 7), legend.text = element_text(size = 7))

note <- plot_annotation(caption = footnote, theme = theme_house() + caption_theme +
                          theme(plot.margin = margin(1, 1.5, 1, 1, "mm")))
if (isTRUE(show_ribbon) && isTRUE(show_dotplot)) {
  p <- (p_rib | p_dot) + plot_layout(widths = c(1.45, 1)) + note
  cells <- "4x2"
} else if (isTRUE(show_ribbon)) {
  p <- p_rib + note
  cells <- "4x1"
} else {
  p <- p_dot + note
  cells <- "2x2"
}
pv_save_house(p, "figure", cells = cells, bump = 0)
message("wrote preview.png")
