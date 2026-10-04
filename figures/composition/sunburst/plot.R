# Two-level sunburst from geom_rect + coord_polar. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

# --- adjustable ---
label_min_share <- 0.075
hole <- 0.62
# ------------------

mix_hex <- function(hex, target, amount) {
  amount <- max(0, min(1, amount))
  a <- grDevices::col2rgb(hex)[, 1]
  b <- grDevices::col2rgb(target)[, 1]
  out <- (1 - amount) * a + amount * b
  grDevices::rgb(out[1], out[2], out[3], maxColorValue = 255)
}

luminance <- function(hex) {
  rgb <- grDevices::col2rgb(hex) / 255
  0.2126 * rgb[1, ] + 0.7152 * rgb[2, ] + 0.0722 * rgb[3, ]
}

child_shades <- function(hex, n) {
  # Lighter tints of the parent only. Never mix toward black.
  amts <- if (n <= 1) 0.25 else seq(0.25, 0.60, length.out = n)
  vapply(amts, function(a) mix_hex(hex, "#FFFFFF", a), character(1))
}

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
parent_sum <- tapply(df$value, df$parent, sum)
parent_levels <- names(sort(parent_sum, decreasing = TRUE))
pal <- stats::setNames(pv_palette("categorical", length(parent_levels)), parent_levels)

inner_r <- c(hole, hole + 0.86)
outer_r <- c(inner_r[2], inner_r[2] + 0.94)
outer_lim <- outer_r[2] + 0.28
text_pt <- 6.2

inner_rows <- vector("list", length(parent_levels))
outer_rows <- vector("list", length(parent_levels))
cursor <- 0
for (par in parent_levels) {
  sub <- df[df$parent == par, , drop = FALSE]
  sub <- sub[order(sub$value, decreasing = TRUE), , drop = FALSE]
  shades <- child_shades(pal[[par]], nrow(sub))
  cend <- cursor + cumsum(sub$value)
  cstart <- cend - sub$value
  inner_rows[[par]] <- data.frame(
    xmin = inner_r[1], xmax = inner_r[2],
    ymin = cursor, ymax = cursor + sum(sub$value),
    fill_hex = pal[[par]],
    label = par,
    lab_r = inner_r[1] + 0.62 * diff(inner_r),
    stringsAsFactors = FALSE
  )
  outer_rows[[par]] <- data.frame(
    xmin = outer_r[1], xmax = outer_r[2],
    ymin = cstart, ymax = cend,
    fill_hex = shades,
    label = sub$child,
    lab_r = outer_r[1] + 0.52 * diff(outer_r),
    stringsAsFactors = FALSE
  )
  cursor <- cursor + sum(sub$value)
}
rings <- rbind(do.call(rbind, inner_rows), do.call(rbind, outer_rows))
total <- cursor
stopifnot(all(rings$xmax > rings$xmin), all(rings$ymax > rings$ymin))
stopifnot(abs(sum(rings$ymax[rings$label %in% parent_levels] - rings$ymin[rings$label %in% parent_levels]) - total) < 1e-6)

rings$share <- (rings$ymax - rings$ymin) / total
rings$mid <- (rings$ymin + rings$ymax) / 2
# Conservative radius of the polar panel on an 85 mm canvas.
panel_r_mm <- 34
char_mm <- 0.52 * pv_text_mm(text_pt)
rings$arc_mm <- 2 * pi * (rings$lab_r / outer_lim) * panel_r_mm * rings$share
rings$show <- rings$share >= label_min_share &
  nchar(rings$label) * char_mm <= rings$arc_mm * 0.90
deg <- 360 * rings$mid / total
angle <- -deg
angle <- ifelse(deg > 90 & deg < 270, angle + 180, angle)
rings$angle <- angle
rings$lab_col <- ifelse(luminance(rings$fill_hex) >= 0.60, "black", "white")
labs <- rings[rings$show, , drop = FALSE]
# Genera that do not fit in the wedge: short radial leader, name outside the ring.
outside <- rings[rings$xmin == outer_r[1] & !rings$show, , drop = FALSE]
outside <- outside[order(outside$mid), , drop = FALSE]
if (nrow(outside)) {
  outside$lab_r <- outer_r[2] + 0.20
  if (nrow(outside) > 1) {
    ddeg <- c(999, diff(outside$mid) / total * 360)
    level <- 0
    for (i in seq_len(nrow(outside))) {
      if (ddeg[i] < 30) level <- (level + 1) %% 3 else level <- 0
      outside$lab_r[i] <- outside$lab_r[i] + level * 0.48
    }
  }
  deg_out <- (360 * outside$mid / total) %% 360
  outside$hjust <- ifelse(deg_out < 180, 0, 1)
  outer_lim <- max(outer_lim, max(outside$lab_r) + 0.08)
}

p <- ggplot2::ggplot(rings) +
  ggplot2::geom_rect(
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill_hex),
    colour = "white", linewidth = 0.25
  ) +
  ggplot2::scale_fill_identity() +
  ggplot2::geom_text(
    data = labs,
    ggplot2::aes(x = lab_r, y = mid, label = label, angle = angle, colour = lab_col),
    size = pv_text_mm(text_pt),
    hjust = 0.5, vjust = 0.5
  ) +
  ggplot2::scale_colour_identity(guide = "none") +
  ggplot2::coord_polar(theta = "y", start = 0, direction = 1, clip = "off") +
  ggplot2::scale_x_continuous(limits = c(0, outer_lim), expand = c(0, 0)) +
  theme_viz(base_size = 7) +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank(),
    legend.position = "none",
    panel.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.margin = ggplot2::margin(8, 10, 8, 10, "mm")
  )

if (nrow(outside)) {
  p <- p +
    ggplot2::geom_segment(
      data = outside,
      ggplot2::aes(x = xmax, xend = lab_r - 0.05, y = mid, yend = mid),
      colour = "grey30", linewidth = 0.25, inherit.aes = FALSE
    ) +
    ggplot2::geom_text(
      data = outside,
      ggplot2::aes(x = lab_r, y = mid, label = label, hjust = hjust),
      size = 2.1, colour = "black", vjust = 0.5, inherit.aes = FALSE
    )
}

pv_save(p, "figure", width_mm = 100, height_mm = 100)
message("wrote preview.png")
