# Four groups, three samples each, richness at 20 shared depths via vegan::rarefy.
set.seed(311)

groups <- c("Grassland", "Forest", "Wetland", "Cropland")
n_sp <- 180L
# group-level richness and evenness differ; counts are negative binomial
base_mu <- c(Grassland = 1.4, Forest = 2.6, Wetland = 0.9, Cropland = 1.7)
otu <- matrix(0, nrow = 12, ncol = n_sp)
sample_id <- character(12)
group <- character(12)
k <- 1L
for (g in groups) {
  for (r in 1:3) {
    present <- rbinom(n_sp, 1, c(Grassland = 0.45, Forest = 0.72, Wetland = 0.32, Cropland = 0.55)[[g]])
    mu <- base_mu[[g]] * runif(n_sp, 0.3, 2.2)
    otu[k, ] <- rnbinom(n_sp, mu = mu, size = 1.4) * present
    # integer library above the deepest rarefaction depth
    otu[k, ] <- round(otu[k, ] / sum(otu[k, ]) * 12000)
    otu[k, ] <- pmax(otu[k, ], 0)
    sample_id[k] <- sprintf("%s_%d", substr(g, 1, 2), r)
    group[k] <- g
    k <- k + 1L
  }
}
rownames(otu) <- sample_id
depths <- round(exp(seq(log(100), log(8000), length.out = 20)))
rich <- vegan::rarefy(otu, sample = depths)

rows <- list()
for (i in seq_len(nrow(otu))) {
  for (d in seq_along(depths)) {
    rows[[length(rows) + 1L]] <- data.frame(
      sample = sample_id[i],
      group = group[i],
      depth = depths[d],
      richness = round(rich[i, d], 2),
      stringsAsFactors = FALSE
    )
  }
}
out <- do.call(rbind, rows)
utils::write.csv(out, "data.csv", row.names = FALSE)
