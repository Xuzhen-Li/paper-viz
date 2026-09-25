# 20 samples, 15 taxa. Counts differ by group so composition and clustering both have structure.
set.seed(307)

samples <- sprintf("S%02d", 1:20)
group <- rep(c("Gut", "Oral", "Skin", "Soil"), each = 5)
taxa <- c(
  "Bacteroides", "Prevotella", "Streptococcus", "Staphylococcus", "Corynebacterium",
  "Lactobacillus", "Faecalibacterium", "Veillonella", "Pseudomonas", "Bacillus",
  "Cutibacterium", "Haemophilus", "Neisseria", "Bifidobacterium", "Rothia"
)
# group-specific mean proportions, then Dirichlet-like noise via gamma
pref <- list(
  Gut = c(18, 8, 2, 1, 1, 6, 14, 2, 1, 1, 1, 2, 1, 10, 2),
  Oral = c(2, 4, 16, 2, 2, 3, 1, 12, 1, 1, 1, 8, 10, 2, 6),
  Skin = c(1, 1, 3, 14, 16, 2, 1, 1, 2, 2, 18, 1, 1, 1, 3),
  Soil = c(2, 2, 2, 3, 4, 2, 2, 1, 14, 16, 3, 1, 1, 2, 2)
)
rows <- list()
for (i in seq_along(samples)) {
  mu <- pref[[group[i]]] * runif(15, 0.7, 1.35)
  counts <- rgamma(15, shape = 2.2, scale = mu)
  counts <- counts + rgamma(15, shape = 1.1, scale = 0.4)
  for (j in seq_along(taxa)) {
    rows[[length(rows) + 1L]] <- data.frame(
      sample = samples[i],
      group = group[i],
      taxon = taxa[j],
      abundance = round(counts[j], 3),
      tip = samples[i],
      stringsAsFactors = FALSE
    )
  }
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
