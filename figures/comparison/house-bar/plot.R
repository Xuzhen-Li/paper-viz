# House-style bar chart: mean ± s.d., raw points, values on bars, P vs control above.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

control <- "Control"
gene_label <- "VvSWEET10"
y_max <- 6
wrap_width <- 9
point_size <- 1.6   # raw-data overlay on bars (style-contract.md, points): size 1.6, alpha 0.8

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
lv <- unique(df$treatment)
df$x <- match(df$treatment, lv)
cols <- stats::setNames(c(pv_palette("house_grey")[["ci"]], pv_palette("house_warm")[2:4])[seq_along(lv)], lv)

sm <- do.call(rbind, lapply(lv, function(t) {
  y <- df$expression[df$treatment == t]
  data.frame(treatment = t, x = match(t, lv), m = mean(y), sd = stats::sd(y), n = length(y))
}))
# value labels: white on dark fills, black on light fills
lum <- colSums(grDevices::col2rgb(cols[sm$treatment]) * c(0.299, 0.587, 0.114)) / 255
sm$txt <- ifelse(lum < 0.6, "white", "black")
others <- setdiff(lv, control)
pv <- vapply(others, function(t) stats::t.test(df$expression[df$treatment == t],
                                               df$expression[df$treatment == control])$p.value, numeric(1))
br <- data.frame(x1 = match(others, lv), lab = vapply(pv, pv_fmt_p, character(1)))
br$y <- 0
prev <- -Inf
for (i in seq_len(nrow(br))) {  # each bracket clears every bar it spans and the bracket below it
  br$y[i] <- max(max(df$expression[df$x <= br$x1[i]]) + 0.35, prev + 0.6)
  prev <- br$y[i]
}
y_max <- max(y_max, ceiling(max(br$y) + 0.6))

set.seed(11)
df$xj <- df$x + stats::runif(nrow(df), -0.14, 0.14)

p <- ggplot(sm, aes(x, m)) +
  geom_col(aes(fill = treatment), width = 0.66, colour = NA) +
  geom_errorbar(aes(ymin = m - sd, ymax = m + sd), width = 0.22, linewidth = pv_house_lw("errorbar")) +
  geom_point(data = df, aes(xj, expression), shape = HOUSE_POINT$shape, fill = "white", colour = "black",
             size = point_size, stroke = HOUSE_POINT$stroke, alpha = 0.8) +
  geom_text(aes(y = 0.16, label = sprintf("%.2f", m), colour = txt), vjust = 0, size = pv_pt2size(7),
            fontface = "bold") +
  scale_colour_identity() +
  geom_segment(data = br, aes(x = 1, xend = x1, y = y, yend = y), linewidth = pv_house_lw("ref")) +
  geom_segment(data = br, aes(x = 1, xend = 1, y = y, yend = y - 0.12), linewidth = pv_house_lw("ref")) +
  geom_segment(data = br, aes(x = x1, xend = x1, y = y, yend = y - 0.12), linewidth = pv_house_lw("ref")) +
  geom_text(data = br, aes(x = x1 - 0.05, y = y + 0.06, label = lab), hjust = 1, vjust = 0, parse = TRUE,
            size = pv_pt2size(7)) +
  annotate("text", x = 0.6, y = y_max * 0.975, label = gene_label, fontface = "italic", hjust = 0, vjust = 1,
           size = pv_pt2size(8)) +
  annotate("text", x = 0.6, y = y_max * 0.875, label = sprintf("Mean \u00b1 s.d., n = %d", max(sm$n)),
           hjust = 0, vjust = 1, size = pv_pt2size(6), colour = pv_palette("house_grey")[["mid"]]) +
  scale_fill_manual(values = cols) +
  scale_x_continuous(breaks = seq_along(lv), labels = function(b) vapply(lv[b], function(s)
    paste(strwrap(s, wrap_width), collapse = "\n"), character(1)), limits = c(0.5, length(lv) + 0.5),
    expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, y_max), breaks = 0:y_max, expand = c(0, 0)) +
  labs(x = NULL, y = "Relative expression") +
  theme_house() +
  theme(axis.text.x = element_text(lineheight = 0.85))

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
