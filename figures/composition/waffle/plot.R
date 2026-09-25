# Waffle. layout is square or parliament. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

layout <- "square"
part_levels <- c("Clone A", "Clone B", "Clone C", "Clone D", "Other")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$part <- factor(df$part, levels = part_levels)
df <- df[order(df$part, df$cell), , drop = FALSE]
df$cell <- seq_len(nrow(df))
pal <- stats::setNames(pv_palette("categorical", nlevels(df$part)), levels(df$part))

if (layout == "parliament") {
  n <- nrow(df)
  n_rows <- 5
  w <- seq_len(n_rows)
  n_per <- as.integer(round(w / sum(w) * n))
  while (sum(n_per) > n) {
    n_per[which.max(n_per)] <- n_per[which.max(n_per)] - 1L
  }
  while (sum(n_per) < n) {
    n_per[which.min(n_per)] <- n_per[which.min(n_per)] + 1L
  }
  xs <- numeric(n)
  ys <- numeric(n)
  k <- 1L
  for (r in seq_len(n_rows)) {
    m <- n_per[r]
    rad <- 1.15 + (r - 1) * 0.72
    ang <- if (m == 1L) pi / 2 else seq(pi - 0.06, 0.06, length.out = m)
    xs[k:(k + m - 1L)] <- rad * cos(ang)
    ys[k:(k + m - 1L)] <- rad * sin(ang)
    k <- k + m
  }
  seat <- data.frame(x = xs, y = ys, ord = seq_len(n))
  seat <- seat[order(atan2(seat$y, seat$x), seat$y), , drop = FALSE]
  df$x <- seat$x
  df$y <- seat$y
  pt <- 2.6
} else {
  ncol_grid <- 10L
  df$x <- (df$cell - 1L) %% ncol_grid
  df$y <- (df$cell - 1L) %/% ncol_grid
  pt <- 5.2
}

p <- ggplot2::ggplot(df, ggplot2::aes(x, y, fill = part)) +
  ggplot2::geom_point(shape = 22, size = pt, colour = "white", stroke = 0.35) +
  ggplot2::scale_fill_manual(values = pal, name = NULL) +
  ggplot2::coord_equal(clip = "off") +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    legend.position = "right",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.margin = ggplot2::margin(2, 2, 2, 2, "mm")
  )

h <- if (layout == "parliament") 78 else 112
pv_save(p, "figure", width_mm = 120, height_mm = h)
message("wrote preview.png")
