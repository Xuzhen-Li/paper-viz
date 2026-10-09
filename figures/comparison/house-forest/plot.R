# House-style forest plot: two seasons per locus, 95% CI, open points when the CI spans 0.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

ci_mult <- 1.96
n_accessions <- 278
dodge <- 0.17
x_limits <- c(-0.65, 1.1)
# point estimate (style-contract.md, points): HOUSE_POINT with size 3.2 (STYLE size 3–3.5)
est_point <- utils::modifyList(HOUSE_POINT, list(size = 3.2))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
pal <- pv_palette("house")
seasons <- sort(unique(as.character(df$season)))
scol <- stats::setNames(c(pal[["purple"]], pal[["orange"]])[seq_along(seasons)], seasons)
loci <- unique(df$locus)
df$season <- as.character(df$season)
df$lo <- df$estimate - ci_mult * df$se
df$hi <- df$estimate + ci_mult * df$se
df$sig <- df$lo > 0 | df$hi < 0
df$y <- (length(loci) + 1 - match(df$locus, loci)) + ifelse(df$season == seasons[1], dodge, -dodge)
df$fillc <- ifelse(df$sig, df$season, "ns")
minus <- function(x) gsub("-", "\u2212", x)
top <- length(loci) + 1

p <- ggplot(df, aes(estimate, y, colour = season)) +
  geom_vline(xintercept = 0, linetype = "22", linewidth = pv_house_lw("ref"),
             colour = pv_palette("house_grey")[["mid"]]) +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = pv_house_lw(0.9)) +
  geom_point(aes(fill = fillc), shape = est_point$shape, size = est_point$size,
             stroke = est_point$stroke) +
  geom_text(aes(x = hi + 0.03, label = minus(sprintf("%+.2f", estimate))), hjust = 0,
            size = pv_pt2size(6)) +
  annotate("text", x = x_limits[1] + 0.03, y = top + 0.05, label = seasons[1], colour = scol[[1]],
           hjust = 0, size = pv_pt2size(7), fontface = "bold") +
  annotate("text", x = x_limits[1] + 0.32, y = top + 0.05, label = seasons[2], colour = scol[[2]],
           hjust = 0, size = pv_pt2size(7), fontface = "bold") +
  annotate("text", x = x_limits[2] - 0.03, y = top + 0.45,
           label = sprintf("italic(N)*' = %d accessions'", n_accessions), parse = TRUE,
           hjust = 1, vjust = 1, size = pv_pt2size(6), colour = pv_palette("house_grey")[["mid"]]) +
  annotate("text", x = x_limits[2] - 0.03, y = top + 0.03, label = "open: 95% CI spans 0",
           hjust = 1, vjust = 1, size = pv_pt2size(6), colour = pv_palette("house_grey")[["mid"]]) +
  scale_colour_manual(values = scol) +
  scale_fill_manual(values = c(scol, ns = "white")) +
  scale_y_continuous(breaks = rev(seq_along(loci)), labels = loci, limits = c(0.45, top + 0.6),
                     expand = c(0, 0)) +
  scale_x_continuous(limits = x_limits, breaks = seq(-0.5, 1, 0.5), expand = c(0, 0),
                     labels = function(x) minus(format(x, nsmall = 1))) +
  labs(x = "Effect on berry weight (g)", y = NULL) +
  theme_house() +
  theme(axis.text.y = element_text(face = "italic"),
        plot.margin = margin(1.6, 2.6, 0.9, 0.4, "mm"))

pv_save_house(p, "figure", cells = "2x2")
message("wrote preview.png")
