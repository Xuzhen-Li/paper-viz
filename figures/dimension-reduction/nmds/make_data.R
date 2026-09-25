# Simulated taxon counts for NMDS. Run from this directory.
set.seed(6)
n_samp <- 36
n_taxa <- 12
group <- rep(c("G1", "G2", "G3"), each = 12)
base <- rbind(
  runif(n_taxa, 0, 1),
  runif(n_taxa, 1, 3),
  runif(n_taxa, 0.5, 2)
)
counts <- base[match(group, c("G1", "G2", "G3")), ] + matrix(rexp(n_samp * n_taxa, 2), n_samp)
samples <- sprintf("S%02d", seq_len(n_samp))
taxa <- sprintf("T%02d", seq_len(n_taxa))
df <- data.frame(
  sample = rep(samples, times = n_taxa),
  group = rep(group, times = n_taxa),
  taxon = rep(taxa, each = n_samp),
  abundance = as.vector(counts),
  stringsAsFactors = FALSE
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
