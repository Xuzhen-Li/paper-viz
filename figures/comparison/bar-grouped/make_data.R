# Simulated grouped means with noise. Run from this directory.
set.seed(11)
groups <- c("A", "B", "C", "D")
series <- c("Control", "Treatment")
base <- c(
  Control = c(A = 3.1, B = 2.4, C = 4.0, D = 2.9),
  Treatment = c(A = 4.2, B = 3.5, C = 4.8, D = 3.7)
)
# Flatten into long table with noise
rows <- list()
for (s in series) {
  for (g in groups) {
    mu <- if (s == "Control") c(A = 3.1, B = 2.4, C = 4.0, D = 2.9)[[g]] else c(A = 4.2, B = 3.5, C = 4.8, D = 3.7)[[g]]
    rows[[length(rows) + 1L]] <- data.frame(
      group = g,
      series = s,
      value = round(mu + rnorm(1, 0, 0.18), 3),
      stringsAsFactors = FALSE
    )
  }
}
df <- do.call(rbind, rows)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
