# Continuous differential-expression draw. Colouring is done in plot.R.
# Run from this directory.
set.seed(1)
n <- 3000
gene <- sprintf("Gene%04d", seq_len(n))
beta <- numeric(n)
de <- sample.int(n, round(0.15 * n))
beta[de] <- rnorm(length(de), 0, 1.5)
log2_fold_change <- beta + rnorm(n, 0, 0.35)
se <- runif(n, 0.35, 0.95)
z <- log2_fold_change / se
pvalue <- 2 * stats::pnorm(-abs(z))
pvalue <- pmax(pvalue, 1e-12)
utils::write.csv(
  data.frame(gene = gene, log2_fold_change = log2_fold_change, pvalue = pvalue),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
