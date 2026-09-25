# Kaplan-Meier step curves. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_viz.R")

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
fit <- survival::survfit(survival::Surv(time, status) ~ arm, data = df)
sf <- summary(fit)
arm <- sub("^arm=", "", sf$strata)
plot_df <- data.frame(time = sf$time, surv = sf$surv, arm = arm, n_censor = sf$n.censor)
cens <- plot_df[plot_df$n_censor > 0, , drop = FALSE]
pal <- pv_palette("categorical", 2)
km_cols <- setNames(pal[1:2], unique(plot_df$arm))

p <- ggplot2::ggplot(plot_df, ggplot2::aes(time, surv, colour = arm)) +
  ggplot2::geom_step(linewidth = 0.6) +
  ggplot2::geom_point(
    data = cens,
    ggplot2::aes(time, surv),
    shape = "|",
    size = 2.4,
    show.legend = FALSE
  ) +
  ggplot2::scale_colour_manual(values = km_cols) +
  ggplot2::scale_y_continuous(limits = c(0, 1)) +
  ggplot2::labs(x = "Time", y = "Survival probability", colour = NULL) +
  theme_viz()

pv_save(p, "figure", width_mm = 89, height_mm = 70)
message("wrote preview.png")
