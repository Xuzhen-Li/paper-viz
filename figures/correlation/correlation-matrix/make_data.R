# Clinical traits from a noisy factor model. Significance is applied in plot.R.
# Run from this directory.
set.seed(512)
vars <- c(
  "BMI", "SBP", "DBP", "Glu", "HbA1c", "LDL", "HDL", "TG",
  "Age", "CRP", "IL6", "ALT", "AST", "eGFR", "UA"
)
p <- length(vars)
n <- 90
lat <- matrix(stats::rnorm(n * 3), n, 3)
load <- matrix(stats::rnorm(p * 3, 0, 0.25), p, 3)
load[1:5, 1] <- load[1:5, 1] + stats::runif(5, 0.45, 0.9)
load[4:9, 2] <- load[4:9, 2] + stats::runif(6, 0.35, 0.8)
load[9:15, 3] <- load[9:15, 3] + stats::runif(7, 0.3, 0.75)
load[7, 2] <- load[7, 2] - 0.7
obs <- lat %*% t(load) + matrix(stats::rnorm(n * p, 0, 0.85), n, p)
colnames(obs) <- vars
r <- stats::cor(obs)
pairs <- utils::combn(vars, 2)
rows <- lapply(seq_len(ncol(pairs)), function(i) {
  a <- pairs[1, i]
  b <- pairs[2, i]
  ct <- stats::cor.test(obs[, a], obs[, b])
  data.frame(var_a = a, var_b = b, r = unname(ct$estimate), p = ct$p.value)
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
