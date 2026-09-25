# Grouped boxplot with two Wilcoxon brackets. Reads data.csv only.
source("../../../styles/r/theme_viz.R")

comparisons <- list(c("A", "B"), c("B", "C"))
df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$group <- factor(df$group, levels = unique(df$group))
cols <- pv_palette("categorical", nlevels(df$group))

star <- function(p) {
  if (p < 0.001) return("***")
  if (p < 0.01) return("**")
  if (p < 0.05) return("*")
  "ns"
}
ymax <- max(df$value)
step <- diff(range(df$value)) * 0.12
brackets <- lapply(seq_along(comparisons), function(i) {
  pair <- comparisons[[i]]
  x1 <- match(pair[1], levels(df$group))
  x2 <- match(pair[2], levels(df$group))
  p <- stats::wilcox.test(value ~ group, data = df[df$group %in% pair, ])$p.value
  y <- ymax + step * i
  data.frame(x1 = x1, x2 = x2, y = y, label = star(p))
})
br <- do.call(rbind, brackets)

p <- ggplot2::ggplot(df, ggplot2::aes(group, value, fill = group)) +
  ggplot2::geom_boxplot(width = 0.6, outlier.size = 0.6) +
  ggplot2::scale_fill_manual(values = cols, guide = "none") +
  ggplot2::geom_segment(data = br, ggplot2::aes(x = x1, xend = x2, y = y, yend = y), inherit.aes = FALSE, linewidth = 0.3) +
  ggplot2::geom_segment(data = br, ggplot2::aes(x = x1, xend = x1, y = y - step * 0.2, yend = y), inherit.aes = FALSE, linewidth = 0.3) +
  ggplot2::geom_segment(data = br, ggplot2::aes(x = x2, xend = x2, y = y - step * 0.2, yend = y), inherit.aes = FALSE, linewidth = 0.3) +
  ggplot2::geom_text(data = br, ggplot2::aes(x = (x1 + x2) / 2, y = y + step * 0.15, label = label), inherit.aes = FALSE, size = 2.2) +
  ggplot2::labs(x = NULL, y = "Value") +
  ggplot2::coord_cartesian(ylim = c(min(df$value), max(br$y) + step * 0.45)) +
  theme_viz()

pv_save(p, "figure", width_mm = 89, height_mm = 80)
message("wrote preview.png")
