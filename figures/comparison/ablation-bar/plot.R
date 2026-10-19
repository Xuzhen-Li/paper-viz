# Ablation study bars (house style): one bar per model variant (mean of seeds, s.d. error bar,
# one open point per seed), the full model as a dashed reference line, and the drop from the full
# model written at the right of each ablated row. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
full_name <- "Full model"          # the reference row in column `variant`
metric_label <- "Accuracy (%)"     # x-axis title
x_limits <- c(0, 100)              # bars start at 0; keep 0 unless the metric has no true zero
sort_by_drop <- TRUE               # largest drop right under the full model
show_points <- FALSE               # TRUE: one open circle per seed on each bar
drop_digits <- 1                   # decimals of the drop labels
footnote <- "Simulated data; not real model results.\nBars: mean \u00b1 s.d. of 5 seeds; dashed line: full model"

hp <- pv_palette("house"); grey <- pv_palette("house_grey")
col_full <- hp[["blue"]]           # 5.0:1 on white, so its value label keeps the bar colour
col_ablated <- grey[["ref"]]       # #757575 bars for the variants (4.6:1 on white)
col_ref <- grey[["dark"]]          # #333333 dashed full-model line, darker than the grey bars
col_text <- "#1A1A1A"              # drop labels

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
stopifnot(full_name %in% df$variant)
s <- do.call(rbind, lapply(split(df, df$variant), function(d) {
  data.frame(variant = d$variant[1], mean = mean(d$score), sd = stats::sd(d$score), n = nrow(d))
}))
full_mean <- s$mean[s$variant == full_name]
s$drop <- s$mean - full_mean
lv <- if (isTRUE(sort_by_drop)) {
  c(full_name, s$variant[s$variant != full_name][order(s$drop[s$variant != full_name])])
} else unique(df$variant)
# first level on top
s$variant <- factor(s$variant, levels = rev(lv))
df$variant <- factor(df$variant, levels = rev(lv))
s$is_full <- s$variant == full_name
# drop labels: ASCII hyphen-minus, fixed x right of the reference line and every error bar
s$lab <- ifelse(s$is_full, sprintf(paste0("%.", drop_digits, "f"), s$mean),
                sprintf(paste0("%+.", drop_digits, "f"), s$drop))
s$lab <- gsub("\u2212", "-", s$lab)
lab_x <- max(s$mean + s$sd, full_mean) + 0.025 * diff(x_limits)
s$lab_col <- ifelse(s$is_full, col_full, col_text)
# seed points at fixed vertical offsets (no jitter, so every render is identical)
df <- df[order(df$variant, df$seed), ]
df$k <- stats::ave(df$score, df$variant, FUN = seq_along)
df$n <- stats::ave(df$score, df$variant, FUN = length)
df$y <- as.numeric(df$variant) + (df$k - (df$n + 1) / 2) * 0.1

p <- ggplot(s, aes(mean, variant)) +
  geom_col(aes(fill = is_full), width = 0.7, colour = NA, orientation = "y") +
  geom_vline(xintercept = full_mean, linetype = "22", colour = col_ref,
             linewidth = pv_house_lw("ref"))
if (isTRUE(show_points)) {
  p <- p + geom_point(data = df, aes(score, y), inherit.aes = FALSE, shape = 21, size = 0.8,
                      stroke = 0.3, fill = "white", colour = "black")
}
p <- p +
  geom_errorbar(aes(xmin = mean - sd, xmax = mean + sd), width = 0.22,
                linewidth = pv_house_lw("errorbar"), orientation = "y") +
  geom_text(aes(x = lab_x, label = lab, colour = lab_col), hjust = 0, size = pv_pt2size(7)) +
  scale_fill_manual(values = c(`TRUE` = col_full, `FALSE` = col_ablated), guide = "none") +
  scale_colour_identity() +
  scale_x_continuous(limits = x_limits, expand = c(0, 0), breaks = pretty(x_limits, n = 5)) +
  scale_y_discrete(expand = expansion(add = 0.55)) +
  labs(x = metric_label, y = NULL, caption = footnote) +
  theme_house() +
  theme(axis.ticks.y = element_blank(),
        plot.margin = margin(1.6, 2.4, 0.9, 0.4, "mm"),   # room for the last x tick "100"
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
