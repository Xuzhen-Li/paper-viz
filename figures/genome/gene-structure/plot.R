# Gene models (house style) with optional domains, isoform track and mutation marks; the parts are named
# in a key row above the models, counts as the in-panel stat. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_domains <- TRUE
show_isoforms <- TRUE
show_mutations <- TRUE

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
if (!isTRUE(show_isoforms)) df <- df[df$gene != "Gene2.2", , drop = FALSE]
if (!isTRUE(show_domains)) df <- df[df$feature != "domain", , drop = FALSE]
if (!isTRUE(show_mutations)) df <- df[df$feature != "mutation", , drop = FALSE]

preferred <- c("Gene1", "Gene2.1", "Gene2.2", "Gene3", "Gene4", "Gene5", "Gene6")
gene_order <- c(preferred[preferred %in% unique(df$gene)], setdiff(unique(df$gene), preferred))
df$gene <- factor(df$gene, levels = rev(gene_order))
df$y <- as.numeric(df$gene)
ng <- nlevels(df$gene)

body <- df[df$feature %in% c("exon", "utr"), , drop = FALSE]
span <- do.call(rbind, lapply(split(body, body$gene), function(d) {
  data.frame(gene = d$gene[1], y = d$y[1], strand = d$strand[1], start = min(d$start), end = max(d$end))
}))
exons <- df[df$feature == "exon", , drop = FALSE]
utrs <- df[df$feature == "utr", , drop = FALSE]
doms <- df[df$feature == "domain", , drop = FALSE]
muts <- df[df$feature == "mutation", , drop = FALSE]
part_cols <- c(CDS = hp[["blue"]], UTR = hp[["sky"]], Domain = hp[["orange"]], Mutation = hp[["red"]])
xmax <- max(span$end)
span$x_tip <- ifelse(span$strand == "+", span$end, span$start)
span$x_end <- ifelse(span$strand == "+", span$end + 0.025 * xmax, span$start - 0.025 * xmax)
line_col <- grey[["dark"]]

p <- ggplot() +
  geom_segment(data = span, aes(x = start, xend = end, y = y, yend = y), linewidth = pv_house_lw("ref"),
               colour = line_col) +
  geom_segment(data = span, aes(x = x_tip, xend = x_end, y = y, yend = y), linewidth = pv_house_lw("ref"),
               colour = line_col, arrow = arrow(length = unit(1.1, "mm"), type = "closed")) +
  geom_rect(data = exons, aes(xmin = start, xmax = end, ymin = y - 0.2, ymax = y + 0.2), fill = part_cols[["CDS"]]) +
  geom_rect(data = utrs, aes(xmin = start, xmax = end, ymin = y - 0.11, ymax = y + 0.11), fill = part_cols[["UTR"]])
if (nrow(doms)) {
  p <- p + geom_rect(data = doms, aes(xmin = start, xmax = end, ymin = y - 0.1, ymax = y + 0.1),
                     fill = part_cols[["Domain"]])
}
if (nrow(muts)) {
  p <- p + geom_point(data = muts, aes(x = start, y = y + 0.38), shape = 25, size = 1.3, stroke = 0.3,
                      fill = part_cols[["Mutation"]], colour = "black")
}

# key row above the top model: swatch + name at fixed x positions (only the parts that are drawn)
key <- data.frame(part = names(part_cols), x = c(-0.02, 0.07, 0.16, 0.28) * xmax)
key <- key[c(TRUE, TRUE, nrow(doms) > 0, nrow(muts) > 0), ]
ky <- ng + 0.95
p <- p +
  geom_rect(data = key[key$part != "Mutation", ], aes(xmin = x, xmax = x + 0.022 * xmax, ymin = ky - 0.16, ymax = ky + 0.16,
                                                      fill = part)) +
  scale_fill_manual(values = part_cols, guide = "none") +
  geom_text(data = key, aes(x = x + 0.03 * xmax, y = ky, label = part), hjust = 0, size = pv_pt2size(7),
            colour = "#1A1A1A", family = house_family())
if (nrow(muts)) {
  p <- p + geom_point(data = key[key$part == "Mutation", ], aes(x = x + 0.011 * xmax, y = ky), shape = 25,
                      size = 1.3, stroke = 0.3, fill = part_cols[["Mutation"]], colour = "black")
}
stat <- sprintf("%d models, %d exons%s", ng, nrow(exons), if (nrow(muts)) sprintf(", %d mutations", nrow(muts)) else "")

y_labs <- sprintf("%s (%s)", span$gene, span$strand)
p <- p +
  annotate("text", x = xmax * 1.06, y = ky, label = stat, hjust = 1, size = pv_pt2size(7), colour = grey[["dark"]],
           family = house_family()) +
  scale_y_continuous(breaks = span$y, labels = y_labs, expand = expansion(add = c(0.45, 0.3))) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.01))) +
  coord_cartesian(xlim = c(-0.03 * xmax, xmax * 1.06), ylim = c(1, ky)) +
  labs(x = "Position within locus (bp)", y = NULL, caption = footnote) +
  theme_house() + theme(axis.ticks.y = element_blank(), plot.margin = margin(1, 2, 1, 1, "mm")) + caption_theme

pv_save_house(p, "figure", cells = "4x2")
message("wrote preview.png")
