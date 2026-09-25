# Gene expression across time, one shape per cluster, with gene-level noise.
# Run from this directory.
set.seed(65)
times <- c(0, 6, 12, 24, 48, 72)
clusters <- c("rise", "fall", "early-peak", "late-peak", "dip", "step")
shapes <- list(
  rise = function(t) -0.6 + 1.5 * t,
  fall = function(t) 1.1 - 1.6 * t,
  "early-peak" = function(t) 1.5 * exp(-((t - 0.28)^2) / 0.03) - 0.35,
  "late-peak" = function(t) 1.45 * exp(-((t - 0.72)^2) / 0.035) - 0.3,
  dip = function(t) 0.35 - 1.3 * exp(-((t - 0.48)^2) / 0.04),
  step = function(t) -0.55 + 1.35 * stats::plogis((t - 0.42) * 10)
)
genes_per <- 8
rows <- list()
for (cl in clusters) {
  tt <- (times - min(times)) / diff(range(times))
  mu <- shapes[[cl]](tt)
  for (g in seq_len(genes_per)) {
    offset <- stats::rnorm(1, 0, 0.18)
    noise <- stats::rnorm(length(times), 0, 0.16)
    rows[[length(rows) + 1]] <- data.frame(
      gene = sprintf("%s-g%d", cl, g),
      cluster = cl,
      time = times,
      value = round(mu + offset + noise, 3),
      stringsAsFactors = FALSE
    )
  }
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE, quote = FALSE)
message("wrote data.csv")
