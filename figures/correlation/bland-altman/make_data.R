# Paired assay readings for Bland–Altman. Run from this directory.
set.seed(82)
n <- 160
# True latent value + method-specific bias and heteroscedastic noise
truth <- stats::rnorm(n, mean = 48, sd = 11)
method_a <- truth + stats::rnorm(n, 0.15, 2.4)
method_b <- truth - 1.1 + stats::rnorm(n, 0, 2.1 + 0.02 * abs(truth - 48))
# Mild outliers for visual realism
idx <- sample.int(n, 4)
method_a[idx] <- method_a[idx] + stats::rnorm(4, 0, 5.5)
utils::write.csv(
  data.frame(
    method_a = round(method_a, 3),
    method_b = round(method_b, 3)
  ),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv rows=", n)
