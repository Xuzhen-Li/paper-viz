# One hundred cells assigned to parts. Run from this directory.
set.seed(7073)
parts <- c("Clone A", "Clone B", "Clone C", "Clone D", "Other")
prob <- c(0.31, 0.24, 0.19, 0.16, 0.10)
prob <- prob * stats::runif(length(prob), 0.88, 1.12)
prob <- prob / sum(prob)
n <- as.integer(stats::rmultinom(1, 100, prob))
# Keep the last part as the remainder so the grid is exactly 100.
n[length(n)] <- 100 - sum(n[-length(n)])
utils::write.csv(
  data.frame(cell = seq_len(100), part = rep(parts, times = n)),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
