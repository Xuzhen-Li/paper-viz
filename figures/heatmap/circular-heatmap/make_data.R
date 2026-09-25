# Feature-by-sample matrix with soft module blocks. Scaling and colour happen in plot.R.
# Run from this directory.
set.seed(66)
n_row <- 30
n_col <- 12
modules <- rep(c("M1", "M2", "M3"), each = 10)
rows <- sprintf("F%02d", seq_len(n_row))
cols <- sprintf("S%02d", seq_len(n_col))
value <- matrix(stats::rnorm(n_row * n_col, 0, 0.85), n_row, n_col)
value[1:10, 1:4] <- value[1:10, 1:4] + 1.15
value[11:20, 5:8] <- value[11:20, 5:8] + 1.05
value[21:30, 9:12] <- value[21:30, 9:12] + 1.2
value[1:10, 9:12] <- value[1:10, 9:12] - 0.55
long <- data.frame(
  row = rep(rows, times = n_col),
  col = rep(cols, each = n_row),
  module = rep(modules, times = n_col),
  value = round(as.vector(value), 3),
  stringsAsFactors = FALSE
)
utils::write.csv(long, "data.csv", row.names = FALSE, quote = FALSE)
message("wrote data.csv")
