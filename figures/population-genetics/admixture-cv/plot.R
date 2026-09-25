# ADMIXTURE CV error. Reads data.csv.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
show_errorbar <- TRUE
mark_best <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
best_k <- df$k[which.min(df$cv_mean)]
pal <- pv_palette("categorical", 4)

p <- ggplot2::ggplot(df, ggplot2::aes(k, cv_mean)) +
  ggplot2::geom_line(linewidth = 0.45, colour = pal[1]) +
  ggplot2::geom_point(size = 1.6, colour = pal[1])
if (isTRUE(show_errorbar)) {
  p <- p + ggplot2::geom_errorbar(
    ggplot2::aes(ymin = cv_mean - cv_sd, ymax = cv_mean + cv_sd),
    width = 0.18, linewidth = 0.3, colour = pal[1]
  )
}
if (isTRUE(mark_best)) {
  p <- p +
    ggplot2::geom_point(
      data = df[df$k == best_k, ],
      size = 2.4, colour = pal[4]
    ) +
    ggplot2::annotate(
      "text", x = best_k, y = df$cv_mean[df$k == best_k] - 0.012,
      label = sprintf("lowest CV (K = %d)", best_k),
      size = 2.05, family = viz_sans_family()
    )
}
p <- p +
  ggplot2::scale_x_continuous(breaks = df$k) +
  ggplot2::labs(x = "K", y = "Cross-validation error") +
  theme_viz()

pv_save(p, "figure", width_mm = 120, height_mm = 80)
message("wrote preview.png")
