# 40 samples x 15 genes. Most cells are empty; burden and classes vary.
set.seed(313)

genes <- c(
  "TP53", "KRAS", "PIK3CA", "APC", "PTEN", "BRAF", "EGFR", "RB1",
  "NF1", "ARID1A", "CDKN2A", "SMAD4", "ATM", "FAT1", "KMT2D"
)
samples <- sprintf("S%02d", 1:40)
# sample burden is a soft gamma, not a block of equal counts
burden <- rgamma(40, shape = 2.4, scale = 1.3)
burden <- pmin(0.85, pmax(0.05, burden / 8))
# a few genes are hot
hot <- setNames(c(0.55, 0.42, 0.38, 0.36, 0.28, 0.22, 0.18, 0.16, 0.14, 0.12, 0.12, 0.1, 0.1, 0.08, 0.08), genes)
classes <- c("Missense_Ti", "Missense_Tv", "Nonsense", "Frameshift", "Splice")
class_p <- c(0.42, 0.23, 0.14, 0.13, 0.08)
cohort <- rep(c("A", "B"), each = 20)

rows <- list()
for (j in seq_along(samples)) {
  for (g in genes) {
    if (runif(1) > burden[j] * hot[[g]] * 2.4) next
    vc <- sample(classes, 1, prob = class_p)
    rows[[length(rows) + 1L]] <- data.frame(
      sample = samples[j],
      gene = g,
      variant_class = vc,
      cohort = cohort[j],
      stringsAsFactors = FALSE
    )
  }
}
out <- do.call(rbind, rows)
utils::write.csv(out, "data.csv", row.names = FALSE)
