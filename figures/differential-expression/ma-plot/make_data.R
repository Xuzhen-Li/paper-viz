# Continuous mean-abundance and log2 fold change. Significance is assigned in plot.R.
# Run from this directory.
set.seed(64)
n <- 8000
gene <- paste0("G", seq_len(n))
base_mean <- round(10^stats::rnorm(n, 1.75, 0.72), 2)
beta <- numeric(n)
de <- sample.int(n, round(0.08 * n))
beta[de] <- stats::rnorm(length(de), 0, 1.35)
se <- 0.22 + 1.6 / sqrt(pmax(base_mean, 0.5))
log2fc <- round(beta + stats::rnorm(n, 0, se), 3)
z <- log2fc / se
pvalue <- signif(pmax(2 * stats::pnorm(-abs(z)), 1e-12), 3)
utils::write.csv(
  data.frame(gene = gene, base_mean = base_mean, log2fc = log2fc, pvalue = pvalue),
  "data.csv",
  row.names = FALSE,
  quote = FALSE
)
message("wrote data.csv")
