# Diversity window scan, chromosome-alternating colours. Reads data.csv.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
stats_show <- c("fst", "pi", "tajima")
show_threshold <- TRUE
fst_q <- 0.99
pi_q <- 0.05
tajima_line <- -2

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$stat %in% stats_show, ]
df$chr <- factor(df$chr, levels = paste0("chr", 1:5))
df$stat <- factor(df$stat, levels = stats_show)

chr_max <- tapply(df$pos, df$chr, max)
gap <- 1.6e6
off <- c(0, cumsum(chr_max + gap)[-length(chr_max)])
names(off) <- names(chr_max)
df$x <- df$pos + off[as.character(df$chr)]
mids <- off + chr_max / 2
pal <- pv_palette("categorical", 2)
df$chr_col <- ifelse(as.integer(df$chr) %% 2 == 1, pal[1], pal[2])

stat_lab <- c(fst = "Fst", pi = "pi x 10^-3", tajima = "Tajima's D")
thr <- data.frame(
  stat = factor(stats_show, levels = stats_show),
  y = c(
    stats::quantile(df$value[df$stat == "fst"], fst_q),
    stats::quantile(df$value[df$stat == "pi"], pi_q),
    tajima_line
  ),
  stringsAsFactors = FALSE
)
thr <- thr[thr$stat %in% stats_show, ]

p <- ggplot2::ggplot(df, ggplot2::aes(x, value, colour = chr_col)) +
  ggplot2::geom_point(size = 0.35, alpha = 0.85, show.legend = FALSE) +
  ggplot2::scale_colour_identity() +
  ggplot2::scale_x_continuous(
    breaks = mids, labels = gsub("chr", "", names(mids)),
    expand = ggplot2::expansion(mult = 0.01)
  ) +
  ggplot2::facet_grid(stat ~ ., scales = "free_y", labeller = ggplot2::as_labeller(stat_lab)) +
  ggplot2::labs(x = "Chromosome", y = NULL) +
  theme_viz() +
  ggplot2::theme(
    strip.background = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(size = 6.5, hjust = 0),
    panel.spacing.y = ggplot2::unit(1.4, "mm")
  )
if (isTRUE(show_threshold)) {
  p <- p + ggplot2::geom_hline(
    data = thr, ggplot2::aes(yintercept = y),
    linetype = "dashed", linewidth = 0.3, colour = "black", inherit.aes = FALSE
  )
}

pv_save(p, "figure", width_mm = 183, height_mm = 130)
message("wrote preview.png")
