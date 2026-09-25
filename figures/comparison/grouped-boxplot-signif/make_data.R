# Simulated three-group measurements. Run from this directory.
set.seed(4)
utils::write.csv(
  data.frame(
    group = rep(c("A", "B", "C"), each = 30),
    value = c(rnorm(30, 2, 0.6), rnorm(30, 3.2, 0.6), rnorm(30, 2.4, 0.5))
  ),
  "data.csv", row.names = FALSE
)
message("wrote data.csv")
