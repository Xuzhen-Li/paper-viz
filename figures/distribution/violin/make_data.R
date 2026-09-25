# Two treatments measured in two tissues. Run from this directory.
set.seed(41)
n_per <- 45
grid <- expand.grid(
  i = seq_len(n_per),
  group = c("Control", "Treated"),
  facet = c("Adjacent", "Tumor"),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
shift <- ifelse(grid$group == "Treated", 0.95, 0) + ifelse(grid$facet == "Tumor", 0.55, 0)
skew <- rgamma(nrow(grid), shape = 2.2, rate = 2.4) - 0.9
grid$value <- shift + rnorm(nrow(grid), 0, 0.48) + 0.28 * skew
grid$sample <- sprintf("S%03d", seq_len(nrow(grid)))
utils::write.csv(
  grid[, c("sample", "group", "facet", "value")],
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
