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
pal <- pv_palette("categorical", length(status_order))
busco_cols <- stats::setNames(pal, status_order)

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
  complete = as.numeric(complete),
  duplicated = as.numeric(wide_s[names(complete), "Complete duplicated"])
)
lab$y <- as.numeric(lab$assembly)
# The number sits 1 point inside the complete block. White on the dark single-copy blue; black once it falls on the light duplicated pink.
lab$lab_col <- ifelse(lab$duplicated >= 4, "black", "white")

df <- df[order(df$assembly, df$status), , drop = FALSE]
df$xmax <- ave(df$percent, df$assembly, FUN = cumsum)
df$xmin <- df$xmax - df$percent
df$y <- as.numeric(df$assembly)

p <- ggplot2::ggplot(df, ggplot2::aes(ymin = y - 0.36, ymax = y + 0.36, xmin = xmin, xmax = xmax, fill = status)) +
  ggplot2::geom_rect(colour = NA) +
  ggplot2::scale_fill_manual(values = busco_cols, name = NULL) +
  ggplot2::scale_x_continuous(
    limits = c(0, 100),
    expand = c(0, 0),
    breaks = seq(0, 100, 25)
  ) +
  ggplot2::scale_y_continuous(
    breaks = seq_along(levels(df$assembly)),
    labels = levels(df$assembly),
    expand = ggplot2::expansion(add = c(0.45, 0.45))
  ) +
  ggplot2::labs(x = "BUSCO genes (%)", y = NULL) +
  theme_viz() +
  ggplot2::theme(
    legend.position = "bottom",
    legend.key.size = ggplot2::unit(3, "mm"),
    legend.text = ggplot2::element_text(size = 7)
  )

if (isTRUE(show_percent)) {
  p <- p + ggplot2::geom_text(
    data = lab,
    ggplot2::aes(x = complete - 1, y = y, label = sprintf("%.1f", complete), colour = lab_col),
    inherit.aes = FALSE,
    hjust = 1, size = 2.2, family = viz_sans_family()
  ) +
    ggplot2::scale_colour_identity(guide = "none")
}

pv_save(p, "figure", width_mm = 160, height_mm = 95)
message("wrote preview.png")
