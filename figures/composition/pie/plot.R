# Pie or donut (house style): sectors drawn as polygons, share inside each sector, names outside in
# the sector colour (#1A1A1A when that colour is < 3:1 on white), total in the centre or corner.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

donut <- TRUE
show_labels <- TRUE
part_drop <- character(0)
inner_frac <- if (isTRUE(donut)) 0.52 else 0   # inner radius as a fraction of the outer radius

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
if (length(part_drop)) df <- df[!df$part %in% part_drop, , drop = FALSE]
df <- df[order(df$value, decreasing = TRUE), , drop = FALSE]
df$share <- df$value / sum(df$value)
df$end <- cumsum(df$share)
df$start <- df$end - df$share
df$mid <- (df$start + df$end) / 2
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
cols <- stats::setNames(unname(hp[seq_len(nrow(df))]), df$part)
# names sit on white: keep the sector colour when it is >= 3:1 on white, else #1A1A1A
low_contrast <- c(hp[["orange"]], hp[["sky"]], hp[["gold"]])
name_col <- ifelse(cols %in% low_contrast, "#1A1A1A", cols)
# percentages sit on the fill: black on light fills, white on dark fills
pct_col <- ifelse(cols %in% low_contrast, "black", "white")
footnote <- "Simulated data for illustration; not biological results"

rin <- inner_frac   # ring outer radius = 1
to_xy <- function(frac, r) data.frame(x = r * sin(2 * pi * frac), y = r * cos(2 * pi * frac))
ring <- do.call(rbind, lapply(seq_len(nrow(df)), function(i) {
  f <- seq(df$start[i], df$end[i], length.out = max(2, ceiling(df$share[i] * 360)))
  inner <- if (rin > 0) to_xy(rev(f), rin) else data.frame(x = 0, y = 0)
  cbind(rbind(to_xy(f, 1), inner), part = df$part[i])
}))
pct <- cbind(df, to_xy(df$mid, if (rin > 0) (rin + 1) / 2 else 0.62), col = pct_col)
pct <- pct[pct$share >= 0.05, ]   # too thin for a number inside: the name carries the share
nm <- cbind(df, to_xy(df$mid, 1.06), col = name_col)
s_mid <- sin(2 * pi * df$mid)
nm$hj <- ifelse(abs(s_mid) < 0.15, 0.5, ifelse(s_mid > 0, 0, 1))
nm$vj <- ifelse(abs(s_mid) < 0.15, ifelse(cos(2 * pi * df$mid) > 0, 0, 1), 0.5)
# a name centred above or below the ring moves out a little more, clear of its neighbours
top_bot <- abs(s_mid) < 0.15
nm[top_bot, c("x", "y")] <- to_xy(df$mid[top_bot], 1.13)
nm$lab <- ifelse(df$share >= 0.05, df$part, sprintf("%s %.0f%%", df$part, 100 * df$share))

cells <- c(2, 1)
view_y <- c(-1.22, 1.27)
view_x <- c(-1, 1) * diff(view_y) * 86 / 34 / 2   # panel about 86 x 34 mm after margins and footnote
p <- ggplot() +
  geom_polygon(data = ring, aes(x, y, group = part, fill = part), colour = "white", linewidth = pv_house_lw(0.5)) +
  geom_text(data = pct, aes(x, y, label = sprintf("%.0f%%", 100 * share), colour = col))
if (isTRUE(show_labels)) {
  p <- p + geom_text(data = nm, aes(x, y, label = lab, hjust = hj, vjust = vj, colour = col))
}
if (rin > 0) {
  p <- p + annotate("text", x = 0, y = 0, label = sprintf("Total\n%s", format(round(sum(df$value), 1))),
                    size = pv_pt2size(8), lineheight = 0.95)
} else {
  p <- p + annotate("text", x = view_x[1], y = view_y[2], hjust = 0, vjust = 1,
                    label = sprintf("Total %s", format(round(sum(df$value), 1))))
}
p <- p +
  scale_fill_manual(values = cols, guide = "none") +
  scale_colour_identity() +
  scale_x_continuous(breaks = NULL, expand = c(0, 0)) +
  scale_y_continuous(breaks = NULL, expand = c(0, 0)) +
  coord_fixed(xlim = view_x, ylim = view_y, clip = "off") +
  labs(x = NULL, y = NULL, caption = footnote) +
  theme_house() +
  theme(panel.border = element_blank(),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = cells)
message("wrote preview.png")
