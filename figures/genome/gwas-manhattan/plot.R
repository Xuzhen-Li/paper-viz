# Manhattan plus QQ (house style): 12 chromosomes in chrom12 colours (light / dark alternate), QTL hits in
# red diamonds with repelled SNP labels, genome-wide line at 5e-8, genomic inflation (lambda) in the QQ panel.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

# 可调参数 -----------------------------------------------------------------
sig_threshold <- 5e-8
sug_threshold <- 1e-5
show_qq <- TRUE
show_labels <- TRUE
n_label <- 3L

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
df <- df[order(df$chr, df$pos), , drop = FALSE]
chr_max <- tapply(df$pos, df$chr, max)
gap <- 1.5e6
chr_ids <- sort(unique(df$chr))
offset <- stats::setNames(cumsum(c(0, utils::head(chr_max[as.character(chr_ids)] + gap, -1))), chr_ids)
df$cum <- df$pos + offset[as.character(df$chr)]
centers <- tapply(df$cum, df$chr, function(z) mean(range(z)))
chr_cols <- stats::setNames(rep(pv_palette("chrom12"), length.out = length(chr_ids)), chr_ids)
hit_col <- hp[["red"]]
df$col <- ifelse(df$highlight == 1L, hit_col, chr_cols[as.character(df$chr)])
ref_col <- grey[["dark"]]
xmax <- max(df$cum) / 1e6

p_man <- ggplot(df, aes(cum / 1e6, -log10(p))) +
  geom_point(data = df[df$highlight != 1L, ], aes(colour = col), size = 0.5, shape = 16) +
  # QTL hits: red diamonds with a black outline, so they stand out from the red chrom12 pair
  geom_point(data = df[df$highlight == 1L, ], shape = 23, size = 1.6, stroke = 0.3, fill = hit_col,
             colour = "black") +
  scale_colour_identity() +
  geom_hline(yintercept = -log10(sig_threshold), linetype = "22", linewidth = pv_house_lw("ref"), colour = hit_col) +
  geom_hline(yintercept = -log10(sug_threshold), linetype = "12", linewidth = pv_house_lw("ref"), colour = ref_col) +
  annotate("text", x = xmax * 0.008, y = -log10(sig_threshold), hjust = 0, vjust = -0.7,
           label = sprintf("genome-wide %s", sub("e-0", "e-", format(sig_threshold))), size = pv_pt2size(7),
           colour = text_col(c(x = hit_col))[[1]], family = house_family()) +
  annotate("text", x = xmax * 0.008, y = -log10(sug_threshold), hjust = 0, vjust = -0.7,
           label = sprintf("suggestive %s", sub("e-0", "e-", format(sug_threshold))), size = pv_pt2size(7),
           colour = "#1A1A1A", family = house_family()) +
  scale_x_continuous(breaks = centers / 1e6, labels = chr_ids, expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(x = "Chromosome", y = "-log10 P") +
  theme_house()

if (isTRUE(show_labels)) {
  lab <- df[df$highlight == 1L, , drop = FALSE]
  lab <- utils::head(lab[order(lab$p), , drop = FALSE], n_label)
  # Fixed seed and iteration cap, no time cap (ggrepel defaults max.time to 0.5 s),
  # so the layout does not depend on machine speed.
  p_man <- p_man + ggrepel::geom_text_repel(
    data = lab, aes(label = snp),
    size = pv_pt2size(7), colour = "#1A1A1A",
    segment.size = pv_house_lw("ref"), segment.colour = ref_col, min.segment.length = 0,
    box.padding = 0.4, point.padding = 0.3, nudge_x = 40, nudge_y = 1,
    max.overlaps = 20, seed = 1, max.iter = 10000, max.time = Inf,
    family = house_family()
  )
}

obs <- sort(-log10(df$p))
exp_lp <- -log10(rev(stats::ppoints(length(obs))))
qq <- data.frame(expected = exp_lp, observed = obs)
lambda <- stats::median(stats::qchisq(df$p, 1, lower.tail = FALSE)) / stats::qchisq(0.5, 1)
p_qq <- ggplot(qq, aes(expected, observed)) +
  geom_abline(slope = 1, intercept = 0, linewidth = pv_house_lw("ref"), colour = ref_col) +
  geom_point(size = 0.6, shape = 16, colour = hp[["blue"]]) +
  annotate("text", x = 0, y = Inf, hjust = 0, vjust = 1.4, label = sprintf("lambda = %.3f", lambda),
           size = pv_pt2size(7), colour = "#1A1A1A", family = house_family()) +
  labs(x = "Expected -log10 P", y = "Observed -log10 P") +
  theme_house()

note <- plot_annotation(caption = footnote, theme = theme_house() + caption_theme +
                          theme(plot.margin = margin(1, 1.5, 1, 1, "mm")))
if (isTRUE(show_qq)) {
  p <- (p_man | p_qq) + plot_layout(widths = c(3, 1)) + note
} else {
  p <- p_man + note
}

pv_save_house(p, "figure", cells = "4x1")
message("wrote preview.png")
