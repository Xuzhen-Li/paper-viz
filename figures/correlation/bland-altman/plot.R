# Bland–Altman: mean vs difference with LoA. Reads data.csv only.
# Run from this directory.
source("../../../styles/r/theme_viz.R")

# 可调参数
loa_mult <- 1.96          # limits of agreement multiplier (SD)
point_size <- 2.2
point_alpha <- 0.75
show_loa_labels <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
ba <- data.frame(
  mean = (df$method_a + df$method_b) / 2,
  diff = df$method_a - df$method_b
)
bias <- mean(ba$diff)
sd_d <- stats::sd(ba$diff)
loa_hi <- bias + loa_mult * sd_d
loa_lo <- bias - loa_mult * sd_d

cols <- pv_palette("categorical", 3)
pt_col <- cols[1]
bias_col <- cols[2]
loa_col <- cols[3]

p <- ggplot2::ggplot(ba, ggplot2::aes(mean, diff)) +
  ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, colour = "grey70") +
  ggplot2::geom_hline(yintercept = bias, linewidth = 0.45, colour = bias_col) +
  ggplot2::geom_hline(
    yintercept = c(loa_lo, loa_hi),
    linewidth = 0.4,
    linetype = "22",
    colour = loa_col
  ) +
  ggplot2::geom_point(size = point_size, alpha = point_alpha, colour = pt_col) +
  ggplot2::labs(
    x = "Mean of methods ((A + B) / 2)",
    y = "Difference (A − B)"
  ) +
  theme_viz(base_size = 7)

if (isTRUE(show_loa_labels)) {
  xr <- range(ba$mean)
  x_lab <- xr[1] + 0.02 * diff(xr)
  lab_df <- data.frame(
    x = x_lab,
    y = c(bias, loa_hi, loa_lo),
    label = c(
      sprintf("Mean = %.2f", bias),
      sprintf("+%.2f SD = %.2f", loa_mult, loa_hi),
      sprintf("−%.2f SD = %.2f", loa_mult, loa_lo)
    )
  )
  p <- p + ggplot2::geom_text(
    data = lab_df,
    ggplot2::aes(x, y, label = label),
    hjust = 0,
    vjust = -0.4,
    size = 2.0,
    colour = "grey25"
  )
}

pv_save(p, "figure", width_mm = 85, height_mm = 60)
message("wrote preview.png")
