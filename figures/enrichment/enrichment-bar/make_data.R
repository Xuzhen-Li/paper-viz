# Enrichment statistics with a noisy link between fold and p. No hard cut.
# Run from this directory.
set.seed(517)
term <- c(
  "inflammatory response", "cell cycle", "apoptotic process", "immune response", "DNA repair",
  "kinase activity", "DNA binding", "receptor binding", "oxidoreductase activity", "TF binding",
  "nucleus", "extracellular region", "mitochondrion", "plasma membrane", "cytosol"
)
ontology <- rep(c("BP", "MF", "CC"), each = 5)
latent <- stats::rnorm(15, 1.1, 0.45)
fold <- pmax(1.15, exp(latent) + stats::rnorm(15, 0, 0.25))
count <- pmax(6, round(8 + 18 * fold + stats::rnorm(15, 0, 8)))
p <- pmax(1e-8, 10^(-0.35 * fold + stats::rnorm(15, -0.4, 0.35)))
utils::write.csv(
  data.frame(term = term, ontology = ontology, fold = fold, p = p, count = count),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
