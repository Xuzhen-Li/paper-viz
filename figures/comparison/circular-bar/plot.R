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
# Horizontal labels. Tangential angles flip the category that crosses
# 12 o'clock (ggplot2 draws angle in screen degrees; the seam inverts it).
theta <- (seq_len(ncat) - 0.5) / ncat
lab <- data.frame(
  x = seq_len(ncat),
  y = pad + ymax * 1.28,
  label = category_levels,
  angle = 0,
  hjust = ifelse(theta < 0.5, 0, 1)
)

p <- ggplot2::ggplot(df) +
  ggplot2::geom_rect(
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = group),
    colour = NA
  ) +
  ggplot2::scale_fill_manual(values = pal, name = NULL) +
  ggplot2::scale_x_continuous(limits = c(0.35, ncat + 0.65), expand = c(0, 0)) +
  ggplot2::scale_y_continuous(
    limits = c(0, pad + ymax * 1.48),
    expand = c(0, 0)
  ) +
  ggplot2::coord_polar(clip = "off") +
  ggplot2::annotate(
    "text",
    x = ncat / 2,
    y = 0,
    label = sprintf("max %.0f", ymax),
    size = 3.2,
    colour = "black",
    family = viz_sans_family()
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
    plot.margin = ggplot2::margin(7, 10, 2, 10, "mm")
  )

if (isTRUE(labels_outside)) {
  p <- p + ggplot2::geom_text(
    data = lab,
    ggplot2::aes(x = x, y = y, label = label, angle = angle, hjust = hjust),
    inherit.aes = FALSE,
    size = 2.2,
    colour = "black"
  )
}

pv_save(p, "figure", width_mm = 140, height_mm = 145)
message("wrote preview.png")
