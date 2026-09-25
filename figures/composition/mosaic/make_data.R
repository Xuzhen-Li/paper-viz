# Stage by outcome counts. Association shifts with stage; Poisson noise, no hard cut.
# Run from this directory.
set.seed(7076)
rows <- c("Stage I", "Stage II", "Stage III", "Stage IV")
cols <- c("Response", "Stable", "Progression")
base <- matrix(c(
  46, 18, 7,
  31, 26, 13,
  16, 24, 22,
  7, 14, 33
), nrow = 4, byrow = TRUE)
n <- base + matrix(stats::rpois(length(base), lambda = 1.6), nrow = 4)
utils::write.csv(
  data.frame(row = rows[row(n)], col = cols[col(n)], n = as.integer(n)),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
