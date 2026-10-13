# Waffle (house style). layout is square or parliament. "Other" stays light grey.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

layout <- "square"
part_levels <- c("Clone A", "Clone B", "Clone C", "Clone D", "Other")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$part <- factor(df$part, levels = part_levels)
df <- df[order(df$part, df$cell), , drop = FALSE]
df$cell <- seq_len(nrow(df))
named <- setdiff(levels(df$part), "Other")
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
pal <- stats::setNames(unname(hp[seq_along(named)]), named)
if ("Other" %in% levels(df$part)) pal["Other"] <- grey[["light"]]
footnote <- "Simulated data;\nnot biological results"

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
  pt <- 1.5
} else {
  ncol_grid <- 10L
  df$x <- (df$cell - 1L) %% ncol_grid
  df$y <- (df$cell - 1L) %/% ncol_grid
  pt <- NA
}

p <- ggplot(df, aes(x, y, fill = part))
p <- if (layout == "parliament") {
  p + geom_point(shape = 21, size = pt, colour = "white", stroke = 0.2)
} else {
  p + geom_tile(width = 0.88, height = 0.88, colour = NA)
}
p <- p +
  scale_fill_manual(values = pal, name = NULL) +
  scale_x_continuous(breaks = NULL) + scale_y_continuous(breaks = NULL) +
  coord_equal(clip = "off") +
  labs(x = NULL, y = NULL, caption = footnote) +
  guides(fill = guide_legend(ncol = 1, keywidth = unit(2.2, "mm"), keyheight = unit(2.2, "mm"))) +
  theme_house() +
  theme(axis.line = element_blank(), panel.border = element_blank(),
        legend.position = "right", legend.text = element_text(size = 7),
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1, "mm"),
        legend.key.spacing.y = unit(0.3, "mm"),
        plot.margin = margin(1, 1, 1, 1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
