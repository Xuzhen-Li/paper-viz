# Five cell fractions over 30 days. Continuous, autocorrelated, strictly positive.
# Run from this directory.
set.seed(7071)
parts <- c("CD4 T", "CD8 T", "B cell", "NK", "Myeloid")
time <- 1:30
rows <- vector("list", length(parts))
for (i in seq_along(parts)) {
  phase <- (i - 1) * 0.85
  drift <- c(-0.15, 0.22, -0.05, 0.08, 0.18)[i]
  level <- c(22, 14, 18, 9, 27)[i]
  wave <- 4.5 * sin(2 * pi * time / 15 + phase) + 2.2 * sin(2 * pi * time / 7 + phase / 2)
  eps <- as.numeric(stats::filter(rnorm(length(time), 0, 1.15), filter = 0.55, method = "recursive"))
  eps[is.na(eps)] <- 0
  value <- level + drift * time + wave + eps
  rows[[i]] <- data.frame(time = time, part = parts[i], value = round(pmax(value, 0.3), 3))
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
