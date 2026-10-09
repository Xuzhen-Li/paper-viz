# Simulated days from flowering to véraison in three grape groups. Run from this directory.
set.seed(20261013)
d <- rbind(
  data.frame(group = "Wild", days = stats::rnorm(58, 52, 4.2)),
  data.frame(group = "Wine", days = stats::rnorm(84, 63, 4.6)),
  data.frame(group = "Table", days = stats::rnorm(71, 57.5, 4.0))
)
d$days <- round(d$days, 1)
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
