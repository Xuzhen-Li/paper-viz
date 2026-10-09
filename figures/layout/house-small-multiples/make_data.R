# Simulated annual temperature anomalies (°C) for eight regions, 1985–2024. Run from this directory.
set.seed(20261016)
regions <- c("Arctic", "Boreal", "Temperate", "Mediterranean", "Arid", "Monsoon", "Tropical", "Southern Ocean")
trend <- c(0.62, 0.41, 0.29, 0.34, 0.22, 0.12, 0.18, -0.04)   # °C per decade
noise <- c(0.45, 0.32, 0.22, 0.24, 0.20, 0.18, 0.14, 0.12)
years <- 1985:2024
d <- do.call(rbind, lapply(seq_along(regions), function(i) {
  e <- as.numeric(stats::arima.sim(list(ar = 0.3), length(years), sd = noise[i]))
  data.frame(region = regions[i], year = years,
             anomaly_c = round(trend[i] * (years - 2005) / 10 + e, 3))
}))
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
