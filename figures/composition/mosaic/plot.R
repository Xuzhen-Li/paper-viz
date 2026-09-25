# Mosaic / spine plot. Width is the row margin; height is the share within the row.
source("../../../styles/r/theme_viz.R")

show_labels <- TRUE
row_levels <- c("Stage I", "Stage II", "Stage III", "Stage IV")
col_levels <- c("Response", "Stable", "Progression")

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
pal <- stats::setNames(pv_palette("categorical", 8)[c(3, 1, 4)], col_levels)
mids <- x_left + widths / 2

p <- ggplot2::ggplot(rd) +
  ggplot2::geom_rect(
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = col),
    colour = "white", linewidth = 0.3
  ) +
  ggplot2::scale_fill_manual(values = pal, name = "Outcome") +
  ggplot2::scale_x_continuous(breaks = mids, labels = row_levels, expand = c(0.01, 0.01)) +
  ggplot2::scale_y_continuous(labels = scales::label_percent(), expand = c(0, 0)) +
  ggplot2::labs(x = "Stage", y = "Share within stage") +
  theme_viz() +
  ggplot2::theme(
    legend.position = "right",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA)
  )

if (isTRUE(show_labels)) {
  p <- p + ggplot2::geom_text(
    ggplot2::aes(x = cx, y = cy, label = lab),
    size = 2.1, colour = "white"
  )
}

pv_save(p, "figure", width_mm = 150, height_mm = 88)
message("wrote preview.png")
