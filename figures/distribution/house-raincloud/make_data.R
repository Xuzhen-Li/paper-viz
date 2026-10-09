# Simulated genome-wide heterozygosity per accession in three grape groups. Run from this directory.
set.seed(20261011)
d <- rbind(
  data.frame(group = "Wild", heterozygosity_pct = stats::rnorm(58, 22.5, 3.6)),
  data.frame(group = "Wine", heterozygosity_pct = stats::rnorm(84, 31.0, 3.1)),
  data.frame(group = "Table", heterozygosity_pct = stats::rnorm(71, 31.6, 3.4))
)
d$heterozygosity_pct <- round(d$heterozygosity_pct, 2)
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
