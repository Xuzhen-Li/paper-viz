# Synthetic Kaplan-Meier curves. survminer is not required.
# Run from recipes/r: Rscript km.R
set.seed(3)
source("../../styles/r/theme_viz.R")

n <- 120
arm <- rep(c("Control", "Treatment"), each = n / 2)
time <- rexp(n, rate = ifelse(arm == "Treatment", 0.04, 0.08))
status <- rbinom(n, 1, 0.75)
time <- pmin(time, 40)
status[time >= 40] <- 0
fit <- survival::survfit(survival::Surv(time, status) ~ arm)
sf <- broom::tidy(fit)
sf$arm <- sub("^arm=", "", sf$strata)
sf$surv <- sf$estimate
cols <- palette_viz(2)

p <- ggplot2::ggplot(sf, ggplot2::aes(time, surv, colour = arm)) +
  ggplot2::geom_step(linewidth = 0.6) +
  ggplot2::scale_colour_manual(values = cols[1:2]) +
  ggplot2::scale_y_continuous(limits = c(0, 1)) +
  ggplot2::labs(x = "Time", y = "Survival", colour = NULL, tag = "b") +
  theme_viz()

ggplot2::ggsave("../../gallery/km.png", p, width = 89 / 25.4, height = 70 / 25.4, dpi = 300)
message("wrote ../../gallery/km.png")
