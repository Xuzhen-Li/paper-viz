# Dot-plot enrichment. Ratio, count, and p stay continuous.
# Run from this directory.
set.seed(518)
term <- c(
  "response to cytokine", "leukocyte activation", "mitotic cell cycle", "DNA replication",
  "regulation of apoptosis", "vesicle transport", "protein phosphorylation",
  "RNA splicing", "chromatin organization", "oxidative phosphorylation",
  "GTPase activity", "transcription regulator activity", "calcium ion binding",
  "structural constituent of ribosome", "ATP binding", "endoplasmic reticulum",
  "Golgi apparatus", "lysosome", "cell junction", "cytosolic ribosome"
)
ontology <- c(rep("BP", 7), rep("MF", 6), rep("CC", 7))
ratio <- stats::rbeta(20, 1.6, 6)
ratio <- pmax(0.03, pmin(0.42, ratio + stats::rnorm(20, 0, 0.02)))
count <- pmax(5, round(12 + 140 * ratio + stats::rnorm(20, 0, 6)))
p <- pmax(1e-7, 10^stats::rnorm(20, mean = -1.6 - 6 * ratio, sd = 0.45))
utils::write.csv(
  data.frame(term = term, ontology = ontology, ratio = ratio, count = count, p = p),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
