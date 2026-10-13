# SV size densities on a log10 axis (house style), coloured by SV type, type names written at the
# density peaks; median size per type as the in-panel stat. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
log_x <- TRUE
sv_keep <- c("DEL", "INS", "DUP", "INV")

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
df <- df[df$sv_type %in% sv_keep, , drop = FALSE]
df$sv_type <- factor(df$sv_type, levels = sv_keep)
cols <- stats::setNames(c(hp[["blue"]], hp[["orange"]], hp[["green"]], hp[["purple"]])[seq_along(sv_keep)], sv_keep)
lab_cols <- text_col(cols)

fmt_bp <- function(b) ifelse(b >= 1e6, sprintf("%.1f Mb", b / 1e6), ifelse(b >= 1e3, sprintf("%.1f kb", b / 1e3),
                                                                          sprintf("%d bp", round(b))))
# density peak of each type on the plotted scale -> name position
tr <- if (isTRUE(log_x)) log10 else identity
itr <- if (isTRUE(log_x)) function(v) 10^v else identity
pk <- do.call(rbind, lapply(split(df$size_bp, df$sv_type), function(v) {
  d <- stats::density(tr(v))
  data.frame(x = itr(d$x[which.max(d$y)]), y = max(d$y), med = stats::median(v))
}))
pk$sv_type <- rownames(pk)
pk$lab <- sprintf("%s\n%s", pk$sv_type, fmt_bp(pk$med))

p <- ggplot(df, aes(size_bp, colour = sv_type, fill = sv_type)) +
  geom_density(alpha = 0.2, linewidth = pv_house_lw("main")) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_fill_manual(values = cols, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.3))) +
  labs(x = "SV size (label: median)", y = "Density", caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 2, 1, 1, "mm")) + caption_theme
# name side per type (0.5 above the peak, 1 to the left, 0 to the right), so neighbouring peaks do not collide
lab_hjust <- c(DEL = 0.5, INS = 1, DUP = 0, INV = 0.5)
pk$hj <- ifelse(pk$sv_type %in% names(lab_hjust), lab_hjust[pk$sv_type], 0.5)
pk$xl <- if (isTRUE(log_x)) pk$x * 10^(0.18 * (0.5 - pk$hj) * 2) else pk$x
if (!isTRUE(log_x)) {
  # linear axis: the peaks crowd at the left, so the names go in a column at the top right
  pk$xl <- Inf; pk$hj <- 1.05
  pk$y <- max(pk$y) * (1.25 - 0.17 * (seq_len(nrow(pk)) - 1))
  pk$lab <- sprintf("%s  %s", pk$sv_type, fmt_bp(pk$med))
}
for (i in seq_len(nrow(pk))) {
  p <- p + annotate("text", x = pk$xl[i], y = pk$y[i], label = pk$lab[i], hjust = pk$hj[i],
                    vjust = if (pk$hj[i] == 0.5) -0.25 else if (pk$hj[i] > 1) 1 else 0.2, lineheight = 0.9,
                    colour = lab_cols[[pk$sv_type[i]]], size = pv_pt2size(7), family = house_family())
}
if (isTRUE(log_x)) {
  p <- p + scale_x_log10(breaks = c(100, 1e3, 1e4, 1e5, 1e6, 1e7),
                         labels = c("100 bp", "1 kb", "10 kb", "100 kb", "1 Mb", "10 Mb"))
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
