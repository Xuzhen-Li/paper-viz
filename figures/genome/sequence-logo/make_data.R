# 15-position DNA PWM. Dirichlet draw, then multinomial counts.
# A few positions are peaked; the rest stay low-information. Run from this directory.
set.seed(7079)
bases <- c("A", "C", "G", "T")
npos <- 15L
nseq <- 200L
mode <- c("C", "G", "A", "T", "A", "T", "C", "G", "A", "C", "G", "T", "A", "C", "G")
peak <- c(1.6, 24, 2.2, 1.8, 28, 18, 2.4, 3.2, 1.5, 4.0, 22, 16, 2.0, 3.0, 1.7)
rows <- vector("list", npos * 4L)
k <- 1L
for (i in seq_len(npos)) {
  alpha <- rep(1, 4)
  alpha[match(mode[i], bases)] <- peak[i]
  g <- stats::rgamma(4, shape = alpha, rate = 1)
  p <- g / sum(g)
  cnt <- as.integer(stats::rmultinom(1, nseq, p))
  phat <- cnt / nseq
  H <- -sum(phat * log2(pmax(phat, 1e-12)))
  correction <- (4 - 1) / (2 * log(2) * nseq)
  R <- max(0, 2 - H - correction)
  for (b in seq_along(bases)) {
    rows[[k]] <- data.frame(
      pos = i,
      base = bases[b],
      bits = round(phat[b] * R, 4),
      prob = round(phat[b], 4),
      count = cnt[b]
    )
    k <- k + 1L
  }
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
