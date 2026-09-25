# Manhattan plus QQ. Chromosomes alternate; genome-wide line at 5e-8.
source("../../../styles/r/theme_viz.R")

sig_threshold <- 5e-8
sug_threshold <- 1e-5
show_qq <- TRUE
show_labels <- TRUE
n_label <- 3L

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[order(df$chr, df$pos), , drop = FALSE]
chr_max <- tapply(df$pos, df$chr, max)
gap <- 1.5e6
chr_ids <- sort(unique(df$chr))
offset <- setNames(cumsum(c(0, head(chr_max[as.character(chr_ids)] + gap, -1))), chr_ids)
df$cum <- df$pos + offset[as.character(df$chr)]
centers <- tapply(df$cum, df$chr, function(z) mean(range(z)))
alt <- rep(c("#2A629A", "#BDBDBD"), length.out = length(chr_ids))
df$fill <- ifelse(df$highlight == 1L, "hit", "bg")
df$col <- ifelse(df$highlight == 1L, "#D55E00", alt[df$chr])

p_man <- ggplot2::ggplot(df, ggplot2::aes(cum / 1e6, -log10(p))) +
  ggplot2::geom_point(ggplot2::aes(colour = col), size = 0.35, alpha = 0.85) +
  ggplot2::scale_colour_identity() +
  ggplot2::geom_hline(
    yintercept = -log10(sig_threshold), linetype = "dashed",
    linewidth = 0.3, colour = "#D55E00"
  ) +
  ggplot2::geom_hline(
    yintercept = -log10(sug_threshold), linetype = "dotted",
    linewidth = 0.3, colour = "#6B6B6B"
  ) +
  ggplot2::scale_x_continuous(
    breaks = centers / 1e6,
    labels = chr_ids,
    expand = ggplot2::expansion(mult = c(0.01, 0.02))
  ) +
  ggplot2::labs(x = "Chromosome", y = expression(-log[10](italic(p)))) +
  theme_viz()

if (isTRUE(show_labels)) {
  lab <- df[df$highlight == 1L, , drop = FALSE]
  lab <- lab[order(lab$p), , drop = FALSE]
  lab <- head(lab, n_label)
  p_man <- p_man + ggrepel::geom_text_repel(
    data = lab,
    ggplot2::aes(label = snp),
    size = 1.8, colour = "#1e3a5f",
    segment.size = 0.2, min.segment.length = 0,
    max.overlaps = 20, seed = 1,
    family = viz_sans_family()
  )
}

obs <- sort(-log10(df$p))
n <- length(obs)
exp_lp <- -log10(rev(stats::ppoints(n)))
qq <- data.frame(expected = exp_lp, observed = obs)
p_qq <- ggplot2::ggplot(qq, ggplot2::aes(expected, observed)) +
  ggplot2::geom_abline(slope = 1, intercept = 0, linewidth = 0.3, colour = "#6B6B6B") +
  ggplot2::geom_point(size = 0.3, colour = "#2A629A", alpha = 0.7) +
  ggplot2::labs(
    x = expression(Expected ~ -log[10](italic(p))),
    y = expression(Observed ~ -log[10](italic(p)))
  ) +
  theme_viz()

if (isTRUE(show_qq)) {
  p <- cowplot::plot_grid(p_man, p_qq, ncol = 2, rel_widths = c(2.4, 1), align = "h")
} else {
  p <- p_man
}

pv_save(p, "figure", width_mm = 183, height_mm = 78)
message("wrote preview.png")
