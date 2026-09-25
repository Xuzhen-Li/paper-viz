# Effective population size, log-log axes. Reads data.csv.
source("../../../styles/r/theme_viz.R")

# 可调参数 -----------------------------------------------------------------
# psmc: classic range (unreliable below ~10 ka). smcpp: includes more recent time.
model <- "psmc"
show_ribbon <- TRUE
pops_show <- c("Wild N", "Cultivar A")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df <- df[df$pop %in% pops_show, ]
df$pop <- factor(df$pop, levels = pops_show)
pal <- pv_palette("categorical", 2)
names(pal) <- pops_show
xlim <- if (model == "smcpp") c(2e3, 5e5) else c(1e4, 1e6)

p <- ggplot2::ggplot(df, ggplot2::aes(years_ago, ne, colour = pop, fill = pop))
if (isTRUE(show_ribbon)) {
  p <- p + ggplot2::geom_ribbon(
    ggplot2::aes(ymin = ne_low, ymax = ne_high),
    alpha = 0.18, colour = NA, show.legend = FALSE
  )
}
p <- p +
  ggplot2::geom_line(linewidth = 0.55) +
  ggplot2::scale_x_log10(
    breaks = c(1e3, 1e4, 1e5, 1e6),
    labels = c(expression(10^3), expression(10^4), expression(10^5), expression(10^6))
  ) +
  ggplot2::scale_y_log10(
    breaks = c(1e3, 1e4, 1e5, 1e6),
    labels = c(expression(10^3), expression(10^4), expression(10^5), expression(10^6))
  ) +
  ggplot2::scale_colour_manual(values = pal, name = "Population") +
  ggplot2::scale_fill_manual(values = pal, guide = "none") +
  ggplot2::coord_cartesian(xlim = xlim) +
  ggplot2::labs(x = "Years ago", y = expression(italic(N)[e])) +
  theme_viz() +
  ggplot2::theme(legend.key = ggplot2::element_blank())

pv_save(p, "figure", width_mm = 150, height_mm = 95)
message("wrote preview.png")
