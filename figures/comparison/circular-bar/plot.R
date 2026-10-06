# Circular bars. Grouped dodge, optional outside labels, optional inner hole.
source("../../../styles/r/theme_viz.R")

show_groups <- TRUE
labels_outside <- TRUE
inner_hole <- 0.42
category_levels <- c(
  "Liver", "Lung", "Colon", "Breast", "Skin", "Kidney", "Brain", "Pancreas",
  "Stomach", "Ovary", "Prostate", "Bladder", "Thyroid", "Uterus", "Esophagus", "Blood"
)
group_levels <- c("Primary", "Metastasis")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
if (!isTRUE(show_groups)) df <- df[df$group == group_levels[1], , drop = FALSE]
df$category <- factor(df$category, levels = category_levels)
df$group <- factor(df$group, levels = intersect(group_levels, unique(df$group)))
pal <- stats::setNames(pv_palette("categorical", nlevels(df$group)), levels(df$group))

ymax <- max(df$value)
pad <- if (inner_hole > 0) inner_hole * ymax else 0
ncat <- nlevels(df$category)
ng <- nlevels(df$group)
df$x <- as.numeric(df$category)
off <- if (ng == 1L) 0 else (as.numeric(df$group) - (ng + 1) / 2) * 0.46
half <- if (ng == 1L) 0.34 else 0.18
df$xmin <- df$x + off - half
df$xmax <- df$x + off + half
df$ymin <- pad
df$ymax <- pad + df$value
# Labels sit just outside the longest bar so the ring can fill the canvas.
bar_outer <- pad + ymax
theta <- (seq_len(ncat) - 0.5) / ncat
lab <- data.frame(
  x = seq_len(ncat),
  y = bar_outer * 1.08,
  label = category_levels,
  angle = 0,
  hjust = ifelse(theta < 0.5, 0, 1)
)

# ggplot2 polar coords draw inside a hard 0.4 radius, so the ring stays small
# no matter how tight scale_y is. Build the same wedges in cartesian space
# (clockwise from 12 o'clock, matching coord_polar) and let them fill the panel.
x_min <- 0.35
x_max <- ncat + 0.65
theta_of <- function(x) (x - x_min) / (x_max - x_min) * 2 * pi
sector_poly <- function(xmin, xmax, r0, r1, id, group, n = 14) {
  ang <- seq(theta_of(xmin), theta_of(xmax), length.out = n)
  data.frame(
    x = c(r1 * sin(ang), r0 * sin(rev(ang))),
    y = c(r1 * cos(ang), r0 * cos(rev(ang))),
    id = id,
    group = group,
    stringsAsFactors = FALSE
  )
}
poly_df <- do.call(rbind, lapply(seq_len(nrow(df)), function(i) {
  sector_poly(df$xmin[i], df$xmax[i], df$ymin[i], df$ymax[i], i, as.character(df$group[i]))
}))
poly_df$group <- factor(poly_df$group, levels = levels(df$group))
lab$theta <- theta_of(lab$x)
lab$lx <- lab$y * sin(lab$theta)
lab$ly <- lab$y * cos(lab$theta)
lim <- bar_outer * 1.12

p <- ggplot2::ggplot() +
  ggplot2::geom_polygon(
    data = poly_df,
    ggplot2::aes(x, y, group = id, fill = group),
    colour = NA
  ) +
  ggplot2::scale_fill_manual(values = pal, name = NULL) +
  ggplot2::annotate(
    "text",
    x = 0,
    y = 0,
    label = sprintf("max %.0f", ymax),
    size = 3.2,
    colour = "black",
    family = viz_sans_family()
  ) +
  ggplot2::coord_equal(
    xlim = c(-lim, lim), ylim = c(-lim, lim),
    expand = FALSE, clip = "off"
  ) +
  theme_viz() +
  ggplot2::theme(
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    panel.border = ggplot2::element_blank(),
    legend.position = "bottom",
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.margin = ggplot2::margin(2, 12, 1, 12, "mm")
  )

if (isTRUE(labels_outside)) {
  p <- p + ggplot2::geom_text(
    data = lab,
    ggplot2::aes(x = lx, y = ly, label = label, hjust = hjust),
    inherit.aes = FALSE,
    size = 2.2,
    colour = "black",
    family = viz_sans_family()
  )
}

pv_save(p, "figure", width_mm = 140, height_mm = 145)
message("wrote preview.png")
