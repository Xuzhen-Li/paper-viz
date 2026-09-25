# Pairwise Fst heatmap. Reads data.csv.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_values <- TRUE
pop_order <- c("WN1", "WN2", "WS1", "WS2", "LE1", "LE2", "LW1", "LW2", "CA1", "CA2", "CB1", "CB2")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
# mirror the upper triangle stored in the file
swap <- df[df$pop_a != df$pop_b, ]
swap <- data.frame(pop_a = swap$pop_b, pop_b = swap$pop_a, fst = swap$fst, stringsAsFactors = FALSE)
df <- rbind(df, swap)
df$pop_a <- factor(df$pop_a, levels = pop_order)
df$pop_b <- factor(df$pop_b, levels = rev(pop_order))
df$label <- sprintf("%.2f", df$fst)
df$txt <- ifelse(df$fst >= 0.16, "white", "black")

p <- ggplot2::ggplot(df, ggplot2::aes(pop_a, pop_b, fill = fst)) +
  ggplot2::geom_tile(colour = "white", linewidth = 0.2) +
  ggplot2::scale_fill_gradientn(
    colours = pv_palette("sequential", 5),
    limits = c(0, max(df$fst)),
    name = expression(italic(F)[ST])
  ) +
  ggplot2::scale_colour_identity() +
  ggplot2::coord_fixed() +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_viz() +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, vjust = 1),
    legend.key.height = ggplot2::unit(8, "mm")
  )
if (isTRUE(show_values)) {
  p <- p + ggplot2::geom_text(
    ggplot2::aes(label = label, colour = txt), size = 1.55, show.legend = FALSE
  )
}

pv_save(p, "figure", width_mm = 150, height_mm = 130)
message("wrote preview.png")
