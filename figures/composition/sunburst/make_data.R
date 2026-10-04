# Two-level composition: three phyla, four genera each. Run from this directory.
set.seed(909)
base <- data.frame(
  parent = c(
    rep("Firmicutes", 4),
    rep("Bacteroidota", 4),
    rep("Proteobacteria", 4)
  ),
  child = c(
    "Lactobacillus", "Faecalibacterium", "Clostridium", "Roseburia",
    "Bacteroides", "Prevotella", "Alistipes", "Parabacteroides",
    "Escherichia", "Pseudomonas", "Klebsiella", "Enterobacter"
  ),
  value = c(18.5, 12.4, 6.8, 4.2, 16.2, 9.6, 4.1, 2.6, 11.2, 6.5, 3.8, 2.4),
  stringsAsFactors = FALSE
)
base$value <- round(base$value * stats::runif(nrow(base), 0.96, 1.04), 2)
utils::write.csv(base, "data.csv", row.names = FALSE)
message("wrote data.csv")
