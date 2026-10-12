# House-style Manhattan plot, 12 chromosomes coloured with pv_palette("chrom12") (light/dark pairs, so
# neighbouring chromosomes always alternate light and dark). Bonferroni threshold = 0.05 / N SNPs, with N
# taken from data.csv. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

SIM_NOTE <- "Simulated 12-chromosome genome (rice/tomato-like). Simulated data for illustration; not biological results"
GAP_MB <- 6                                                    # gap between chromosomes on the x axis

d <- utils::read.csv("data.csv")
n_snp <- nrow(d)
thr <- -log10(0.05 / n_snp)                                    # Bonferroni on -log10 scale
chr_ids <- sort(unique(d$chr))
cols <- stats::setNames(pv_palette("chrom12"), chr_ids)
stopifnot(length(chr_ids) == 12, length(cols) == 12)

len <- tapply(d$pos_mb, d$chr, max)
off <- stats::setNames(c(0, cumsum(len + GAP_MB))[seq_along(len)], names(len))
d$x <- d$pos_mb + off[as.character(d$chr)]
mid <- off + len / 2
d$chr_f <- factor(d$chr, levels = chr_ids)
d$sig <- d$neg_log10_p > thr

# lead SNP of each significant chromosome
lead <- do.call(rbind, lapply(split(d[d$sig, ], d$chr[d$sig]), function(s) s[which.max(s$neg_log10_p), ]))
lead$lab <- sprintf("chr%d lead SNP", lead$chr)
stopifnot(nrow(lead) >= 1, all(lead$neg_log10_p > thr))

ymax <- max(d$neg_log10_p) + 0.8                             # just above the highest peak
thr_lab <- sprintf("Bonferroni (0.05/%s)\n%s = %.2f", format(n_snp, big.mark = ","), "-log10 P", thr)
xr <- range(d$x)

p <- ggplot(d, aes(x, neg_log10_p)) +
  geom_point(data = d[!d$sig, ], aes(colour = chr_f), size = 0.55, stroke = 0) +
  geom_point(data = d[d$sig, ], aes(colour = chr_f), size = 0.9, stroke = 0) +
  geom_hline(yintercept = thr, linetype = "22", linewidth = pv_house_lw(0.5),
             colour = pv_palette("house_grey")[["mid"]]) +
  annotate("text", x = xr[1], y = thr + 0.25, label = thr_lab, hjust = 0, vjust = 0, lineheight = 0.95, size = pv_pt2size(7),
           colour = pv_palette("house_grey")[["dark"]]) +
  # lead SNPs: red diamond with black outline, about twice a normal point, so they stand out from the
  # red / brown-red chrom12 colours
  geom_point(data = lead, shape = 23, size = 1.9, stroke = 0.35, fill = pv_palette("house")[["red"]],
             colour = "black") +
  geom_text(data = lead, aes(label = lab), nudge_x = 11, hjust = 0, vjust = 0.5, size = pv_pt2size(7)) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(breaks = mid, labels = chr_ids, expand = c(0.005, 0)) +
  scale_y_continuous(limits = c(0, ymax), breaks = seq(0, 12, 4), expand = c(0, 0)) +
  labs(x = "Chromosome", y = "-log10 P", caption = SIM_NOTE) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 1, colour = pv_palette("house_grey")[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "4x1")
message(sprintf("N SNPs = %d, threshold -log10 P = %.3f, significant = %d", n_snp, thr, sum(d$sig)))
message("wrote preview.png")
