# Six assay readouts for three batches. Highlighting is chosen in plot.R.
# Run from this directory.
set.seed(67)
axes <- c("Biomass", "Purity", "Stability", "Cost", "Time", "Yield")
means <- rbind(
  "Batch-A" = c(2.4, 0.86, 0.78, 42, 18, 71),
  "Batch-B" = c(1.6, 0.62, 0.91, 28, 26, 54),
  "Batch-C" = c(3.1, 0.74, 0.55, 55, 14, 83)
)
sd <- c(0.18, 0.035, 0.04, 3.2, 1.6, 3.5)
n <- c(16, 14, 10)
rows <- list()
k <- 0
for (g in rownames(means)) {
  for (i in seq_len(n[match(g, rownames(means))])) {
    k <- k + 1
    val <- means[g, ] + stats::rnorm(length(axes), 0, sd)
    val <- pmax(val, c(0.4, 0.2, 0.2, 8, 6, 20))
    rows[[k]] <- data.frame(
      item = sprintf("I%02d", k),
      group = g,
      axis = axes,
      value = round(val, 3),
      stringsAsFactors = FALSE
    )
  }
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE, quote = FALSE)
message("wrote data.csv")
