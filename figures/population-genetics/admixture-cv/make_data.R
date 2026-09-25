# ADMIXTURE cross-validation error for K = 1..8.
set.seed(103)
k <- 1:8
cv_mean <- c(0.584, 0.521, 0.486, 0.449, 0.461, 0.470, 0.479, 0.490)
cv_mean <- cv_mean + rnorm(8, 0, 0.0015)
cv_sd <- c(0.006, 0.005, 0.004, 0.0032, 0.0036, 0.0044, 0.0055, 0.0065)
utils::write.csv(
  data.frame(k = k, cv_mean = round(cv_mean, 5), cv_sd = cv_sd),
  "data.csv", row.names = FALSE
)
message("wrote data.csv")
