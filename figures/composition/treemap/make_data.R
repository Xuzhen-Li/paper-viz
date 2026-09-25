# Two groups, twelve tiles each. Areas follow a lognormal, not a neat grid.
# Run from this directory.
set.seed(7074)
up <- c("MYC", "CCND1", "EGFR", "CDK4", "VEGFA", "MKI67", "TOP2A", "BIRC5", "AURKA", "FOXM1", "E2F1", "CCNB1")
down <- c("TP53", "PTEN", "CDKN1A", "BAX", "FAS", "CASP3", "BTG2", "GADD45A", "CDKN2A", "RB1", "BBC3", "TNFRSF10B")
value_up <- stats::rlnorm(length(up), meanlog = log(c(42, 28, 22, 18, 16, 14, 11, 9, 8, 7, 6, 5)), sdlog = 0.18)
value_dn <- stats::rlnorm(length(down), meanlog = log(c(36, 24, 19, 15, 13, 11, 9, 8, 6.5, 5.5, 4.5, 3.8)), sdlog = 0.18)
df <- data.frame(
  group = rep(c("Up", "Down"), each = 12),
  tile = c(up, down),
  value = round(c(value_up, value_dn), 2)
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
