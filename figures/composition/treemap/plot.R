# Treemap (house style) laid out with alternating slices; tile area is proportional to value.
# Tile names in white (both fills are >= 3:1 against white). Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

show_subgroup <- TRUE
show_labels <- TRUE
group_levels <- c("Up", "Down")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
pal <- stats::setNames(unname(hp[c("red", "blue")]), group_levels)
footnote <- "Simulated data for illustration; not biological results"

slice_layout <- function(values, x, y, w, h, horizontal) {
  n <- length(values)
  out <- data.frame(xmin = numeric(n), xmax = numeric(n), ymin = numeric(n), ymax = numeric(n))
  place <- function(i, x, y, w, h, horizontal) {
    if (!length(i)) return()
    if (length(i) == 1L) {
      out$xmin[i] <<- x
      out$xmax[i] <<- x + w
      out$ymin[i] <<- y
      out$ymax[i] <<- y + h
      return()
    }
    share <- values[i[1]] / sum(values[i])
    if (horizontal) {
      hh <- h * share
      out$xmin[i[1]] <<- x
      out$xmax[i[1]] <<- x + w
      out$ymin[i[1]] <<- y
      out$ymax[i[1]] <<- y + hh
      place(i[-1], x, y + hh, w, h - hh, FALSE)
    } else {
      ww <- w * share
      out$xmin[i[1]] <<- x
      out$xmax[i[1]] <<- x + ww
      out$ymin[i[1]] <<- y
      out$ymax[i[1]] <<- y + h
      place(i[-1], x + ww, y, w - ww, h, TRUE)
    }
  }
  ord <- order(values, decreasing = TRUE)
  place(ord, x, y, w, h, horizontal)
  out
}

gap <- if (isTRUE(show_subgroup)) 0.018 else 0
totals <- sapply(group_levels, function(g) sum(df$value[df$group == g]))
span <- 1 - gap
widths <- as.numeric(totals) / sum(totals) * span
x0 <- c(0, widths[1] + gap)
rects <- vector("list", length(group_levels))
for (i in seq_along(group_levels)) {
  sub <- df[df$group == group_levels[i], , drop = FALSE]
  lay <- slice_layout(sub$value, x0[i], 0, widths[i], 1, FALSE)
  sub$xmin <- lay$xmin
  sub$xmax <- lay$xmax
  sub$ymin <- lay$ymin
  sub$ymax <- lay$ymax
  rects[[i]] <- sub
}
rd <- do.call(rbind, rects)
pad <- 0.003
rd$xmin <- rd$xmin + pad
rd$xmax <- rd$xmax - pad
rd$ymin <- rd$ymin + pad
rd$ymax <- rd$ymax - pad
rd$cx <- (rd$xmin + rd$xmax) / 2
rd$cy <- (rd$ymin + rd$ymax) / 2
rd$w <- rd$xmax - rd$xmin
rd$hgt <- rd$ymax - rd$ymin
# fit test in mm on the ~87 x 35 mm panel: horizontal first, else rotated for tall narrow tiles
w_mm <- rd$w * 87; h_mm <- rd$hgt * 35; txt_mm <- nchar(rd$tile) * 1.5 + 1.2
fit_h <- txt_mm < w_mm & h_mm > 3.5
fit_v <- !fit_h & txt_mm < h_mm & w_mm > 3.5
rd$lab <- ifelse(isTRUE(show_labels) & (fit_h | fit_v), rd$tile, "")
rd$angle <- ifelse(fit_v, 90, 0)

p <- ggplot(rd) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = group),
            colour = "white", linewidth = 0.3) +
  geom_text(aes(x = cx, y = cy, label = lab, angle = angle), size = pv_pt2size(7), colour = "white",
            family = house_family()) +
  scale_fill_manual(values = pal, name = NULL) +
  scale_x_continuous(breaks = NULL, expand = c(0, 0)) +
  scale_y_continuous(breaks = NULL, expand = c(0, 0)) +
  labs(x = NULL, y = NULL, caption = footnote) +
  theme_house() +
  theme(legend.position = "top", legend.justification = "left", legend.text = element_text(size = 7),
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1, "mm"),
        axis.line = element_blank(), panel.border = element_blank(),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
