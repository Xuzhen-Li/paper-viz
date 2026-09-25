# Simulated time-to-event table. Run from this directory.
set.seed(3)
n <- 120
arm <- rep(c("Control", "Treatment"), each = n / 2)
time <- rexp(n, rate = ifelse(arm == "Treatment", 0.04, 0.08))
status <- rbinom(n, 1, 0.75)
time <- pmin(time, 40)
status[time >= 40] <- 0
utils::write.csv(
  data.frame(id = sprintf("P%03d", seq_len(n)), time = time, status = status, arm = arm),
  "data.csv", row.names = FALSE
)
message("wrote data.csv")
