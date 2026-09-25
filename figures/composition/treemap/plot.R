# Treemap laid out with alternating slices. treemapify returns empty tiles on this ggplot2.
source("../../../styles/r/theme_viz.R")

show_subgroup <- TRUE
show_labels <- TRUE
group_levels <- c("Up", "Down")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
pal <- stats::setNames(pv_palette("categorical", 8)[c(4, 3)], group_levels)

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
rd$lab <- ifelse(isTRUE(show_labels) & rd$w > 0.09 & rd$hgt > 0.07, rd$tile, "")

p <- ggplot2::ggplot(rd) +
  ggplot2::geom_rect(
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = group),
    colour = "white", linewidth = 0.3
  ) +
  ggplot2::geom_text(
    ggplot2::aes(x = cx, y = cy, label = lab),
    size = 1.9, colour = "white"
  ) +
  ggplot2::scale_fill_manual(values = pal, name = NULL) +
  ggplot2::coord_equal(expand = FALSE) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    legend.position = "bottom",
    axis.text = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

pv_save(p, "figure", width_mm = 160, height_mm = 100)
message("wrote preview.png")
