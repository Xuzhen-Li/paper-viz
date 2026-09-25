# Three noisy time courses. Ribbons are fit in plot.R, not stored as hard bands.
# Run from this directory.
set.seed(514)
x <- 0:49
series <- c("Control", "Low dose", "High dose")
trend <- list(
  Control = 1.15 + 0.012 * x + 0.18 * sin(x / 6),
  "Low dose" = 1.05 + 0.035 * x - 0.00035 * x^2,
  "High dose" = 0.95 + 0.55 * (1 - exp(-x / 12))
)
rows <- lapply(series, function(s) {
  y <- trend[[s]] + stats::rnorm(length(x), 0, 0.08)
  data.frame(x = x, y = y, series = s)
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
