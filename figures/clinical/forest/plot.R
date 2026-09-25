# Forest plot. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$study <- factor(df$study, levels = rev(df$study))
cols <- pv_palette("categorical", 1)

p <- ggplot2::ggplot(df, ggplot2::aes(hr, study)) +
  ggplot2::geom_vline(xintercept = 1, linetype = "dashed", linewidth = 0.3) +
  ggplot2::geom_errorbarh(ggplot2::aes(xmin = ci_low, xmax = ci_high), height = 0.15, linewidth = 0.4) +
  ggplot2::geom_point(size = 2, colour = cols[1]) +
  ggplot2::scale_x_log10() +
  ggplot2::labs(x = "Hazard ratio", y = NULL) +
  theme_viz()

pv_save(p, "figure", width_mm = 89, height_mm = 80)
message("wrote preview.png")
