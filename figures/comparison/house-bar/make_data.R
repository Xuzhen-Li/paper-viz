# Simulated relative expression of one gene under four treatments, n = 5 each. Run from this directory.
set.seed(20261010)
trt <- c("Control", "Drought", "Heat", "Drought + heat")
mu <- c(1.00, 2.35, 1.62, 3.48)
sdv <- c(0.12, 0.30, 0.22, 0.41)
d <- data.frame(
  treatment = rep(trt, each = 5),
  replicate = rep(1:5, times = 4),
  expression = round(unlist(lapply(1:4, function(i) stats::rnorm(5, mu[i], sdv[i]))), 3)
)
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
