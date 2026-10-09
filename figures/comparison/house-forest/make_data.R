# Simulated locus effects on berry weight (estimate ± s.e.) in two seasons. Run from this directory.
set.seed(20261012)
loci <- c("VvSWEET10", "VvAGL11", "VvMYBA1", "VvGAI1", "VvCEB1", "VvIAA19", "VvNAC26", "VvERF045")
eff <- c(0.42, 0.61, 0.08, -0.35, 0.27, -0.12, 0.19, -0.05)
d <- do.call(rbind, lapply(c(2024, 2025), function(s) data.frame(
  season = s, locus = loci,
  estimate = round(eff + stats::rnorm(8, 0, 0.06), 3),
  se = round(stats::runif(8, 0.05, 0.11), 3))))
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
