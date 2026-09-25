# Two overlapping measurement groups. Run from this directory.
set.seed(44)
n <- 400
control <- rnorm(n, 0, 1)
case <- 0.85 + rnorm(n, 0, 1.05) + ifelse(runif(n) < 0.08, rnorm(n, 1.4, 0.4), 0)
utils::write.csv(
  data.frame(
    group = rep(c("Control", "Case"), each = n),
    value = c(control, case)
  ),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
