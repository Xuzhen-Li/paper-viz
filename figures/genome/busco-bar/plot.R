# BUSCO stacked bars, sorted by complete (single-copy + duplicated) percent.
source("../../../styles/r/theme_viz.R")

sort_by_completeness <- TRUE
show_percent <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
status_order <- c(
  "Complete single-copy",
  "Complete duplicated",
  "Fragmented",
  "Missing"
)
df$status <- factor(df$status, levels = status_order)
busco_cols <- c(
  "Complete single-copy" = "#56B4E9",
  "Complete duplicated" = "#0072B2",
  "Fragmented" = "#F0E442",
  "Missing" = "#D55E00"
)

wide_s <- tapply(df$percent, list(df$assembly, df$status), sum)
complete <- wide_s[, "Complete single-copy"] + wide_s[, "Complete duplicated"]
ord <- if (isTRUE(sort_by_completeness)) {
  names(sort(complete, decreasing = FALSE))
} else {
  sort(unique(df$assembly))
}
df$assembly <- factor(df$assembly, levels = ord)

lab <- data.frame(
  assembly = factor(names(complete), levels = ord),
  complete = as.numeric(complete)
)
lab$y <- as.numeric(lab$assembly)

df <- df[order(df$assembly, df$status), , drop = FALSE]
df$xmax <- ave(df$percent, df$assembly, FUN = cumsum)
df$xmin <- df$xmax - df$percent
df$y <- as.numeric(df$assembly)

p <- ggplot2::ggplot(df, ggplot2::aes(ymin = y - 0.36, ymax = y + 0.36, xmin = xmin, xmax = xmax, fill = status)) +
  ggplot2::geom_rect(colour = NA) +
  ggplot2::scale_y_continuous(breaks = seq_along(levels(df$assembly)), labels = levels(df$assembly)) +
  ggplot2::scale_fill_manual(values = busco_cols, name = NULL) +
  ggplot2::scale_x_continuous(
    limits = c(0, if (isTRUE(show_percent)) 118 else 100),
    expand = c(0, 0),
    breaks = seq(0, 100, 25)
  ) +
  ggplot2::labs(x = "BUSCO genes (%)", y = NULL) +
  theme_viz() +
  ggplot2::theme(
    legend.key.size = ggplot2::unit(3, "mm"),
    legend.text = ggplot2::element_text(size = 5.5)
  )

if (isTRUE(show_percent)) {
  p <- p + ggplot2::geom_text(
    data = lab,
    ggplot2::aes(x = 101, y = y, label = sprintf("%.1f", complete)),
    inherit.aes = FALSE,
    hjust = 0, size = 1.7, family = viz_sans_family()
  )
}

pv_save(p, "figure", width_mm = 160, height_mm = 95)
message("wrote preview.png")
