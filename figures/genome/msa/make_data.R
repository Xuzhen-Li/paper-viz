# Short protein alignment around one consensus, with conserved and variable sites.
# Run from this directory.
set.seed(68)
aa <- strsplit("ACDEFGHIKLMNPQRSTVWY", "")[[1]]
hydrophobic <- strsplit("AVLIMFPW", "")[[1]]
n_seq <- 8
n_pos <- 40
consensus <- sample(aa, n_pos, replace = TRUE, prob = c(
  3, 1, 2, 2, 1, 2, 1, 3, 2, 3, 1, 2, 1, 1, 2, 2, 2, 3, 1, 1
))
# Low mutation rate on a conserved block, higher elsewhere.
p_mut <- rep(0.42, n_pos)
p_mut[12:28] <- 0.06
p_mut[c(3, 8, 33, 37)] <- 0.72
seqs <- lapply(seq_len(n_seq), function(i) {
  out <- consensus
  flip <- stats::runif(n_pos) < p_mut
  n_flip <- sum(flip)
  if (n_flip) {
    out[flip] <- sample(aa, n_flip, replace = TRUE)
  }
  paste(out, collapse = "")
})
rows <- list()
for (i in seq_len(n_seq)) {
  bases <- strsplit(seqs[[i]], "")[[1]]
  rows[[i]] <- data.frame(
    seq = sprintf("Seq%d", i),
    pos = seq_len(n_pos),
    base = bases,
    stringsAsFactors = FALSE
  )
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE, quote = FALSE)
message("wrote data.csv")
