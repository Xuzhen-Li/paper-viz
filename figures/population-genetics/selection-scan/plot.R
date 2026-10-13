# Selection scan, XP-CLR and |iHS| (house style): chromosomes in chrom12 colours, one row per method
# with its name as the row title, dashed cut-off lines. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
methods_show <- c("xpclr", "ihs")
show_threshold <- TRUE
xpclr_q <- 0.995
ihs_cut <- 2

footnote <- "Simulated data;\nnot biological results"
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# label text: the group colour if it reaches 3:1 contrast on white (no new colours)
text_col <- function(hex) {
  v <- grDevices::col2rgb(hex) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  ratio <- 1.05 / (colSums(c(0.2126, 0.7152, 0.0722) * v) + 0.05)
  # below 3:1, use the darker step of the same hue where one exists in the house palettes
  # (orange -> chrom12 orange #E17927, 3.01:1); otherwise #1A1A1A
  darker <- c("#E17D52" = "#E17927", "#F77E12" = "#E17927")
  up <- toupper(hex)
  stats::setNames(ifelse(ratio >= 3, hex, ifelse(up %in% names(darker), darker[up], "#1A1A1A")),
                  names(hex))
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
# fixed house colour per population (same in every B2 figure)
pop_cols <- c("Wild N" = hp[["blue"]], "Wild S" = hp[["sky"]], "Landrace E" = hp[["green"]],
              "Landrace W" = hp[["gold"]], "Cultivar A" = hp[["red"]], "Cultivar B" = hp[["purple"]])

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$method %in% methods_show, ]
df$chr <- factor(df$chr, levels = paste0("chr", 1:5))
df$method <- factor(df$method, levels = methods_show)
chr_max <- tapply(df$pos, df$chr, max)
gap <- 1.6e6
off <- c(0, cumsum(chr_max + gap)[-length(chr_max)])
names(off) <- names(chr_max)
df$x <- df$pos + off[as.character(df$chr)]
mids <- off + chr_max / 2
# one chrom12 colour per chromosome (light and dark alternate along the genome)
chr_pal <- stats::setNames(pv_palette("chrom12", nlevels(df$chr)), levels(df$chr))
df$chr_col <- unname(chr_pal[as.character(df$chr)])

meth_lab <- c(xpclr = "XP-CLR", ihs = "|iHS|")
thr <- data.frame(
  method = factor(c("xpclr", "ihs"), levels = methods_show),
  y = c(stats::quantile(df$score[df$method == "xpclr"], xpclr_q), ihs_cut),
  stringsAsFactors = FALSE
)
thr <- thr[thr$method %in% methods_show, ]

p <- ggplot(df, aes(x, score, colour = chr_col)) +
  geom_point(size = 0.4, shape = 16, show.legend = FALSE) +
  scale_colour_identity() +
  scale_x_continuous(
    breaks = mids, labels = gsub("chr", "", names(mids)),
    expand = expansion(mult = 0.01)
  ) +
  facet_grid(method ~ ., scales = "free_y", switch = "y", labeller = as_labeller(meth_lab)) +
  labs(x = "Chromosome", y = NULL) +
  labs(caption = footnote) +
  theme_house() +
  theme(
    strip.background = element_blank(), strip.placement = "outside",
    strip.text.y.left = element_text(size = 7, angle = 0, hjust = 1),
    panel.spacing.y = unit(2, "mm"),
    plot.margin = margin(2, 1.5, 1, 1, "mm")   # top 2 mm: the top y tick label sits on the panel edge
  ) +
  caption_theme
if (isTRUE(show_threshold)) {
  p <- p + geom_hline(
    data = thr, aes(yintercept = y),
    linetype = "dashed", linewidth = pv_house_lw("ref"), colour = grey[["dark"]], inherit.aes = FALSE
  )
}

pv_save_house(p, "figure", cells = "4x2")
message("wrote preview.png")
