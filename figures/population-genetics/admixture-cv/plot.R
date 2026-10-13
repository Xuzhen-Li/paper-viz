# ADMIXTURE cross-validation error by K (house style). The lowest K is marked from the data.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
show_errorbar <- TRUE
mark_best <- TRUE
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

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
best_k <- df$k[which.min(df$cv_mean)]
line_col <- grey[["dark"]]

p <- ggplot(df, aes(k, cv_mean))
if (isTRUE(show_errorbar)) {
  p <- p + geom_errorbar(aes(ymin = cv_mean - cv_sd, ymax = cv_mean + cv_sd),
                         width = 0.25, linewidth = pv_house_lw("minor"), colour = line_col)
}
p <- p +
  geom_line(linewidth = pv_house_lw("main"), colour = line_col) +
  geom_point(shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
             colour = HOUSE_POINT$colour, fill = grey[["ci"]])
if (isTRUE(mark_best)) {
  b <- df[df$k == best_k, , drop = FALSE]
  p <- p +
    geom_point(data = b, shape = HOUSE_POINT$shape, size = HOUSE_POINT$size, stroke = HOUSE_POINT$stroke,
               colour = HOUSE_POINT$colour, fill = hp[["red"]]) +
    annotate("text", x = best_k, y = b$cv_mean - 0.06 * diff(range(df$cv_mean)), vjust = 1,
             label = sprintf("Lowest CV (K = %d)", best_k),
             colour = text_col(hp["red"]), size = pv_pt2size(7), family = house_family())
}
p <- p +
  scale_x_continuous(breaks = df$k) +
  scale_y_continuous(expand = expansion(mult = c(0.16, 0.05))) +
  labs(x = "K", y = "Cross-validation error", caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 1.5, 1, 1, "mm")) + caption_theme

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
