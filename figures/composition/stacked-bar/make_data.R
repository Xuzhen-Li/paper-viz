# Sample compositions from a group-shifted Dirichlet. Counts, not pre-cut shares.
# Run from this directory.
set.seed(520)
parts <- c("Firmicutes", "Bacteroidota", "Proteobacteria", "Actinobacteriota", "Verrucomicrobiota", "Other")
samples <- sprintf("D%02d", 1:20)
group <- rep(c("Healthy", "IBD", "Treated"), c(7, 7, 6))
alpha <- list(
  Healthy = c(6.5, 4.2, 1.1, 1.4, 0.8, 0.9),
  IBD = c(3.2, 2.4, 3.6, 1.0, 0.5, 1.3),
  Treated = c(5.0, 3.4, 1.6, 1.8, 0.7, 1.0)
)
rows <- lapply(seq_along(samples), function(i) {
  a <- alpha[[group[i]]]
  w <- stats::rgamma(length(parts), shape = a, scale = 1)
  share <- w / sum(w)
  counts <- as.numeric(stats::rmultinom(1, size = sample(8000:14000, 1), prob = share))
  data.frame(sample = samples[i], group = group[i], part = parts, value = counts)
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
