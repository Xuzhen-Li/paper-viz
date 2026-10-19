# Simulated benchmark: four methods scored on four metrics with different units, five
# cross-validation folds each. Run from this directory.
set.seed(4417)
methods <- c("CNN", "GBM", "SVM", "LR")   # short names: 4 bars share a 1-cell panel
metrics <- data.frame(
  metric = c("Accuracy (%)", "F1 score", "AUROC", "Runtime (min)"),
  direction = c("higher", "higher", "higher", "lower"),
  sd = c(1.1, 0.012, 0.010, 1.6),
  stringsAsFactors = FALSE
)
mu <- rbind(
  "Accuracy (%)" = c(88.4, 85.1, 82.7, 79.9),
  "F1 score" = c(0.861, 0.842, 0.803, 0.771),
  "AUROC" = c(0.934, 0.921, 0.887, 0.862),
  "Runtime (min)" = c(14.2, 31.5, 9.8, 6.1)
)
rows <- list()
for (i in seq_len(nrow(metrics))) {
  for (j in seq_along(methods)) {
    v <- mu[metrics$metric[i], j] + stats::rnorm(5, 0, metrics$sd[i])
    rows[[length(rows) + 1L]] <- data.frame(
      method = methods[j], metric = metrics$metric[i], direction = metrics$direction[i],
      fold = 1:5, value = signif(v, 4), stringsAsFactors = FALSE
    )
  }
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
