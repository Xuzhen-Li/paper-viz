# Simulated weed seed-bank projections (house example). Fixed seed; writes data.csv.
set.seed(5)
yr <- seq(2000, 2100, 10)
fut <- yr >= 2020
s <- function(x0, x1, rate, mid) x1 + (x0 - x1) / (1 + exp((yr - mid) / rate))
hist_total <- c(38.6, 46.9, 49.8)
none   <- 49.8 + 9 * (1 - exp(-(yr - 2020) / 12)) + c(rep(0, 3), rnorm(8, 0, 0.7))
target <- c(hist_total, s(52, 12, 7, 2042)[-(1:3)])
target[4] <- 46.8
ambit  <- c(hist_total, pmax(s(56, 0.8, 6, 2034)[-(1:3)], 0.8))
ambit[4] <- 36.9
annual <- target * seq(0.80, 0.55, length.out = length(yr)) + c(rnorm(length(yr), 0, 0.4))
current <- ifelse(yr >= 2030, 46.8 - 6.5 * (1 - exp(-(yr - 2030) / 20)) + rnorm(length(yr), 0, 0.4), NA)
d <- rbind(
  data.frame(year = yr[!fut | yr == 2020], series = "history", value = hist_total),
  data.frame(year = yr[fut], series = "no_control", value = round(none[fut], 2)),
  data.frame(year = yr[yr >= 2030], series = "current_practice", value = round(current[yr >= 2030], 2)),
  data.frame(year = yr, series = "target", value = round(target, 2)),
  data.frame(year = yr[fut], series = "ambitious", value = round(ambit[fut], 2)),
  data.frame(year = yr, series = "annual_share_of_target", value = round(annual, 2))
)
write.csv(d, "data.csv", row.names = FALSE)
