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

# ggplot2 4 maps a polar radius into c(0, 0.4), so the disk only
# covers 80% of the panel. Stretch it to the panel edge.
coord_sunburst <- function(start = 0, direction = 1, clip = "off") {
  ggplot2::ggproto(
    "CoordSunburst",
    ggplot2::CoordPolar,
    theta = "y",
    r = "x",
    start = start,
    direction = direction,
    clip = clip,
    transform = function(self, data, panel_params) {
      if (inherits(data$x, "AsIs") && inherits(data$y, "AsIs")) {
        return(data)
      }
      theta <- data$y
      radius <- data$x
      tr <- panel_params$theta.range
      rr <- panel_params$r.range
      span <- diff(tr)
      if (!is.finite(span) || span == 0) span <- 1
      rspan <- diff(rr)
      if (!is.finite(rspan) || rspan == 0) rspan <- 1
      ang <- ((theta - tr[1]) / span) * (2 * pi)
      ang <- ((self$start + ang) %% (2 * pi)) * self$direction
      rad <- (radius - rr[1]) / rspan * 0.5
      data$x <- rad * sin(ang) + 0.5
      data$y <- rad * cos(ang) + 0.5
      data
    }
  )
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

# Thick rings, limit tight to the outer edge, so the disk fills the square.
inner_r <- c(hole, hole + 0.70)
outer_r <- c(inner_r[2], inner_r[2] + 1.18)
outer_lim <- outer_r[2] + 0.02
text_pt <- 6
canvas_mm <- 100
margin_mm <- 1.2

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
    lab_r = inner_r[1] + 0.50 * diff(inner_r),
    stringsAsFactors = FALSE
  )
  outer_rows[[par]] <- data.frame(
    xmin = outer_r[1], xmax = outer_r[2],
    ymin = cstart, ymax = cend,
    fill_hex = shades,
    label = sub$child,
    lab_r = outer_r[1] + 0.50 * diff(outer_r),
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
# Square canvas minus a thin margin. The circle is inscribed in that panel.
panel_r_mm <- (canvas_mm - 2 * margin_mm) / 2
char_mm <- 0.50 * pv_text_mm(text_pt)
glyph_mm <- pv_text_mm(text_pt)
rings$arc_mm <- 2 * pi * (rings$lab_r / outer_lim) * panel_r_mm * rings$share
rings$band_mm <- (rings$xmax - rings$xmin) / outer_lim * panel_r_mm
rings$text_mm <- nchar(rings$label) * char_mm
# Inner end of a label centered on lab_r, in data units, then as an arc.
half_r <- (rings$text_mm / panel_r_mm) * outer_lim / 2
radial_inner <- pmax(rings$xmin, rings$lab_r - half_r)
rings$arc_inner_mm <- 2 * pi * (radial_inner / outer_lim) * panel_r_mm * rings$share
deg <- (360 * rings$mid / total) %% 360
tang <- -deg
tang <- ifelse(deg > 90 & deg < 270, tang + 180, tang)
tan_ok <- rings$share >= label_min_share & rings$text_mm <= rings$arc_mm * 0.90
rad_ok <- rings$text_mm <= rings$band_mm * 0.88 & glyph_mm <= rings$arc_inner_mm * 0.82
rings$mode <- ifelse(tan_ok, "tangential", ifelse(rad_ok, "radial", "none"))
rings$angle <- ifelse(rings$mode == "radial", tang + 90, tang)
# 0° reads left-to-right, 90° bottom-to-top. Flip the upside-down half.
page <- rings$angle %% 360
rings$angle <- rings$angle + ifelse(page > 90 & page <= 270, 180, 0)
rings$lab_col <- ifelse(luminance(rings$fill_hex) >= 0.60, "black", "white")
labs <- rings[rings$mode != "none", , drop = FALSE]
miss <- rings$label[rings$mode == "none"]
if (length(miss)) message("unlabeled: ", paste(miss, collapse = ", "))

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
    family = viz_sans_family(),
    hjust = 0.5, vjust = 0.5
  ) +
  ggplot2::scale_colour_identity(guide = "none") +
  coord_sunburst(start = 0, direction = 1, clip = "off") +
  ggplot2::scale_x_continuous(limits = c(0, outer_lim), expand = c(0, 0)) +
  ggplot2::scale_y_continuous(expand = c(0, 0)) +
  theme_viz(base_size = 7) +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.ticks.length = ggplot2::unit(0, "mm"),
    axis.line = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank(),
    legend.position = "none",
    aspect.ratio = 1,
    panel.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.margin = ggplot2::margin(margin_mm, margin_mm, margin_mm, margin_mm, "mm")
  )

pv_save(p, "figure", width_mm = canvas_mm, height_mm = canvas_mm)
message("wrote preview.png")
