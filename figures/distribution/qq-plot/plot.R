# Normal QQ plot. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

point_size <- 1.1
point_alpha <- 0.75
show_ref_line <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
x <- sort(as.numeric(df$value))
n <- length(x)
# Blom plotting positions
prob <- (seq_len(n) - 0.375) / (n + 0.25)
theo <- stats::qnorm(prob)
qq <- data.frame(theoretical = theo, sample = x)
cols <- pv_palette("categorical", 1)

p_plot <- ggplot2::ggplot(qq, ggplot2::aes(theoretical, sample)) +
  ggplot2::geom_point(size = point_size, alpha = point_alpha, colour = cols[[1]]) +
  ggplot2::labs(
    x = "Theoretical quantiles",
    y = "Sample quantiles"
  ) +
  theme_viz()

if (isTRUE(show_ref_line)) {
  qy <- stats::quantile(x, c(0.25, 0.75), names = FALSE, type = 7)
  qx <- stats::qnorm(c(0.25, 0.75))
  slope <- diff(qy) / diff(qx)
  intercept <- qy[1] - slope * qx[1]
  p_plot <- p_plot + ggplot2::geom_abline(
    intercept = intercept, slope = slope,
    linewidth = 0.35, colour = "#6B6B6B"
  )
}

pv_save(p_plot, "figure", width_mm = 89, height_mm = 89)
message("wrote preview.png")
