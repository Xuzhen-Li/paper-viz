# Six plant genomes: TE class fractions across 30 Kimura divergence bins.
set.seed(212)

genomes <- c("180 Mb", "320 Mb", "480 Mb", "750 Mb", "1.2 Gb", "2.3 Gb")
totals <- c(0.18, 0.31, 0.42, 0.55, 0.67, 0.76)
shares <- rbind(
  c(0.28, 0.26, 0.15, 0.23, 0.08),
  c(0.34, 0.24, 0.13, 0.21, 0.08),
  c(0.41, 0.22, 0.12, 0.18, 0.07),
  c(0.49, 0.18, 0.10, 0.17, 0.06),
  c(0.56, 0.16, 0.09, 0.14, 0.05),
  c(0.63, 0.14, 0.08, 0.11, 0.04)
)
classes <- c("Gypsy", "Copia", "LINE", "TIR", "Helitron")
div <- 0:29

shapes <- list(
  Gypsy = 0.55 * stats::dnorm(div, 4.5, 1.7) + 0.45 * stats::dnorm(div, 15, 4.2),
  Copia = 0.70 * stats::dnorm(div, 2.5, 1.4) + 0.30 * stats::dnorm(div, 11, 3.5),
  LINE = stats::dnorm(div, 18, 6),
  TIR = 0.40 * stats::dnorm(div, 6, 2.2) + 0.60 * stats::dnorm(div, 13, 4),
  Helitron = stats::dnorm(div, 10, 5)
)
shapes <- lapply(shapes, function(z) z / sum(z))

rows <- list()
for (i in seq_along(genomes)) {
  for (j in seq_along(classes)) {
    frac <- totals[i] * shares[i, j] * shapes[[classes[j]]]
    frac <- frac * (1 + stats::rnorm(length(div), 0, 0.04))
    frac <- pmax(0, frac)
    frac <- frac / sum(frac) * totals[i] * shares[i, j]
    rows[[length(rows) + 1L]] <- data.frame(
      genome = genomes[i],
      te_class = classes[j],
      divergence = div,
      fraction = round(frac, 6)
    )
  }
}
df <- do.call(rbind, rows)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
