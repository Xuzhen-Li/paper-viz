# Simulated differential-expression table. Run from this directory.
set.seed(1)
n <- 800
gene <- sprintf("Gene%04d", seq_len(n))
lfc <- rnorm(n, 0, 1.2)
pval <- 10^(-runif(n, 0.1, 6))
utils::write.csv(
  data.frame(gene = gene, log2_fold_change = lfc, pvalue = pval),
  "data.csv", row.names = FALSE
)
message("wrote data.csv")
