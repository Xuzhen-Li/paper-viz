# BUSCO stacked bars (house style), sorted by complete (single-copy + duplicated) percent; the four
# classes are named in a key row above the bars. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

# 可调参数 -----------------------------------------------------------------
sort_by_completeness <- TRUE
show_percent <- TRUE

set.seed(1)   # fixed RNG state, so the figure never depends on the session
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
# push end-of-line label positions apart to at least `gap` (data units), keeping their order
spread <- function(y, gap) {
  o <- order(y); z <- y[o]
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  shift <- mean(z) - mean(y[o]); z <- z - shift
  for (i in seq_along(z)[-1]) z[i] <- max(z[i], z[i - 1] + gap)
  y[o] <- z; y
}
df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
status_order <- c("Complete single-copy", "Complete duplicated", "Fragmented", "Missing")
df$status <- factor(df$status, levels = status_order)
busco_cols <- stats::setNames(c(hp[["blue"]], hp[["sky"]], hp[["gold"]], grey[["light"]]), status_order)

wide_s <- tapply(df$percent, list(df$assembly, df$status), sum)
complete <- wide_s[, "Complete single-copy"] + wide_s[, "Complete duplicated"]
ord <- if (isTRUE(sort_by_completeness)) names(sort(complete, decreasing = FALSE)) else rev(sort(unique(df$assembly)))
df$assembly <- factor(df$assembly, levels = ord)

lab <- data.frame(assembly = factor(names(complete), levels = ord), complete = as.numeric(complete),
                  single = as.numeric(wide_s[names(complete), "Complete single-copy"]))
lab$y <- as.numeric(lab$assembly)

df <- df[order(df$assembly, df$status), , drop = FALSE]
df$xmax <- ave(df$percent, df$assembly, FUN = cumsum)
df$xmin <- df$xmax - df$percent
df$y <- as.numeric(df$assembly)
n <- nlevels(df$assembly)

# key row above the bars: swatch + class name, at fixed x positions
key <- data.frame(status = factor(status_order, levels = status_order),
                  x = c(0, 30, 59, 81), lab = c("Single-copy", "Duplicated", "Fragmented", "Missing"))
key_y <- n + 1.05

p <- ggplot(df) +
  geom_rect(aes(ymin = y - 0.38, ymax = y + 0.38, xmin = xmin, xmax = xmax, fill = status), colour = NA) +
  geom_rect(data = key, aes(xmin = x, xmax = x + 2.6, ymin = key_y - 0.3, ymax = key_y + 0.3, fill = status), colour = NA) +
  geom_text(data = key, aes(x = x + 3.6, y = key_y, label = lab), hjust = 0, size = pv_pt2size(7),
            colour = "#1A1A1A", family = house_family()) +
  scale_fill_manual(values = busco_cols, guide = "none") +
  scale_x_continuous(limits = c(0, 100), expand = c(0, 0), breaks = seq(0, 100, 25)) +
  scale_y_continuous(breaks = seq_len(n), labels = levels(df$assembly),
                     expand = expansion(add = c(0.5, 0.3))) +
  coord_cartesian(ylim = c(1, key_y + 0.3), clip = "off") +
  labs(x = "BUSCO genes (%)", y = NULL, caption = footnote) +
  theme_house() + theme(plot.margin = margin(1, 2, 1, 1, "mm")) + caption_theme

if (isTRUE(show_percent)) {
  # complete percent 1 point inside the single-copy block, white on the blue
  p <- p + geom_text(data = lab, aes(x = single - 1, y = y, label = sprintf("%.1f", complete)),
                     hjust = 1, size = pv_pt2size(7), colour = "white", family = house_family())
}

pv_save_house(p, "figure", cells = "2x2", bump = 0)
message("wrote preview.png")
