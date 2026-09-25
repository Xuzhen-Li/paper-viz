# Split or faceted violins with optional Wilcoxon brackets.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

# 可调参数
layout <- "split" # split | facet
show_signif <- TRUE
group_levels <- c("Control", "Treated")
facet_levels <- c("Adjacent", "Tumor")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
df$facet <- factor(df$facet, levels = facet_levels)
cols <- setNames(pv_palette("categorical", 2), group_levels)

star <- function(p) {
  if (p < 0.001) return("***")
  if (p < 0.01) return("**")
  if (p < 0.05) return("*")
  "ns"
}

half_poly <- function(values, x0, side, width = 0.34, id = "a") {
  d <- stats::density(values, n = 128, from = min(values) - 0.2, to = max(values) + 0.2)
  y <- d$y / max(d$y) * width
  data.frame(
    x = c(x0, x0 + side * y, x0),
    y = c(d$x[1], d$x, d$x[length(d$x)]),
    id = id,
    stringsAsFactors = FALSE
  )
}

if (layout == "split") {
  polys <- list()
  meds <- list()
  for (i in seq_along(facet_levels)) {
    for (j in seq_along(group_levels)) {
      sub <- df[df$facet == facet_levels[i] & df$group == group_levels[j], ]
      side <- if (j == 1) -1 else 1
      pid <- paste(facet_levels[i], group_levels[j])
      poly <- half_poly(sub$value, i, side, id = pid)
      poly$group <- group_levels[j]
      polys[[pid]] <- poly
      qs <- stats::quantile(sub$value, c(0.25, 0.5, 0.75))
      meds[[pid]] <- data.frame(
        x = i, xend = i + side * 0.16,
        y = qs, group = group_levels[j]
      )
    }
  }
  poly_df <- do.call(rbind, polys)
  med_df <- do.call(rbind, meds)
  br <- NULL
  if (show_signif) {
    br <- do.call(rbind, lapply(seq_along(facet_levels), function(i) {
      sub <- df[df$facet == facet_levels[i], ]
      p <- stats::wilcox.test(value ~ group, data = sub)$p.value
      y <- max(sub$value) + 0.45
      data.frame(x = i - 0.28, xend = i + 0.28, y = y, tick = 0.14, label = star(p))
    }))
  }
  p <- ggplot2::ggplot() +
    ggplot2::geom_polygon(
      data = poly_df,
      ggplot2::aes(x, y, group = id, fill = group),
      colour = NA, alpha = 0.9
    ) +
    ggplot2::geom_segment(
      data = med_df,
      ggplot2::aes(x = x, xend = xend, y = y, yend = y),
      linewidth = 0.3, colour = "grey20"
    ) +
    ggplot2::scale_fill_manual(values = cols, name = NULL) +
    ggplot2::scale_x_continuous(breaks = seq_along(facet_levels), labels = facet_levels) +
    ggplot2::labs(x = NULL, y = "Expression (log2)") +
    theme_viz() +
    ggplot2::theme(legend.position = "top")
  if (!is.null(br)) {
    p <- p +
      ggplot2::geom_segment(
        data = br,
        ggplot2::aes(x = x, xend = xend, y = y, yend = y),
        inherit.aes = FALSE, linewidth = 0.3
      ) +
      ggplot2::geom_segment(
        data = br,
        ggplot2::aes(x = x, xend = x, y = y - tick, yend = y),
        inherit.aes = FALSE, linewidth = 0.3
      ) +
      ggplot2::geom_segment(
        data = br,
        ggplot2::aes(x = xend, xend = xend, y = y - tick, yend = y),
        inherit.aes = FALSE, linewidth = 0.3
      ) +
      ggplot2::geom_text(
        data = br,
        ggplot2::aes(x = (x + xend) / 2, y = y + 0.12, label = label),
        inherit.aes = FALSE, size = 2.2
      ) +
      ggplot2::coord_cartesian(ylim = c(min(df$value) - 0.2, max(br$y) + 0.35))
  }
} else {
  p <- ggplot2::ggplot(df, ggplot2::aes(group, value, fill = group)) +
    ggplot2::geom_violin(scale = "width", trim = FALSE, colour = "grey25", linewidth = 0.25) +
    ggplot2::geom_boxplot(width = 0.12, outlier.shape = NA, fill = "white", linewidth = 0.25) +
    ggplot2::facet_wrap(~facet) +
    ggplot2::scale_fill_manual(values = cols, guide = "none") +
    ggplot2::labs(x = NULL, y = "Expression (log2)") +
    theme_viz()
  if (show_signif) {
    br <- do.call(rbind, lapply(seq_along(facet_levels), function(i) {
      sub <- df[df$facet == facet_levels[i], ]
      pval <- stats::wilcox.test(value ~ group, data = sub)$p.value
      data.frame(
        facet = facet_levels[i],
        x = 1, xend = 2,
        y = max(sub$value) + 0.4,
        label = star(pval)
      )
    }))
    p <- p +
      ggplot2::geom_segment(
        data = br,
        ggplot2::aes(x = x, xend = xend, y = y, yend = y),
        inherit.aes = FALSE, linewidth = 0.3
      ) +
      ggplot2::geom_text(
        data = br,
        ggplot2::aes(x = (x + xend) / 2, y = y + 0.12, label = label),
        inherit.aes = FALSE, size = 2.2
      )
  }
}

pv_save(p, "figure", width_mm = 110, height_mm = 78)
message("wrote preview.png")
