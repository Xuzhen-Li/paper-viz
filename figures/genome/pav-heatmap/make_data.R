# 20 genomes x 80 gene families. Presence is stochastic around latent classes.
set.seed(303)

genomes <- sprintf("G%02d", 1:20)
clade <- rep(c("C1", "C2", "C3", "C4"), each = 5)
families <- sprintf("F%03d", 1:80)
# latent compartment, not a cut on a plotted continuous score
comp <- sample(c("core", "shell", "cloud"), 80, replace = TRUE, prob = c(0.28, 0.42, 0.30))
base_p <- c(core = 0.90, shell = 0.48, cloud = 0.14)
# a subset of shell/cloud families enriched in one clade
owner <- sample(c("C1", "C2", "C3", "C4", "shared"), 80, replace = TRUE, prob = c(0.12, 0.12, 0.12, 0.12, 0.52))
owner[comp == "core"] <- "shared"

rows <- list()
for (j in seq_along(families)) {
  for (i in seq_along(genomes)) {
    p <- base_p[[comp[j]]]
    if (owner[j] != "shared") {
      p <- if (clade[i] == owner[j]) min(0.97, p + 0.40) else max(0.02, p * 0.35)
    }
    p <- min(0.99, max(0.01, p + rnorm(1, 0, 0.03)))
    rows[[length(rows) + 1L]] <- data.frame(
      genome = genomes[i],
      family = families[j],
      present = stats::rbinom(1, 1, p),
      compartment = comp[j],
      stringsAsFactors = FALSE
    )
  }
}
out <- do.call(rbind, rows)
utils::write.csv(out, "data.csv", row.names = FALSE)
