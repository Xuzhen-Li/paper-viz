# Beeswarm with optional Wilcoxon brackets. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

# 可调参数
show_signif <- TRUE
use_facet <- FALSE
group_levels <- c("Ctrl", "Dose1", "Dose2", "Dose3")
comparisons <- list(c("Ctrl", "Dose1"), c("Dose2", "Dose3"))

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = group_levels)
cols <- setNames(pv_palette("categorical", nlevels(df$group)), group_levels)

star <- function(p) {
  if (p < 0.001) return("***")
  if (p < 0.01) return("**")
  if (p < 0.05) return("*")
  "ns"
}

if (use_facet) {
  df$panel <- ifelse(df$group %in% group_levels[1:2], "Low dose", "High dose")
}

p <- ggplot2::ggplot(df, ggplot2::aes(group, value, colour = group)) +
  ggbeeswarm::geom_quasirandom(size = 0.7, width = 0.28, alpha = 0.85) +
  ggplot2::stat_summary(
    fun = stats::median, geom = "crossbar",
    width = 0.45, linewidth = 0.3, colour = "grey15", show.legend = FALSE
  ) +
  ggplot2::scale_colour_manual(values = cols, guide = "none") +
  ggplot2::labs(x = NULL, y = "Response") +
  theme_viz()

if (show_signif && !use_facet) {
  step <- diff(range(df$value)) * 0.14
  br <- do.call(rbind, lapply(seq_along(comparisons), function(i) {
    pair <- comparisons[[i]]
    sub <- df[df$group %in% pair, ]
    pval <- stats::wilcox.test(value ~ group, data = sub)$p.value
    data.frame(
      x = match(pair[1], group_levels),
      xend = match(pair[2], group_levels),
      y = max(df$value) + step * (0.7 + 0.15 * i),
      tick = step * 0.28,
      label = star(pval)
    )
  }))
  p <- p +
    ggplot2::geom_segment(
      data = br, ggplot2::aes(x = x, xend = xend, y = y, yend = y),
      inherit.aes = FALSE, linewidth = 0.3
    ) +
    ggplot2::geom_segment(
      data = br, ggplot2::aes(x = x, xend = x, y = y - tick, yend = y),
      inherit.aes = FALSE, linewidth = 0.3
    ) +
    ggplot2::geom_segment(
      data = br, ggplot2::aes(x = xend, xend = xend, y = y - tick, yend = y),
      inherit.aes = FALSE, linewidth = 0.3
    ) +
    ggplot2::geom_text(
      data = br,
      ggplot2::aes(x = (x + xend) / 2, y = y + step * 0.22, label = label),
      inherit.aes = FALSE, size = 2.2
    ) +
    ggplot2::coord_cartesian(ylim = c(min(df$value) - 0.1, max(br$y) + step * 0.45))
}

if (use_facet) {
  p <- p + ggplot2::facet_wrap(~panel, scales = "free_x")
}

pv_save(p, "figure", width_mm = 100, height_mm = 82)
message("wrote preview.png")
