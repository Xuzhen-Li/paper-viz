# Waterfall: opening → signed steps → closing. Reads data.csv only.
# Run from this directory. Pure ggplot2 (no waterfalls package).
source("../../../styles/r/theme_viz.R")

# 可调参数
bar_width <- 0.62
show_connectors <- TRUE
show_value_labels <- TRUE
label_size <- 2.2

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$label <- factor(df$label, levels = unique(df$label))
n <- nrow(df)

ymin <- numeric(n)
ymax <- numeric(n)
fill_key <- character(n)
leave <- numeric(n)
running <- 0
for (i in seq_len(n)) {
  if (df$kind[i] == "total") {
    ymin[i] <- 0
    ymax[i] <- df$value[i]
    running <- df$value[i]
    fill_key[i] <- "Total"
  } else {
    start <- running
    end <- running + df$value[i]
    ymin[i] <- min(start, end)
    ymax[i] <- max(start, end)
    running <- end
    fill_key[i] <- if (df$value[i] >= 0) "Increase" else "Decrease"
  }
  leave[i] <- running
}

plot_df <- data.frame(
  label = df$label,
  xmin = as.numeric(df$label) - bar_width / 2,
  xmax = as.numeric(df$label) + bar_width / 2,
  ymin = ymin,
  ymax = ymax,
  fill_key = factor(fill_key, levels = c("Increase", "Decrease", "Total")),
  stringsAsFactors = FALSE
)

conn <- NULL
if (isTRUE(show_connectors) && n > 1) {
  conn <- data.frame(
    x = as.numeric(df$label[-n]) + bar_width / 2,
    xend = as.numeric(df$label[-1]) - bar_width / 2,
    y = leave[-n],
    yend = leave[-n]
  )
}

pal <- pv_palette("categorical", 4)
cols <- c(Increase = pal[3], Decrease = pal[4], Total = pal[1])

p <- ggplot2::ggplot() +
  ggplot2::geom_rect(
    data = plot_df,
    ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill_key),
    colour = NA
  )
if (!is.null(conn)) {
  p <- p + ggplot2::geom_segment(
    data = conn,
    ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
    linewidth = 0.3,
    colour = "grey55"
  )
}
if (isTRUE(show_value_labels)) {
  lab_df <- plot_df
  lab_df$txt <- ifelse(
    df$kind == "total",
    sprintf("%.1f", df$value),
    sprintf("%+.1f", df$value)
  )
  p <- p + ggplot2::geom_text(
    data = lab_df,
    ggplot2::aes(x = (xmin + xmax) / 2, y = ymax, label = txt),
    vjust = -0.35,
    size = label_size,
    colour = "grey20"
  )
}
p <- p +
  ggplot2::scale_fill_manual(values = cols, name = NULL) +
  ggplot2::scale_x_continuous(
    breaks = as.numeric(df$label),
    labels = as.character(levels(df$label)),
    expand = ggplot2::expansion(mult = c(0.02, 0.02))
  ) +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
  ggplot2::labs(x = NULL, y = "Value") +
  theme_viz() +
  ggplot2::theme(
    legend.position = "top",
    axis.text.x = ggplot2::element_text(angle = 35, hjust = 1)
  )

pv_save(p, "figure", width_mm = 120, height_mm = 85)
message("wrote preview.png")
