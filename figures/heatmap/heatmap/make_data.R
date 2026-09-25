# Simulated gene-by-sample matrix in long form. Run from this directory.
set.seed(5)
genes <- paste0("Gene", sprintf("%02d", 1:20))
samples <- paste0("S", 1:8)
group <- rep(c("A", "B"), each = 4)
mat <- matrix(rnorm(20 * 8), nrow = 20, dimnames = list(genes, samples))
mat[1:6, 1:4] <- mat[1:6, 1:4] + 2
df <- data.frame(
  gene = rep(genes, times = length(samples)),
  sample = rep(samples, each = length(genes)),
  value = as.vector(mat),
  group = rep(group, each = length(genes)),
  stringsAsFactors = FALSE
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
