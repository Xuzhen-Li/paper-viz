# Simulated study-level hazard ratios. Run from this directory.
set.seed(2)
studies <- paste0("Study ", LETTERS[1:8])
loghr <- rnorm(8, 0.25, 0.35)
se <- runif(8, 0.12, 0.4)
utils::write.csv(
  data.frame(
    study = studies,
    hr = exp(loghr),
    ci_low = exp(loghr - 1.96 * se),
    ci_high = exp(loghr + 1.96 * se)
  ),
  "data.csv", row.names = FALSE
)
message("wrote data.csv")
