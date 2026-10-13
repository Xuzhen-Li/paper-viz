# Mosaic / spine plot (house style). Width is the row margin; height is the share within the row.
# Counts sit inside tiles that are large enough: white on dark fills, black on light fills.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

show_labels <- TRUE
row_levels <- c("Stage I", "Stage II", "Stage III", "Stage IV")
col_levels <- c("Response", "Stable", "Progression")
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$row <- factor(df$row, levels = row_levels)
df$col <- factor(df$col, levels = col_levels)
gap <- 0.015
rt <- sapply(row_levels, function(r) sum(df$n[df$row == r]))
usable <- 1 - gap * (length(row_levels) - 1)
widths <- as.numeric(rt) / sum(rt) * usable
x_left <- cumsum(c(0, utils::head(widths, -1) + gap))

rects <- vector("list", length(row_levels))
for (i in seq_along(row_levels)) {
  sub <- df[df$row == row_levels[i], , drop = FALSE]
  sub <- sub[order(sub$col), , drop = FALSE]
  h <- sub$n / sum(sub$n)
  y1 <- cumsum(h)
  y0 <- y1 - h
  rects[[i]] <- data.frame(
    row = row_levels[i], col = sub$col, n = sub$n,
    xmin = x_left[i], xmax = x_left[i] + widths[i],
    ymin = y0, ymax = y1
  )
}
rd <- do.call(rbind, rects)
rd$cx <- (rd$xmin + rd$xmax) / 2
rd$cy <- (rd$ymin + rd$ymax) / 2
rd$lab <- ifelse(rd$ymax - rd$ymin > 0.07 & rd$xmax - rd$xmin > 0.08, as.character(rd$n), "")
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
pal <- stats::setNames(unname(hp[c("green", "blue", "red")]), col_levels)
rd$txt <- "white"
mids <- x_left + widths / 2

p <- ggplot(rd) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = col),
            colour = "white", linewidth = 0.3) +
  scale_fill_manual(values = pal, name = NULL) +
  scale_x_continuous(breaks = mids, labels = row_levels, expand = c(0.01, 0.01)) +
  scale_y_continuous(labels = scales::label_percent(), expand = c(0, 0)) +
  labs(x = NULL, y = "Share within stage", caption = footnote) +
  theme_house() +
  theme(legend.position = "right", legend.text = element_text(size = 7),
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1.5, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

if (isTRUE(show_labels)) {
  p <- p + geom_text(aes(x = cx, y = cy, label = lab), size = pv_pt2size(7),
                     colour = rd$txt, family = house_family())
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
